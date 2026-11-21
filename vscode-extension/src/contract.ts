// Tradução pura entre o JSON da CLI (schemas/diagnostic.schema.json) e o editor.
// Sem import de vscode, para os testes de unidade rodarem com node --test.

export type Severity = "error" | "warning" | "info";

export interface Point {
  line: number;
  column: number;
  offset: number;
}

export interface CliDiagnostic {
  rule: string;
  severity: Severity;
  message: string;
  file: string;
  range: {start: Point; end: Point};
  documentation?: string;
  suggestion?: string;
  fix?: {safety: string; replacement: string};
}

export interface CliResult {
  schema_version: string;
  diagnostics: CliDiagnostic[];
}

export interface RuleInfo {
  id: string;
  title: string;
  description: string;
  correct?: string;
}

export interface Position {
  line: number;
  character: number;
}

export const CONFIG_FILES = [".pte-lint.yaml", ".pte-lint.yml", ".pte-lint.json"];

export interface ArgsOptions {
  cliPath: string;
  stdinFilename: string;
  configPath?: string;
  level?: string | null;
  locale?: string | null;
}

export function cliArgs(options: ArgsOptions): string[] {
  const args = [options.cliPath, "check", "--format", "json", "--stdin-filename", options.stdinFilename];
  if (options.configPath) args.push("--config", options.configPath);
  if (options.level) args.push("--level", options.level);
  if (options.locale) args.push("--locale", options.locale);
  return args;
}

export class ToolError extends Error {}

// Códigos 0 e 1 encerram uma análise válida; os demais são falha da ferramenta.
export function parseResult(exitCode: number | null, stdout: string, stderr: string): CliResult {
  if (exitCode !== 0 && exitCode !== 1) {
    throw new ToolError(`pte-lint terminou com código ${exitCode}: ${stderr.trim() || "sem mensagem"}`);
  }
  let result: CliResult;
  try {
    result = JSON.parse(stdout) as CliResult;
  } catch {
    throw new ToolError(`pte-lint devolveu JSON inválido: ${stderr.trim() || stdout.slice(0, 200)}`);
  }
  if (result.schema_version !== "1.0" || !Array.isArray(result.diagnostics)) {
    throw new ToolError(`pte-lint devolveu schema_version ${String(result.schema_version)} sem suporte`);
  }
  return result;
}

export function splitLines(text: string): string[] {
  return text.split("\n").map((line) => (line.endsWith("\r") ? line.slice(0, -1) : line));
}

// O motor conta colunas em caracteres Ruby (pontos de código), base 1;
// o editor conta unidades UTF-16, base 0.
export function toPosition(lines: string[], point: Point): Position {
  const line = Math.max(0, point.line - 1);
  const text = lines[line] ?? "";
  let character = 0;
  let remaining = point.column - 1;
  for (const codePoint of text) {
    if (remaining <= 0) break;
    character += codePoint.length;
    remaining -= 1;
  }
  return {line, character: character + Math.max(0, remaining)};
}

export function hoverMarkdown(rule: RuleInfo | undefined, ruleId: string, suggestion?: string): string {
  const parts: string[] = [];
  if (rule) {
    parts.push(`**${rule.id} — ${rule.title}**`, rule.description);
    if (rule.correct) parts.push(`Correto: ${rule.correct}`);
  } else {
    parts.push(`**${ruleId}**`);
  }
  if (suggestion !== undefined) parts.push(`Sugestão: \`${suggestion.replace(/`/g, "\\`")}\``);
  return parts.join("\n\n");
}
