#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

ROOT = File.expand_path("..", __dir__)
SOURCE = File.join(ROOT, "rules", "rules.yaml")
TARGET = File.join(ROOT, "rules", "catalog.md")

data = YAML.safe_load(File.read(SOURCE, encoding: "UTF-8"), permitted_classes: [], aliases: false)
rules = data.fetch("rules")
categories = {
  "lexicon" => "Léxico",
  "sentence" => "Frase",
  "procedure" => "Procedimento",
  "alert" => "Alertas",
  "data" => "Dados, números e unidades",
  "structure" => "Estrutura",
  "ai" => "Escrita para IA"
}

lines = [
  "# Catálogo de regras PTE-100 v#{data.fetch("standard_version")}",
  "",
  "> **Normativo.** Este arquivo é gerado de `rules/rules.yaml`. Não o edite diretamente; execute `ruby tools/generate_catalog.rb`.",
  "",
  "Cada seção apresenta código, obrigação, justificativa, exemplos e a representação YAML portátil para lint. Os exemplos demonstram a regra em foco, não conformidade integral.",
  ""
]

rules.group_by { |rule| rule.fetch("category") }.each do |category, group|
  lines << "## #{categories.fetch(category)}"
  lines << ""
  group.each do |rule|
    lines << "### #{rule.fetch("id")} — #{rule.fetch("title")}"
    lines << ""
    lines << "- **Descrição:** #{rule.fetch("description")}"
    lines << "- **Justificativa:** #{rule.fetch("rationale")}"
    lines << "- **Nível mínimo:** `#{rule.fetch("level")}`"
    lines << "- **Severidade padrão:** `#{rule.fetch("severity")}`"
    lines << ""
    lines << "**Incorreto**"
    lines << ""
    lines << "> #{rule.fetch("incorrect")}"
    lines << ""
    lines << "**Correto**"
    lines << ""
    lines << "> #{rule.fetch("correct")}"
    lines << ""
    lines << "**Representação YAML para lint**"
    lines << ""
    lines << "```yaml"
    lint_yaml = YAML.dump({"id" => rule.fetch("id"), "lint" => rule.fetch("lint")})
      .sub(/\A---\s*\n/, "")
      .rstrip
    lines.concat(lint_yaml.lines(chomp: true))
    lines << "```"
    lines << ""
  end
end

File.write(TARGET, lines.join("\n") + "\n", mode: "w", encoding: "UTF-8")

