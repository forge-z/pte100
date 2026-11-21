import assert from "node:assert/strict";
import {readdirSync} from "node:fs";
import * as path from "node:path";
import * as vscode from "vscode";
import type {Pte100Api} from "../../extension";

const ROOT = path.resolve(__dirname, "..", "..", "..", "..");
const FIXTURES = path.join(ROOT, "corpus", "fixtures");

const ruleIds = (diagnostics: readonly vscode.Diagnostic[]) =>
  diagnostics.map((d) => (typeof d.code === "object" ? String(d.code.value) : String(d.code)));

async function api(): Promise<Pte100Api> {
  const extension = vscode.extensions.getExtension<Pte100Api>("forge-z.pte100-vscode");
  assert.ok(extension, "extensão não encontrada");
  return extension.activate();
}

async function analyzed(document: vscode.TextDocument): Promise<readonly vscode.Diagnostic[]> {
  const result = await (await api()).analyze(document);
  assert.ok(result, `análise cancelada ou falhou: ${document.uri.fsPath}`);
  return result;
}

const tests: Array<[string, () => Promise<void>]> = [];
const it = (name: string, body: () => Promise<void>) => tests.push([name, body]);

it("fixtures positivas incluem o ID e negativas não incluem", async () => {
  const failures: string[] = [];
  let count = 0;
  for (const kind of ["positive", "negative"]) {
    for (const name of readdirSync(path.join(FIXTURES, kind)).filter((f) => f.endsWith(".md")).sort()) {
      const rule = path.basename(name, ".md");
      const document = await vscode.workspace.openTextDocument(path.join(FIXTURES, kind, name));
      const ids = ruleIds(await analyzed(document));
      if ((kind === "positive") !== ids.includes(rule)) failures.push(`${kind}/${name}: ${ids.join(", ") || "sem diagnóstico"}`);
      count += 1;
    }
  }
  assert.equal(count, 42);
  assert.deepEqual(failures, []);
});

it("analisa o buffer não salvo e converte posição para UTF-16", async () => {
  const text = "😀 ação\u00a0é 24 V.\n";
  const document = await vscode.workspace.openTextDocument({language: "markdown", content: text});
  const diagnostic = (await analyzed(document)).find((d) => ruleIds([d])[0] === "R038");
  assert.ok(diagnostic, "R038 ausente");
  const start = text.indexOf("24 V");
  assert.deepEqual(
    [diagnostic.range.start.line, diagnostic.range.start.character, diagnostic.range.end.character],
    [0, start, start + 4]
  );
  assert.equal(diagnostic.severity, vscode.DiagnosticSeverity.Error);
  assert.equal(diagnostic.source, "pte-lint");
  assert.equal(typeof diagnostic.code === "object" && diagnostic.code.target.fragment, "r038");
});

it("hover mostra regra, exemplo correto e sugestão", async () => {
  const text = "A tensão é 24 V.\n";
  const document = await vscode.workspace.openTextDocument({language: "markdown", content: text});
  await analyzed(document);
  const hovers = await vscode.commands.executeCommand<vscode.Hover[]>(
    "vscode.executeHoverProvider", document.uri, new vscode.Position(0, text.indexOf("24") + 1)
  );
  const markdown = hovers.flatMap((h) => h.contents).map((c) => (typeof c === "string" ? c : c.value)).join("\n");
  assert.match(markdown, /R038 — Separe número e símbolo de unidade/);
  assert.match(markdown, /Correto:/);
  assert.match(markdown, /Sugestão: `24\u00a0V`/);
});

it("nova análise cancela a anterior", async () => {
  const document = await vscode.workspace.openTextDocument({language: "markdown", content: "A tensão é 24 V.\n"});
  const extension = await api();
  const [first, second] = await Promise.all([extension.analyze(document), extension.analyze(document)]);
  assert.equal(first, undefined);
  assert.ok(second && ruleIds(second).includes("R038"));
});

it("edição no editor dispara análise depois do atraso", async () => {
  const document = await vscode.workspace.openTextDocument({language: "markdown", content: "Texto.\n"});
  await analyzed(document);
  const editor = await vscode.window.showTextDocument(document);
  await editor.edit((edit) => edit.insert(new vscode.Position(1, 0), "A tensão é 24 V.\n"));
  const deadline = Date.now() + 10000;
  while (!ruleIds(vscode.languages.getDiagnostics(document.uri)).includes("R038")) {
    assert.ok(Date.now() < deadline, "diagnóstico não apareceu após a edição");
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  await vscode.commands.executeCommand("workbench.action.revertAndCloseActiveEditor");
});

it("falha da CLI vira erro da ferramenta e mantém os diagnósticos", async () => {
  const document = await vscode.workspace.openTextDocument({language: "markdown", content: "A tensão é 24 V.\n"});
  const before = await analyzed(document);
  const config = vscode.workspace.getConfiguration("pte100");
  await config.update("level", "pte-inexistente", vscode.ConfigurationTarget.Global);
  try {
    assert.equal(await (await api()).analyze(document), undefined);
    assert.deepEqual(ruleIds(vscode.languages.getDiagnostics(document.uri)), ruleIds(before));
  } finally {
    await config.update("level", "pte-ia", vscode.ConfigurationTarget.Global);
  }
});

export async function run(): Promise<void> {
  const config = vscode.workspace.getConfiguration("pte100");
  await config.update("level", "pte-ia", vscode.ConfigurationTarget.Global);
  await config.update("locale", "pt-BR", vscode.ConfigurationTarget.Global);
  const failed: string[] = [];
  for (const [name, body] of tests) {
    try {
      await body();
      console.log(`ok - ${name}`);
    } catch (error) {
      failed.push(name);
      console.error(`not ok - ${name}\n${error instanceof Error ? error.stack : String(error)}`);
    }
  }
  if (failed.length > 0) throw new Error(`${failed.length} teste(s) falharam`);
}
