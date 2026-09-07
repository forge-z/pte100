#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "pathname"

ROOT = File.expand_path("..", __dir__)
errors = []
EXCLUDED_DIRECTORIES = %w[.git .astro coverage dist node_modules tmp .pte-cache].freeze

def project_markdown_files
  Dir.glob(File.join(ROOT, "**", "*.md")).sort.reject do |path|
    relative = path.delete_prefix(ROOT + "/").split(File::SEPARATOR)
    (relative & EXCLUDED_DIRECTORIES).any?
  end
end

rules_path = File.join(ROOT, "rules", "rules.yaml")
rules_data = YAML.safe_load(File.read(rules_path, encoding: "UTF-8"), permitted_classes: [], aliases: false)
rules = rules_data.fetch("rules")

expected_ids = (1..50).map { |number| format("R%03d", number) }
actual_ids = rules.map { |rule| rule["id"] }
errors << "IDs esperados: #{expected_ids.join(", ")}; recebidos: #{actual_ids.join(", ")}" unless actual_ids == expected_ids
errors << "IDs de regra duplicados" unless actual_ids.uniq.length == actual_ids.length
errors << "o contrato do MVP espera 21 regras automáticas" unless rules.count { |rule| rule.dig("lint", "mode") == "automatic" } == 21
errors << "o contrato atual espera 29 regras assistidas" unless rules.count { |rule| rule.dig("lint", "mode") == "assisted" } == 29

required_rule_fields = %w[id title category level status severity description rationale incorrect correct lint]
required_lint_fields = %w[mode engine selector condition parameters autofix message]
allowed_categories = %w[lexicon sentence procedure alert data structure ai]
allowed_modes = %w[automatic assisted manual]
rules.each do |rule|
  missing = required_rule_fields.reject { |field| rule.key?(field) }
  errors << "#{rule.fetch("id", "regra sem ID")}: campos ausentes: #{missing.join(", ")}" unless missing.empty?
  next unless rule["lint"].is_a?(Hash)

  missing_lint = required_lint_fields.reject { |field| rule["lint"].key?(field) }
  errors << "#{rule["id"]}: campos de lint ausentes: #{missing_lint.join(", ")}" unless missing_lint.empty?
  errors << "#{rule["id"]}: categoria inválida" unless allowed_categories.include?(rule["category"])
  errors << "#{rule["id"]}: modo de lint inválido" unless allowed_modes.include?(rule["lint"]["mode"])
end

vocabulary_path = File.join(ROOT, "vocabulary", "core.yaml")
if File.exist?(vocabulary_path)
  vocabulary = YAML.safe_load(File.read(vocabulary_path, encoding: "UTF-8"), permitted_classes: [], aliases: false)
  term_ids = vocabulary.fetch("concepts").map { |entry| entry.fetch("id") }
  errors << "IDs de conceito duplicados" unless term_ids.uniq.length == term_ids.length
else
  errors << "vocabulary/core.yaml não existe"
end

Dir.glob(File.join(ROOT, "schemas", "*.json")).sort.each do |path|
  JSON.parse(File.read(path, encoding: "UTF-8"))
rescue JSON::ParserError => e
  errors << "#{path.delete_prefix(ROOT + "/")}: JSON inválido: #{e.message}"
end

Dir.glob(File.join(ROOT, ".github", "**", "*.y{a,}ml")).sort.each do |path|
  YAML.parse_file(path)
rescue Psych::SyntaxError => e
  errors << "#{path.delete_prefix(ROOT + "/")}: YAML inválido: #{e.message}"
end

%w[pte-lint.example.yaml vocabulary/core.yaml rules/rules.yaml corpus/cases.yaml corpus/sources.yaml corpus/sources.lock.yaml].each do |relative|
  path = File.join(ROOT, relative)
  YAML.safe_load(File.read(path, encoding: "UTF-8"), permitted_classes: [], aliases: false)
rescue Psych::SyntaxError => e
  errors << "#{relative}: YAML inválido: #{e.message}"
end

cases_path = File.join(ROOT, "corpus", "cases.yaml")
if File.file?(cases_path)
  cases = YAML.safe_load(File.read(cases_path, encoding: "UTF-8"), permitted_classes: [], aliases: false).fetch("cases")
  errors << "corpus/cases.yaml deve conter 42 casos" unless cases.length == 42
  errors << "corpus/cases.yaml deve conter 21 casos positivos e 21 negativos" unless cases.count { |item| item["class"] == "positive" } == 21 && cases.count { |item| item["class"] == "negative" } == 21
  %w[positive negative].each do |kind|
    fixture_ids = Dir.glob(File.join(ROOT, "corpus", "fixtures", kind, "*.md")).map { |path| File.basename(path, ".md") }.sort
    expected_fixture_ids = cases.select { |item| item["class"] == kind }.map { |item| item["id"] }.sort
    errors << "fixtures #{kind} não correspondem ao corpus anotado" unless fixture_ids == expected_fixture_ids
  end
end

begin
  YAML.parse_file(File.join(ROOT, "CITATION.cff"))
rescue Psych::SyntaxError => e
  errors << "CITATION.cff: YAML inválido: #{e.message}"
end

catalog_path = File.join(ROOT, "rules", "catalog.md")
if File.exist?(catalog_path)
  catalog = File.read(catalog_path, encoding: "UTF-8")
  actual_ids.each { |id| errors << "catalog.md não contém #{id}" unless catalog.include?("### #{id} —") }
else
  errors << "rules/catalog.md não existe"
end


# Verificação simples de destinos Markdown locais. Âncoras internas e URLs não
# são validadas aqui porque dependem do renderizador ou da rede.
project_markdown_files.each do |path|
  text = File.read(path, encoding: "UTF-8")
  text.scan(/\[[^\]]*\]\(([^)]+)\)/).flatten.each do |target|
    target = target.strip.sub(/\A</, "").sub(/>\z/, "")
    next if target.empty? || target.start_with?("#") || target.match?(/\A[a-z][a-z0-9+.-]*:/i)

    relative = target.split("#", 2).first
    destination = File.expand_path(relative, File.dirname(path))
    unless Pathname.new(destination).to_s.start_with?(ROOT + File::SEPARATOR) && File.exist?(destination)
      errors << "#{path.delete_prefix(ROOT + "/")}: link local inexistente: #{target}"
    end
  end
end

if errors.empty?
  puts "OK: #{rules.length} regras, IDs contínuos, YAML válido e schemas JSON válidos."
  exit 0
end

warn errors.map { |error| "ERRO: #{error}" }.join("\n")
exit 1
