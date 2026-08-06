#!/usr/bin/env ruby
# frozen_string_literal: true

# Baixa e segmenta fontes HTML para uso local no PTE-Lint.
# O texto integral fica em .pte-cache/corpus/, ignorado pelo Git.

require "cgi"
require "digest"
require "fileutils"
require "json"
require "net/http"
require "optparse"
require "uri"
require "yaml"

ROOT = File.expand_path("..", __dir__)
MANIFEST_PATH = File.join(ROOT, "corpus", "sources.yaml")
DEFAULT_CACHE = File.join(ROOT, ".pte-cache", "corpus")

class HtmlSegmenter
  def initialize(source_id, html)
    @source_id = source_id
    @html = html.to_s.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
  end

  def units
    clean = @html.gsub(%r{<(script|style|nav|footer|header|aside)\b[^>]*>.*?</\1>}im, "")
    pattern = /<(h[1-4]|p|li|blockquote|pre)\b[^>]*>(.*?)<\/\1>/im
    ordinal = 0
    clean.to_enum(:scan, pattern).each_with_object([]) do |_, result|
      match = Regexp.last_match
      element = match[1].downcase
      text = normalize(match[2], preserve_whitespace: element == "pre")
      next if text.empty?

      ordinal += 1
      result << {
        "id" => format("%s#u%04d", @source_id, ordinal),
        "source_id" => @source_id,
        "ordinal" => ordinal,
        "element" => element,
        "text" => text,
        "sha256" => Digest::SHA256.hexdigest(text)
      }
    end
  end

  private

  def normalize(fragment, preserve_whitespace: false)
    value = fragment.gsub(%r{<br\s*/?>}i, "\n")
    value = value.gsub(%r{</?(?:a|code|strong|em|b|i|span)\b[^>]*>}i, "")
    value = value.gsub(%r{<img\b[^>]*>}i, "")
    value = value.gsub(%r{<[^>]+>}, "")
    value = CGI.unescapeHTML(value)
    preserve_whitespace ? value.lines.map(&:rstrip).join("\n").strip : value.gsub(/\s+/, " ").strip
  end
end

def load_manifest
  YAML.safe_load(File.read(MANIFEST_PATH, encoding: "UTF-8"), permitted_classes: [], aliases: false)
end

def selected_sources(manifest_data, requested)
  sources = manifest_data.fetch("sources")
  return sources if requested.nil? || requested == "all"

  source = sources.find { |item| item.fetch("id") == requested }
  abort "Fonte inexistente: #{requested}" unless source
  [source]
end

def cache_path(source, directory, extension)
  File.join(directory, "#{source.fetch("id")}#{extension}")
end

def fetch_url(url, redirects = 0)
  abort "Limite de redirecionamentos excedido para #{url}" if redirects > 5

  uri = URI.parse(url)
  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "PTE-100-corpus/0.1 (+https://pte-100.org)"
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 20, read_timeout: 30) do |http|
    http.request(request)
  end
  return fetch_url(URI.join(url, response["location"]).to_s, redirects + 1) if response.is_a?(Net::HTTPRedirection)
  abort "HTTP #{response.code} ao baixar #{url}" unless response.is_a?(Net::HTTPSuccess)

  response.body
end

def fetch_source(source, cache_dir)
  raw_dir = File.join(cache_dir, "raw")
  FileUtils.mkdir_p(raw_dir)
  path = cache_path(source, raw_dir, ".html")
  File.binwrite(path, fetch_url(source.fetch("url")))
  puts "Baixada #{source.fetch("id")} em #{path}"
  path
end

def convert_source(source, input_path, output_dir, metadata_only: false)
  abort "Entrada não encontrada: #{input_path}" unless File.file?(input_path)

  units = HtmlSegmenter.new(source.fetch("id"), File.read(input_path, encoding: "UTF-8")).units
  abort "Nenhuma unidade extraída de #{input_path}" if units.empty?

  FileUtils.mkdir_p(output_dir)
  output_path = cache_path(source, output_dir, ".jsonl")
  File.open(output_path, "w", encoding: "UTF-8") do |file|
    units.each do |unit|
      record = {
        "id" => unit.fetch("id"),
        "source_id" => source.fetch("id"),
        "source_url" => source.fetch("url"),
        "title" => source.fetch("title"),
        "platform" => source.fetch("platform"),
        "locale" => source.fetch("locale"),
        "kind" => source.fetch("kind"),
        "license" => source.fetch("license"),
        "retrieved_from" => "cache://raw/#{File.basename(input_path)}",
        "element" => unit.fetch("element"),
        "ordinal" => unit.fetch("ordinal"),
        "sha256" => unit.fetch("sha256")
      }
      record["text"] = unit.fetch("text") unless metadata_only
      file.puts(JSON.generate(record))
    end
  end
  puts "Extraídas #{units.length} unidades de #{source.fetch("id")} em #{output_path}"
end

options = {cache_dir: DEFAULT_CACHE, metadata_only: false}
parser = OptionParser.new do |opts|
  opts.banner = "Uso: tools/ingest_corpus.rb COMANDO [opções]"
  opts.on("--source ID", "Fonte do manifesto ou all") { |value| options[:source] = value }
  opts.on("--input PATH", "HTML local para convert") { |value| options[:input] = value }
  opts.on("--output DIR", "Diretório de unidades") { |value| options[:output] = value }
  opts.on("--cache-dir DIR", "Cache local (padrão: .pte-cache/corpus)") { |value| options[:cache_dir] = File.expand_path(value, ROOT) }
  opts.on("--metadata-only", "Não gravar o texto integral no JSONL") { options[:metadata_only] = true }
  opts.on("--help", "Mostrar ajuda") { puts opts; exit 0 }
end

command = ARGV.shift || "list"
parser.parse!(ARGV)
data = load_manifest
sources = selected_sources(data, options[:source])

case command
when "list"
  sources.each { |source| puts "#{source.fetch("id")}\t#{source.fetch("kind")}\t#{source.fetch("title")}" }
when "fetch"
  sources.each { |source| fetch_source(source, options[:cache_dir]) }
when "convert"
  sources.each do |source|
    input = options[:input] || cache_path(source, File.join(options[:cache_dir], "raw"), ".html")
    output = options[:output] || File.join(options[:cache_dir], "units")
    convert_source(source, input, output, metadata_only: options[:metadata_only])
  end
when "fetch-and-convert"
  sources.each do |source|
    input = fetch_source(source, options[:cache_dir])
    output = options[:output] || File.join(options[:cache_dir], "units")
    convert_source(source, input, output, metadata_only: options[:metadata_only])
  end
else
  abort "Comando desconhecido: #{command}. Use list, fetch, convert ou fetch-and-convert."
end
