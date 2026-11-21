# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require_relative "../lib/pte_mcp"
require_relative "support/json_schema_subset"

class PteMcpServerTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SERVER = File.join(ROOT, "bin", "pte-mcp")
  DIAGNOSTIC_SCHEMA = JsonSchemaSubset.load(File.join(ROOT, "schemas", "diagnostic.schema.json"))

  def test_initialize_and_list_tools
    responses = session({"method" => "tools/list"})

    assert_equal "2025-06-18", responses.fetch(0).dig("result", "protocolVersion")
    assert_equal({"listChanged" => false}, responses.fetch(0).dig("result", "capabilities", "tools"))
    assert_equal %w[pte_check_text pte_explain_rule pte_lookup_term], responses.fetch(1).dig("result", "tools").map { |tool| tool["name"] }
  end

  def test_check_text_returns_cli_document
    result = tool("pte_check_text", "text" => "Faça a checagem da bateria.")

    refute result["isError"]
    document = result.fetch("structuredContent")
    assert_empty DIAGNOSTIC_SCHEMA.errors(document)
    assert_includes document.fetch("diagnostics").map { |d| d["rule"] }, "R001"
    assert_equal document, JSON.parse(result.dig("content", 0, "text"))
    assert_equal %w[pte-claro pt-BR], document.fetch("configuration").values_at("level", "locale")
  end

  def test_check_text_passes_level_locale_and_filename
    document = tool("pte_check_text", "text" => "Verifique a bateria.", "level" => "pte-ia", "locale" => "pt-BR", "filename" => "doc.md").fetch("structuredContent")

    assert_equal "pte-ia", document.dig("configuration", "level")
    assert_empty document.fetch("diagnostics")
  end

  def test_check_text_rejects_text_above_limit
    result = tool("pte_check_text", "text" => "a" * (PteMcp::MAX_TEXT_BYTES + 1))

    assert result["isError"]
    assert_match(/acima de/, result.dig("content", 0, "text"))
  end

  def test_check_text_tool_error_on_invalid_level
    result = tool("pte_check_text", "text" => "Verifique.", "level" => "pte-inexistente")

    assert result["isError"]
    assert_match(/código 2/, result.dig("content", 0, "text"))
  end

  def test_explain_rule
    rule = tool("pte_explain_rule", "id" => "R038").fetch("structuredContent")

    assert_equal "safe", rule.dig("lint", "autofix")
    assert_equal "automatic", rule.dig("lint", "mode")
    assert_equal "Ajuste para 24\u00a0V e 30\u00a0°C.", rule["correct"]
    assert_equal %w[correct description id incorrect level lint rationale severity title], rule.keys.sort
  end

  def test_explain_unknown_rule_fails
    result = tool("pte_explain_rule", "id" => "R051")

    assert result["isError"]
    refute result.key?("structuredContent")
  end

  def test_lookup_term
    found = tool("pte_lookup_term", "term" => "Checar").fetch("structuredContent")

    assert_equal "pt-BR", found["locale"]
    concept = found.fetch("concepts").fetch(0)
    assert_equal "PTE-C0001", concept["id"]
    assert_equal "verificar", concept["preferred"]
    assert_equal "verificar", concept.fetch("forbidden").find { |entry| entry["term"] == "checar" }["replacement"]
    assert_empty tool("pte_lookup_term", "term" => "inexistente").dig("structuredContent", "concepts")
  end

  def test_protocol_errors
    responses = raw_session(["{", JSON.generate({"jsonrpc" => "2.0", "id" => 1, "method" => "resources/list"}),
                             JSON.generate({"jsonrpc" => "2.0", "id" => 2, "method" => "tools/call", "params" => {"name" => "pte_fix"}})])

    assert_equal [-32700, -32601, -32602], responses.map { |r| r.dig("error", "code") }
  end

  def test_utf8_stdio_is_independent_of_locale
    lines = [JSON.generate({"jsonrpc" => "2.0", "id" => 1, "method" => "tools/call", "params" => {
      "name" => "pte_check_text", "arguments" => {"text" => "Faça a checagem da pressão. 🛠️", "filename" => "acentuação-😀.md"}
    }})]
    expected = raw_session(lines, env: {"LC_ALL" => "C.UTF-8"})
    [{"LC_ALL" => "C", "LANG" => nil}, {"LC_ALL" => nil, "LANG" => nil, "LC_CTYPE" => nil}].each do |env|
      assert_equal expected, raw_session(lines, env: env)
    end
    refute expected.fetch(0).dig("result", "isError")
    assert_equal "R001", expected.fetch(0).dig("result", "structuredContent", "diagnostics", 0, "rule")
  end

  def test_malformed_messages_do_not_stop_the_process
    cases = [
      ["{", -32700, nil],
      ["\xff".b, -32700, nil],
      [JSON.generate([{"jsonrpc" => "2.0", "id" => 1, "method" => "ping"}]), -32600, nil],
      [JSON.generate({"jsonrpc" => "2.0", "id" => nil, "method" => "ping"}), -32600, nil]
    ]
    %w[initialize tools/call].each do |method|
      [[], "texto", 1, true, nil].each do |params|
        cases << [JSON.generate({"jsonrpc" => "2.0", "id" => 1, "method" => method, "params" => params}), -32602, 1]
      end
    end
    cases.each do |line, code, id|
      responses = raw_session([line, JSON.generate({"jsonrpc" => "2.0", "id" => 2, "method" => "ping"})], env: {"LC_ALL" => "C", "LANG" => nil})
      assert_equal 2, responses.length
      assert_equal code, responses.fetch(0).dig("error", "code")
      assert_equal [id], [responses.fetch(0)["id"]]
      assert_equal({"jsonrpc" => "2.0", "id" => 2, "result" => {}}, responses.fetch(1))
    end
  end

  def test_notifications_remain_silent_even_with_invalid_params
    lines = [
      {"jsonrpc" => "2.0", "method" => "notifications/initialized"},
      {"jsonrpc" => "2.0", "method" => "initialize", "params" => []},
      {"jsonrpc" => "2.0", "method" => "tools/call", "params" => []},
      {"jsonrpc" => "2.0", "id" => 1, "method" => "ping"}
    ]
    assert_equal [{"jsonrpc" => "2.0", "id" => 1, "result" => {}}], raw_session(lines.map { |line| JSON.generate(line) })
  end

  def test_unexpected_exception_returns_internal_error_and_keeps_serving
    injection = 'require_relative "lib/pte_mcp"; class PteMcp::Server; def initialize_result(requested); raise "detalhe privado"; end; end; load ARGV.fetch(0)'
    lines = [
      {"jsonrpc" => "2.0", "id" => "init", "method" => "initialize"},
      {"jsonrpc" => "2.0", "method" => "initialize"},
      {"jsonrpc" => "2.0", "id" => 2, "method" => "ping"}
    ]
    responses = raw_session(lines.map { |line| JSON.generate(line) }, ruby_options: ["-e", injection])
    assert_equal 2, responses.length
    assert_equal({"jsonrpc" => "2.0", "id" => "init", "error" => {"code" => -32603, "message" => "Erro interno"}}, responses.fetch(0))
    assert_equal({"jsonrpc" => "2.0", "id" => 2, "result" => {}}, responses.fetch(1))
  end

  def test_session_does_not_write_workspace
    before = workspace_state
    session({"method" => "tools/list"},
            {"method" => "tools/call", "params" => {"name" => "pte_check_text", "arguments" => {"text" => "Faça a checagem da bateria."}}},
            {"method" => "tools/call", "params" => {"name" => "pte_explain_rule", "arguments" => {"id" => "R001"}}},
            {"method" => "tools/call", "params" => {"name" => "pte_lookup_term", "arguments" => {"term" => "checar"}}})

    assert_equal before, workspace_state
  end

  private

  def tool(name, arguments)
    session({"method" => "tools/call", "params" => {"name" => name, "arguments" => arguments}}).last.fetch("result")
  end

  def session(*requests)
    lines = [{"method" => "initialize", "params" => {"protocolVersion" => "2025-06-18", "capabilities" => {}, "clientInfo" => {"name" => "test", "version" => "0"}}}]
    messages = lines.concat(requests).each_with_index.map { |request, index| {"jsonrpc" => "2.0", "id" => index + 1}.merge(request) }
    messages.insert(1, {"jsonrpc" => "2.0", "method" => "notifications/initialized"})
    raw_session(messages.map { |message| JSON.generate(message) })
  end

  def raw_session(lines, env: {}, ruby_options: [])
    input = lines.map(&:b).join("\n") + "\n"
    stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, *ruby_options, SERVER, stdin_data: input, chdir: ROOT)
    assert status.success?, stderr
    assert_empty stderr
    stdout.lines.map { |line| JSON.parse(line) }
  end

  def workspace_state
    Dir.glob("**/*", File::FNM_DOTMATCH, base: ROOT).reject { |path| path.start_with?(".git/") || path.include?("node_modules/") }
       .sort.map { |path| full = File.join(ROOT, path); [path, File.file?(full) ? [File.size(full), File.mtime(full).to_r] : :dir] }
  end
end
