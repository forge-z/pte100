# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"
require "yaml"

# Servidor MCP local, stdio e somente leitura. Mensagens JSON-RPC 2.0, uma por linha.
module PteMcp
  ROOT = File.expand_path("..", __dir__)
  CLI = File.join(ROOT, "bin", "pte-lint")
  PROTOCOL_VERSIONS = %w[2025-06-18 2025-03-26 2024-11-05].freeze
  MAX_TEXT_BYTES = 1_048_576
  RULE_FIELDS = %w[id title description rationale incorrect correct severity level].freeze

  class ToolError < StandardError; end

  TOOLS = [
    {
      "name" => "pte_check_text",
      "description" => "Analisa texto com ruby bin/pte-lint check --format json e devolve o documento JSON da CLI (schema 1.0). Não grava arquivo.",
      "inputSchema" => {
        "type" => "object",
        "properties" => {
          "text" => {"type" => "string", "description" => "Texto Markdown ou simples, até #{MAX_TEXT_BYTES} bytes UTF-8."},
          "level" => {"type" => "string", "enum" => %w[pte-estrutura pte-claro pte-ia]},
          "locale" => {"type" => "string"},
          "filename" => {"type" => "string", "description" => "Nome usado em file nos diagnósticos."}
        },
        "required" => ["text"]
      }
    },
    {
      "name" => "pte_explain_rule",
      "description" => "Devolve os campos de uma regra de rules/rules.yaml.",
      "inputSchema" => {
        "type" => "object",
        "properties" => {"id" => {"type" => "string", "pattern" => "^R0(0[1-9]|[1-4][0-9]|50)$"}},
        "required" => ["id"]
      }
    },
    {
      "name" => "pte_lookup_term",
      "description" => "Procura um termo em preferred, admitted e forbidden.term de vocabulary/core.yaml, sem distinção de maiúsculas.",
      "inputSchema" => {
        "type" => "object",
        "properties" => {"term" => {"type" => "string"}},
        "required" => ["term"]
      }
    }
  ].freeze

  class Server
    def initialize(root: ROOT)
      @root = root
    end

    def serve(input = $stdin, output = $stdout)
      input.set_encoding(Encoding::UTF_8)
      output.set_encoding(Encoding::UTF_8)
      output.sync = true
      input.each_line do |line|
        response = handle_line(line)
        output.puts(JSON.generate(response)) if response
      end
    end

    def handle_line(line)
      message = nil
      line = line.dup.force_encoding(Encoding::UTF_8)
      return error(nil, -32700, "UTF-8 inválido") unless line.valid_encoding?
      return nil if line.strip.empty?

      begin
        message = JSON.parse(line)
      rescue JSON::ParserError
        return error(nil, -32700, "JSON inválido")
      end
      return error(nil, -32600, "Requisição inválida") unless message.is_a?(Hash) && message["jsonrpc"] == "2.0"

      handle(message)
    rescue StandardError
      return nil if message.is_a?(Hash) && !message.key?("id")

      error(message.is_a?(Hash) ? message["id"] : nil, -32603, "Erro interno")
    end

    def handle(message)
      id = message["id"]
      return nil unless message.key?("id")
      return error(nil, -32600, "Identificador não pode ser null") if id.nil?
      if message.key?("params") && !message["params"].is_a?(Hash)
        return error(id, -32602, "Parâmetros devem ser objeto")
      end

      case message["method"]
      when "initialize" then result(id, initialize_result(message.dig("params", "protocolVersion")))
      when "ping" then result(id, {})
      when "tools/list" then result(id, {"tools" => TOOLS})
      when "tools/call" then call_tool(id, message["params"] || {})
      else error(id, -32601, "Método não suportado: #{message["method"]}")
      end
    end

    private

    def initialize_result(requested)
      {
        "protocolVersion" => PROTOCOL_VERSIONS.include?(requested) ? requested : PROTOCOL_VERSIONS.first,
        "capabilities" => {"tools" => {"listChanged" => false}},
        "serverInfo" => {"name" => "pte100-mcp", "version" => "0.1.0"}
      }
    end

    def call_tool(id, params)
      arguments = params["arguments"] || {}
      return error(id, -32602, "Argumentos devem ser objeto") unless arguments.is_a?(Hash)

      value = case params["name"]
              when "pte_check_text" then check_text(arguments)
              when "pte_explain_rule" then explain_rule(arguments)
              when "pte_lookup_term" then lookup_term(arguments)
              else return error(id, -32602, "Ferramenta desconhecida: #{params["name"]}")
              end
      result(id, {"content" => [{"type" => "text", "text" => JSON.generate(value)}], "structuredContent" => value, "isError" => false})
    rescue ToolError => e
      result(id, {"content" => [{"type" => "text", "text" => e.message}], "isError" => true})
    end

    def check_text(arguments)
      text = string_arg(arguments, "text")
      raise ToolError, "Texto acima de #{MAX_TEXT_BYTES} bytes; envie um trecho menor." if text.bytesize > MAX_TEXT_BYTES

      args = [RbConfig.ruby, CLI, "check", "--format", "json", "--stdin-filename", optional_arg(arguments, "filename") || "<stdin>"]
      %w[level locale].each do |key|
        value = optional_arg(arguments, key)
        args.push("--#{key}", value) if value
      end
      stdout, stderr, status = Open3.capture3(*args, stdin_data: text, chdir: @root, binmode: true)
      stdout.force_encoding(Encoding::UTF_8)
      stderr.force_encoding(Encoding::UTF_8)
      raise ToolError, "pte-lint terminou com código #{status.exitstatus}: #{stderr.strip}" unless [0, 1].include?(status.exitstatus)

      JSON.parse(stdout)
    end

    def explain_rule(arguments)
      id = string_arg(arguments, "id").upcase
      rule = rules.find { |item| item["id"] == id }
      raise ToolError, "Regra desconhecida: #{id}" unless rule

      rule.slice(*RULE_FIELDS).merge("lint" => {"mode" => rule.dig("lint", "mode"), "autofix" => rule.dig("lint", "autofix")})
    end

    def lookup_term(arguments)
      term = string_arg(arguments, "term").strip.downcase
      vocabulary = YAML.safe_load_file(File.join(@root, "vocabulary", "core.yaml"))
      concepts = vocabulary.fetch("concepts").select do |concept|
        names = [concept["preferred"], *concept["admitted"], *(concept["forbidden"] || []).map { |entry| entry["term"] }]
        names.compact.any? { |name| name.downcase == term }
      end
      {"locale" => vocabulary.fetch("locales").first, "concepts" => concepts.map { |concept| concept.slice("id", "preferred", "admitted", "forbidden", "definition", "example") }}
    end

    def rules
      @rules ||= YAML.safe_load_file(File.join(@root, "rules", "rules.yaml")).fetch("rules")
    end

    def string_arg(arguments, key)
      value = arguments[key]
      raise ToolError, "Argumento '#{key}' obrigatório (texto)." unless value.is_a?(String)

      value
    end

    def optional_arg(arguments, key)
      return nil if arguments[key].nil?

      string_arg(arguments, key)
    end

    def result(id, value)
      {"jsonrpc" => "2.0", "id" => id, "result" => value}
    end

    def error(id, code, message)
      {"jsonrpc" => "2.0", "id" => id, "error" => {"code" => code, "message" => message}}
    end
  end
end
