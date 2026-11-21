import assert from "node:assert/strict";
import {test} from "node:test";
import {CliDiagnostic, ToolError, cliArgs, hoverMarkdown, parseResult, safeReplacement, splitLines, toPosition} from "../../contract";

const point = (line: number, column: number) => ({line, column, offset: 0});

test("converte coluna em caracteres Ruby para unidades UTF-16", () => {
  const lines = splitLines("primeira\r\n😀 ação\u00a0é 24 V.");
  const start = lines[1].indexOf("24 V");
  assert.deepEqual(toPosition(lines, point(2, 10)), {line: 1, character: start});
  assert.deepEqual(toPosition(lines, point(2, 14)), {line: 1, character: start + 4});
  assert.deepEqual(toPosition(lines, point(1, 1)), {line: 0, character: 0});
});

test("aceita fim exclusivo depois do último caractere", () => {
  const lines = splitLines("é");
  assert.deepEqual(toPosition(lines, point(1, 2)), {line: 0, character: 1});
});

test("monta a invocação com buffer na entrada padrão", () => {
  assert.deepEqual(
    cliArgs({cliPath: "bin/pte-lint", stdinFilename: "docs/a.md", configPath: "/w/.pte-lint.yaml", level: "pte-ia", locale: null}),
    ["bin/pte-lint", "check", "--format", "json", "--stdin-filename", "docs/a.md", "--config", "/w/.pte-lint.yaml", "--level", "pte-ia"]
  );
  assert.deepEqual(cliArgs({cliPath: "c", stdinFilename: "a.md"}), ["c", "check", "--format", "json", "--stdin-filename", "a.md"]);
});

test("códigos 0 e 1 são análise válida; 2 e 3 são erro da ferramenta", () => {
  const json = JSON.stringify({schema_version: "1.0", diagnostics: []});
  assert.deepEqual(parseResult(0, json, "").diagnostics, []);
  assert.deepEqual(parseResult(1, json, "").diagnostics, []);
  assert.throws(() => parseResult(2, "", "opção inválida"), ToolError);
  assert.throws(() => parseResult(3, "", "falha"), ToolError);
  assert.throws(() => parseResult(0, "não é json", ""), ToolError);
  assert.throws(() => parseResult(0, JSON.stringify({schema_version: "2.0", diagnostics: []}), ""), ToolError);
});

test("hover mostra título, descrição, exemplo correto e sugestão", () => {
  const markdown = hoverMarkdown(
    {id: "R038", title: "Separe número e símbolo de unidade", description: "Descrição.", correct: "24 V"},
    "R038",
    "24\u00a0V"
  );
  assert.match(markdown, /\*\*R038 — Separe número e símbolo de unidade\*\*/);
  assert.match(markdown, /Descrição\./);
  assert.match(markdown, /Correto: 24 V/);
  assert.match(markdown, /Sugestão: `24\u00a0V`/);
  assert.equal(hoverMarkdown(undefined, "R999"), "**R999**");
});

test("só fix safe com replacement vira Code Action", () => {
  const base = {
    rule: "R038", severity: "error", message: "m", file: "a.md",
    range: {start: point(1, 1), end: point(1, 5)}, suggestion: "24\u00a0V"
  } as CliDiagnostic;
  assert.equal(safeReplacement({...base, fix: {safety: "safe", replacement: "24\u00a0V"}}), "24\u00a0V");
  assert.equal(safeReplacement({...base, fix: {safety: "review", replacement: "24\u00a0V"}}), undefined);
  assert.equal(safeReplacement(base), undefined);
});
