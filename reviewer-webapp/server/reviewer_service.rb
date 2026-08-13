# frozen_string_literal: true

require "json"
require "securerandom"
require_relative "../../lib/pte_lint"
require_relative "document_converter"

class ReviewerService
  MAX_BYTES = 5 * 1024 * 1024
  MAX_WORDS = 100_000
  FORMATS = %w[markdown text pdf].freeze
  LEVELS = %w[pte-estrutura pte-claro pte-ia].freeze
  LOCALES = %w[pt-BR].freeze

  attr_reader :session_token

  def initialize(root: File.expand_path("../..", __dir__), session_token: SecureRandom.hex(32), converter: DocumentConverter.new)
    @root = root
    @session_token = session_token
    @converter = converter
  end

  def capabilities
    {
      "service" => "pte-100-reviewer",
      "service_version" => "0.2.0",
      "engine" => "pte-lint",
      "engine_version" => "0.1.0",
      "standard" => "PTE-100@0.1",
      "formats" => @converter.formats,
      "converters" => @converter.capabilities,
      "locales" => LOCALES,
      "levels" => LEVELS,
      "max_bytes" => MAX_BYTES,
      "max_words" => MAX_WORDS,
      "session_token" => @session_token
    }
  end

  def review(payload)
    unless payload.is_a?(Hash)
      return error("invalid_request", "A requisição deve ser um objeto JSON.")
    end
    document = payload["document"]
    configuration = payload["configuration"] || {}
    unless document.is_a?(Hash)
      return error("invalid_document", "O documento não foi informado.")
    end

    name = document["name"].to_s
    format = document["format"].to_s
    return error("invalid_name", "O nome do arquivo não foi informado.") if name.empty? || name.include?("/") || name.include?("\\")
    return error("unsupported_format", "Formato não aceito. Use Markdown, texto simples ou PDF.") unless FORMATS.include?(format)
    return error("converter_unavailable", "O conversor deste formato não está disponível neste computador.") unless @converter.formats.include?(format)

    content = @converter.extract(document)
    return error("document_too_large", "O documento excede o limite local de 100 mil palavras.") if content.split.size > MAX_WORDS

    level = configuration["level"].to_s
    locale = configuration["locale"].to_s
    return error("invalid_level", "Nível PTE-100 inválido.") unless LEVELS.include?(level)
    return error("invalid_locale", "Localidade não suportada neste MVP.") unless LOCALES.include?(locale)

    runner = PteLint::Runner.new(level: level, locale: locale, rules_path: File.join(@root, "rules", "rules.yaml"), vocabulary_path: File.join(@root, "vocabulary", "core.yaml"))
    diagnostics = runner.check_text(content, name)
    result = runner.result(diagnostics, files: 1)
    result
  rescue DocumentConverter::ConversionError => error
    self.class.error(error.code, error.message)
  rescue Psych::Exception, JSON::ParserError => error
    self.class.error("invalid_request", error.message)
  rescue StandardError => error
    warn "reviewer-webapp internal error: #{error.class}: #{error.message}" if ENV["PTE_REVIEWER_DEBUG"] == "1"
    self.class.error("internal_error", "Não foi possível concluir a revisão local.")
  end

  def rule(rule_id)
    pack = PteLint::RulePack.new(File.join(@root, "rules", "rules.yaml"))
    rule = pack.by_id[rule_id.to_s]
    return self.class.error("not_found", "Regra não encontrada.") unless rule

    { "id" => rule["id"], "title" => rule["title"], "description" => rule["description"], "level" => rule["level"], "severity" => rule["severity"], "lint" => rule["lint"] }
  rescue StandardError
    self.class.error("internal_error", "Não foi possível carregar a regra.")
  end

  def self.error(code, message)
    { "error" => { "code" => code, "message" => message } }
  end

  private

  def error(code, message)
    self.class.error(code, message)
  end
end
