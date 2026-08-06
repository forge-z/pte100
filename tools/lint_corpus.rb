#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require_relative "../lib/pte_lint"

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Uso: tools/lint_corpus.rb UNIDADES.jsonl [opções]"
  opts.on("--config PATH", "Configuração do PTE-Lint") { |value| options[:config] = value }
  opts.on("--level LEVEL", %w[pte-estrutura pte-claro pte-ia]) { |value| options[:level] = value }
  opts.on("--output PATH", "Arquivo JSON de saída") { |value| options[:output] = value }
  opts.on("--include-local-paths", "Preservar caminhos locais (somente depuração)") { options[:include_local_paths] = true }
  opts.on("--help", "Mostrar ajuda") { puts opts; exit 0 }
end
parser.parse!(ARGV)
path = ARGV.fetch(0) { abort parser.to_s }
abort "Unidades não encontradas: #{path}" unless File.file?(path)

runner = PteLint::Runner.new(config_path: options[:config], level: options[:level])
records = File.readlines(path, encoding: "UTF-8").reject { |line| line.strip.empty? }.map { |line| JSON.parse(line) }
results = records.map do |record|
  diagnostics = runner.check_text(record.fetch("text", ""), record.fetch("id"), context: {"source_id" => record["source_id"], "element" => record["element"]})
  sanitized = record.dup
  unless options[:include_local_paths]
    sanitized["retrieved_from"] = "cache://raw/#{File.basename(record.fetch("retrieved_from", "unknown"))}"
  end
  sanitized.merge("diagnostics" => diagnostics)
end
payload = {
  "schema" => "pte-lint-corpus-result@0.1",
  "source_file" => options[:include_local_paths] ? path : "cache://units/#{File.basename(path)}",
  "units" => results.length,
  "diagnostics" => results.sum { |record| record.fetch("diagnostics").length },
  "results" => results
}
json = JSON.pretty_generate(payload)
if options[:output]
  File.write(options[:output], json + "\n", encoding: "UTF-8")
else
  puts json
end
