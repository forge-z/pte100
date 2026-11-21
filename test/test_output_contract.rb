# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require_relative "../lib/pte_lint"
require_relative "support/json_schema_subset"

class PteLintOutputContractTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  CLI = File.join(ROOT, "bin", "pte-lint")
  FIXTURES = File.join("corpus", "fixtures")
  DIAGNOSTIC_SCHEMA = JsonSchemaSubset.load(File.join(ROOT, "schemas", "diagnostic.schema.json"))
  SARIF_SCHEMA = JsonSchemaSubset.load(File.join(ROOT, "schemas", "pte-lint-sarif.schema.json"))
  CLEAN_TEXT = "Verifique a bateria."

  def test_fixture_json_output_matches_diagnostic_schema
    result = check_json(FIXTURES)

    assert_empty DIAGNOSTIC_SCHEMA.errors(result)
    assert_equal 42, result.dig("summary", "files")
    assert_equal PteLint::AUTOMATIC_RULES.sort, result.fetch("diagnostics").map { |d| d.fetch("rule") }.uniq.sort
  end

  def test_text_without_diagnostics_matches_diagnostic_schema
    result = check_json(stdin: CLEAN_TEXT)

    assert_empty DIAGNOSTIC_SCHEMA.errors(result)
    assert_empty result.fetch("diagnostics")
    assert_equal 1, result.dig("summary", "files")
  end

  def test_safe_fix_matches_diagnostic_schema
    %w[R038 R039].each do |rule|
      result = check_json(File.join(FIXTURES, "positive", "#{rule}.md"))
      diagnostic = result.fetch("diagnostics").find { |d| d.fetch("rule") == rule }

      assert_empty DIAGNOSTIC_SCHEMA.errors(result), rule
      assert_equal({"safety" => "safe", "replacement" => diagnostic.fetch("suggestion")}, diagnostic.fetch("fix"), rule)
    end
  end

  def test_fix_is_only_emitted_by_safe_rules
    rules_with_fix = check_json(FIXTURES).fetch("diagnostics").select { |d| d.key?("fix") }.map { |d| d.fetch("rule") }.uniq.sort

    assert_equal %w[R038 R039], rules_with_fix
  end

  def test_diagnostic_schema_rejects_contract_violations
    valid = check_json(File.join(FIXTURES, "positive", "R038.md"))
    assert_empty DIAGNOSTIC_SCHEMA.errors(valid)

    violations = {
      "campo não previsto" => ->(d) { d["x_extra"] = true },
      "severidade inválida" => ->(d) { d["severity"] = "note" },
      "fingerprint ausente" => ->(d) { d.delete("fingerprint") },
      "fix sem replacement" => ->(d) { d["fix"].delete("replacement") },
      "coluna base 0" => ->(d) { d["range"]["start"]["column"] = 0 },
      "offset como texto" => ->(d) { d["range"]["start"]["offset"] = "0" }
    }
    violations.each do |name, mutate|
      broken = JSON.parse(JSON.generate(valid))
      mutate.call(broken.fetch("diagnostics").first)
      refute_empty DIAGNOSTIC_SCHEMA.errors(broken), name
    end
  end

  def test_fixture_sarif_output_matches_published_subset
    sarif = check(FIXTURES, format: "sarif")
    json = check_json(FIXTURES)

    assert_empty SARIF_SCHEMA.errors(sarif)
    assert_equal sarif_view(json), sarif.dig("runs", 0, "results").map { |result| sarif_result_view(result) }
  end

  def test_sarif_without_results_matches_published_subset
    sarif = check(stdin: CLEAN_TEXT, format: "sarif")

    assert_empty SARIF_SCHEMA.errors(sarif)
    assert_empty sarif.dig("runs", 0, "results")
  end

  def test_sarif_subset_rejects_fields_outside_current_emitter
    valid = check(File.join(FIXTURES, "positive", "R001.md"), format: "sarif")
    region = ->(document) { document.dig("runs", 0, "results", 0, "locations", 0, "physicalLocation", "region") }

    broken = JSON.parse(JSON.generate(valid))
    region.call(broken)["endLine"] = 1
    refute_empty SARIF_SCHEMA.errors(broken)

    broken = JSON.parse(JSON.generate(valid))
    broken.dig("runs", 0, "results", 0)["level"] = "note"
    refute_empty SARIF_SCHEMA.errors(broken)
  end

  def test_validator_refuses_unsupported_keywords
    assert_raises(ArgumentError) { JsonSchemaSubset.new({"type" => "string", "pattern" => "^R"}).errors("R001") }
  end

  private

  def check(*paths, format:, stdin: nil)
    args = [RbConfig.ruby, CLI, "check", *paths, "--level", "pte-ia", "--locale", "pt-BR", "--format", format]
    output, error, status = Open3.capture3(*args, stdin_data: stdin.to_s, chdir: ROOT)
    assert_includes [0, 1], status.exitstatus, error
    JSON.parse(output)
  end

  def check_json(*paths, stdin: nil)
    check(*paths, format: "json", stdin: stdin)
  end

  def sarif_view(json)
    json.fetch("diagnostics").map do |d|
      [d.fetch("rule"), d.fetch("severity"), d.fetch("message"), d.fetch("file"), d.dig("range", "start", "line"), d.dig("range", "start", "column")]
    end
  end

  def sarif_result_view(result)
    location = result.dig("locations", 0, "physicalLocation")
    [result.fetch("ruleId"), result.fetch("level"), result.dig("message", "text"), location.dig("artifactLocation", "uri"), location.dig("region", "startLine"), location.dig("region", "startColumn")]
  end
end
