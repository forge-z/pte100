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

async function pteActions(document: vscode.TextDocument): Promise<vscode.CodeAction[]> {
  const full = new vscode.Range(0, 0, document.lineCount, 0);
  const actions = await vscode.commands.executeCommand<Array<vscode.CodeAction | vscode.Command>>(
    "vscode.executeCodeActionProvider", document.uri, full
  );
  // O comando não devolve `diagnostics`; as ações da extensão se distinguem pelo título.
  return actions.filter((a): a is vscode.CodeAction => "kind" in a && a.title.startsWith("PTE-100:"));
}

const fixture = (kind: string, rule: string) =>
  vscode.workspace.openTextDocument(path.join(FIXTURES, kind, `${rule}.md`));

async function scratch(source: vscode.TextDocument): Promise<vscode.TextDocument> {
  return vscode.workspace.openTextDocument({language: "markdown", content: source.getText()});
}

function replacements(action: vscode.CodeAction): string[] {
  return action.edit?.entries().flatMap(([, edits]) => edits.map((e) => e.newText)) ?? [];
}

it("R038 oferece Code Action com U+00A0 entre número e símbolo", async () => {
  const document = await fixture("positive", "R038");
  await analyzed(document);
  const actions = await pteActions(document);
  assert.equal(actions.length, 1);
  assert.equal(actions[0].kind?.value, vscode.CodeActionKind.QuickFix.value);
  assert.match(replacements(actions[0]).join(""), /\d\u00a0\S/);
});

it("R039 aplica o símbolo do registro", async () => {
  const document = await scratch(await fixture("positive", "R039"));
  const diagnostics = await analyzed(document);
  const r039 = diagnostics.find((d) => ruleIds([d])[0] === "R039");
  assert.ok(r039);
  const [action] = await pteActions(document);
  assert.ok(action, "sem Code Action para R039");
  const replacement = replacements(action)[0];
  assert.notEqual(document.getText(r039.range), replacement);
  assert.ok(await vscode.workspace.applyEdit(action.edit!));
  assert.ok(document.getText().includes(replacement));
  assert.ok(!ruleIds(await analyzed(document)).includes("R039"));
});

it("regras sem fix safe não oferecem Code Action", async () => {
  const rules = ["R001", "R004", "R005", "R006", "R012", "R014", "R017", "R018", "R021", "R029",
    "R031", "R037", "R040", "R041", "R042", "R045", "R046", "R048", "R050"];
  const offering: string[] = [];
  for (const rule of rules) {
    const document = await fixture("positive", rule);
    await analyzed(document);
    if ((await pteActions(document)).length > 0) offering.push(rule);
  }
  assert.deepEqual(offering, []);
});

it("suggestion sem fix não gera Code Action", async () => {
  for (const rule of ["R001", "R005", "R006"]) {
    const document = await fixture("positive", rule);
    const diagnostic = (await analyzed(document)).find((d) => ruleIds([d])[0] === rule);
    assert.ok(diagnostic, rule);
    const hovers = await vscode.commands.executeCommand<vscode.Hover[]>(
      "vscode.executeHoverProvider", document.uri, diagnostic.range.start
    );
    const markdown = hovers.flatMap((h) => h.contents).map((c) => (typeof c === "string" ? c : c.value)).join("\n");
    assert.match(markdown, /Sugestão:/, rule);
    assert.deepEqual(await pteActions(document), [], rule);
  }
});

it("Code Action some quando o buffer mudou depois da análise", async () => {
  const document = await scratch(await fixture("positive", "R038"));
  await analyzed(document);
  assert.equal((await pteActions(document)).length, 1);
  const edit = new vscode.WorkspaceEdit();
  edit.insert(document.uri, new vscode.Position(0, 0), "X");
  assert.ok(await vscode.workspace.applyEdit(edit));
  assert.deepEqual(await pteActions(document), []);
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
