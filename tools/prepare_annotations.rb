#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "fileutils"
require "optparse"

options = {metadata_only: false}
parser = OptionParser.new do |opts|
  opts.banner = "Uso: tools/prepare_annotations.rb RESULTADO.json [opções]"
  opts.on("--output PATH", "JSONL de anotação") { |value| options[:output] = value }
  opts.on("--metadata-only", "Omitir o texto integral da unidade") { options[:metadata_only] = true }
  opts.on("--help", "Mostrar ajuda") { puts opts; exit 0 }
end
parser.parse!(ARGV)
input = ARGV.fetch(0) { abort parser.to_s }
abort "Resultado não encontrado: #{input}" unless File.file?(input)

result = JSON.parse(File.read(input, encoding: "UTF-8"))
default_output = File.join(File.dirname(input), "..", "annotations", "#{File.basename(input, ".json")}.jsonl")
output = options[:output] || default_output
FileUtils.mkdir_p(File.dirname(output))

File.open(output, "w", encoding: "UTF-8") do |file|
  result.fetch("results").each do |unit|
    annotation = {
      "schema" => "pte-corpus-annotation@0.1",
      "unit_id" => unit.fetch("id"),
      "source_id" => unit.fetch("source_id"),
      "source_url" => unit.fetch("source_url"),
      "license" => unit.fetch("license"),
      "element" => unit.fetch("element"),
      "sha256" => unit.fetch("sha256"),
      "diagnostics" => unit.fetch("diagnostics").map { |diagnostic| diagnostic.slice("rule", "severity", "confidence", "evidence", "message") },
      "decision" => "uncertain",
      "applicable_rules" => [],
      "rationale" => "",
      "reviewer" => nil,
      "reviewed_at" => nil
    }
    annotation["text"] = unit.fetch("text") unless options[:metadata_only]
    file.puts(JSON.generate(annotation))
  end
end
puts "Preparado #{result.fetch("results").length} registros em #{output}"
