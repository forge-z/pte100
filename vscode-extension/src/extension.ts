import {execFile, spawn} from "node:child_process";
import {existsSync} from "node:fs";
import * as path from "node:path";
import * as vscode from "vscode";
import {
  CONFIG_FILES, CliDiagnostic, RuleInfo, ToolError, cliArgs, hoverMarkdown, parseResult, splitLines, toPosition
} from "./contract";

const LANGUAGES = ["markdown", "plaintext"];
const SOURCE = "pte-lint";

const SEVERITY: Record<string, vscode.DiagnosticSeverity> = {
  error: vscode.DiagnosticSeverity.Error,
  warning: vscode.DiagnosticSeverity.Warning,
  info: vscode.DiagnosticSeverity.Information
};

export interface Pte100Api {
  // Analisa o buffer agora. Devolve undefined quando outra análise a cancelou.
  analyze(document: vscode.TextDocument): Promise<readonly vscode.Diagnostic[] | undefined>;
}

interface Pending {
  timer?: NodeJS.Timeout;
  abort?: AbortController;
}

export function activate(context: vscode.ExtensionContext): Pte100Api {
  const collection = vscode.languages.createDiagnosticCollection("pte100");
  const output = vscode.window.createOutputChannel("PTE-100");
  const pending = new Map<string, Pending>();
  const suggestions = new WeakMap<vscode.Diagnostic, string>();
  const rulesCache = new Map<string, Promise<Map<string, RuleInfo>>>();
  const shownErrors = new Set<string>();

  const settings = () => vscode.workspace.getConfiguration("pte100");

  function workspaceRoot(document: vscode.TextDocument): string | undefined {
    const folder = vscode.workspace.getWorkspaceFolder(document.uri) ?? vscode.workspace.workspaceFolders?.[0];
    return folder?.uri.fsPath;
  }

  function cliLocation(root: string | undefined): string | undefined {
    const cliPath = settings().get<string>("cliPath", "bin/pte-lint");
    if (path.isAbsolute(cliPath)) return cliPath;
    return root ? path.join(root, cliPath) : undefined;
  }

  function stdinFilename(document: vscode.TextDocument, root: string | undefined): string {
    if (document.uri.scheme !== "file") return path.basename(document.uri.path) || "untitled.md";
    return root ? path.relative(root, document.uri.fsPath).split(path.sep).join("/") : document.uri.fsPath;
  }

  function reportToolError(message: string): void {
    output.appendLine(message);
    if (shownErrors.has(message)) return;
    shownErrors.add(message);
    void vscode.window.showWarningMessage(`PTE-100: ${message}`);
  }

  function cancel(key: string): void {
    const entry = pending.get(key);
    if (entry?.timer) clearTimeout(entry.timer);
    entry?.abort?.abort();
    pending.delete(key);
  }

  function toDiagnostic(lines: string[], item: CliDiagnostic): vscode.Diagnostic {
    const start = toPosition(lines, item.range.start);
    const end = toPosition(lines, item.range.end);
    const diagnostic = new vscode.Diagnostic(
      new vscode.Range(start.line, start.character, end.line, end.character),
      item.message,
      SEVERITY[item.severity] ?? vscode.DiagnosticSeverity.Information
    );
    diagnostic.source = SOURCE;
    diagnostic.code = item.documentation
      ? {value: item.rule, target: vscode.Uri.parse(item.documentation)}
      : item.rule;
    if (item.suggestion !== undefined) suggestions.set(diagnostic, item.suggestion);
    return diagnostic;
  }

  function run(ruby: string, args: string[], cwd: string, input: string, signal: AbortSignal) {
    return new Promise<{code: number | null; stdout: string; stderr: string} | undefined>((resolve, reject) => {
      const child = spawn(ruby, args, {cwd, signal});
      const stdout: Buffer[] = [];
      const stderr: Buffer[] = [];
      child.stdout.on("data", (chunk: Buffer) => stdout.push(chunk));
      child.stderr.on("data", (chunk: Buffer) => stderr.push(chunk));
      child.stdin.on("error", () => undefined);
      child.on("error", (error: NodeJS.ErrnoException) => {
        if (error.name === "AbortError") resolve(undefined);
        else reject(new ToolError(`não foi possível executar ${ruby}: ${error.message}`));
      });
      child.on("close", (code) => {
        if (signal.aborted) return resolve(undefined);
        resolve({code, stdout: Buffer.concat(stdout).toString("utf8"), stderr: Buffer.concat(stderr).toString("utf8")});
      });
      child.stdin.end(input, "utf8");
    });
  }

  async function analyze(document: vscode.TextDocument): Promise<readonly vscode.Diagnostic[] | undefined> {
    const key = document.uri.toString();
    cancel(key);
    const abort = new AbortController();
    pending.set(key, {abort});

    const root = workspaceRoot(document);
    const cli = cliLocation(root);
    if (!cli) {
      reportToolError("defina pte100.cliPath como caminho absoluto quando não houver workspace aberto.");
      return undefined;
    }
    const cwd = root ?? path.dirname(cli);
    const config = root ? CONFIG_FILES.map((name) => path.join(root, name)).find((file) => existsSync(file)) : undefined;
    const args = cliArgs({
      cliPath: cli,
      stdinFilename: stdinFilename(document, root),
      configPath: config,
      level: settings().get<string | null>("level", null),
      locale: settings().get<string | null>("locale", null)
    });
    const text = document.getText();

    try {
      const outcome = await run(settings().get<string>("rubyPath", "ruby"), args, cwd, text, abort.signal);
      if (!outcome) return undefined;
      const result = parseResult(outcome.code, outcome.stdout, outcome.stderr);
      const lines = splitLines(text);
      const diagnostics = result.diagnostics.map((item) => toDiagnostic(lines, item));
      collection.set(document.uri, diagnostics);
      return diagnostics;
    } catch (error) {
      if (!(error instanceof ToolError)) throw error;
      reportToolError(error.message);
      return undefined;
    } finally {
      if (pending.get(key)?.abort === abort) pending.delete(key);
    }
  }

  function schedule(document: vscode.TextDocument, delay: number): void {
    if (!LANGUAGES.includes(document.languageId)) return;
    if (document.uri.scheme !== "file" && document.uri.scheme !== "untitled") return;
    const key = document.uri.toString();
    cancel(key);
    const entry: Pending = {};
    entry.timer = setTimeout(() => void analyze(document), delay);
    pending.set(key, entry);
  }

  function loadRules(document: vscode.TextDocument): Promise<Map<string, RuleInfo>> {
    const cli = cliLocation(workspaceRoot(document));
    if (!cli) return Promise.resolve(new Map());
    const rulesPath = path.resolve(path.dirname(cli), "..", "rules", "rules.yaml");
    let cached = rulesCache.get(rulesPath);
    if (!cached) {
      const script = 'require "yaml"; require "json"; puts JSON.generate(YAML.safe_load_file(ARGV[0]).fetch("rules"))';
      cached = new Promise((resolve) => {
        execFile(settings().get<string>("rubyPath", "ruby"), ["-e", script, rulesPath], (error, stdout) => {
          if (error) {
            output.appendLine(`não foi possível ler ${rulesPath}: ${error.message}`);
            rulesCache.delete(rulesPath);
            return resolve(new Map());
          }
          const rules = JSON.parse(stdout) as RuleInfo[];
          resolve(new Map(rules.map((rule) => [rule.id, rule])));
        });
      });
      rulesCache.set(rulesPath, cached);
    }
    return cached;
  }

  const hover: vscode.HoverProvider = {
    async provideHover(document, position) {
      const found = collection.get(document.uri)?.filter((d) => d.range.contains(position)) ?? [];
      if (found.length === 0) return undefined;
      const rules = await loadRules(document);
      const contents = found.map((diagnostic) => {
        const id = typeof diagnostic.code === "object" ? String(diagnostic.code.value) : String(diagnostic.code);
        return new vscode.MarkdownString(hoverMarkdown(rules.get(id), id, suggestions.get(diagnostic)));
      });
      return new vscode.Hover(contents);
    }
  };

  const delay = () => Math.max(0, settings().get<number>("debounceMs", 300));

  context.subscriptions.push(
    collection,
    output,
    vscode.languages.registerHoverProvider(LANGUAGES, hover),
    vscode.workspace.onDidOpenTextDocument((document) => schedule(document, 0)),
    vscode.workspace.onDidSaveTextDocument((document) => schedule(document, 0)),
    vscode.workspace.onDidChangeTextDocument((event) => {
      if (event.contentChanges.length > 0) schedule(event.document, delay());
    }),
    vscode.workspace.onDidCloseTextDocument((document) => {
      cancel(document.uri.toString());
      collection.delete(document.uri);
    }),
    vscode.workspace.onDidChangeConfiguration((event) => {
      if (!event.affectsConfiguration("pte100")) return;
      rulesCache.clear();
      shownErrors.clear();
      vscode.workspace.textDocuments.forEach((document) => schedule(document, 0));
    }),
    {dispose: () => [...pending.keys()].forEach(cancel)}
  );
  vscode.workspace.textDocuments.forEach((document) => schedule(document, 0));

  return {analyze};
}

export function deactivate(): void {}
