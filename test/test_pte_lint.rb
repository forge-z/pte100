# frozen_string_literal: true

require "minitest/autorun"
require "yaml"
require_relative "../lib/pte_lint"

class PteLintFixturesTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def setup
    @pack = PteLint::RulePack.new(File.join(ROOT, "rules", "rules.yaml"))
    @vocabulary = PteLint::Vocabulary.new(File.join(ROOT, "vocabulary", "core.yaml"))
    @config = PteLint::Config.new("level" => "pte-ia", "locale" => "pt-BR")
    @engine = PteLint::Engine.new(rule_pack: @pack, vocabulary: @vocabulary, config: @config)
    @cases = YAML.safe_load(File.read(File.join(ROOT, "corpus", "cases.yaml"), encoding: "UTF-8"), permitted_classes: [], aliases: false).fetch("cases")
  end

  def test_every_automatic_rule_has_an_implementation
    automatic = @pack.automatic.map { |rule| rule.fetch("id") }
    assert_equal PteLint::AUTOMATIC_RULES.sort, automatic.sort
    automatic.each { |id| assert @engine.respond_to?("check_#{id}", true), "#{id} não tem implementação" }
  end

  def test_positive_cases_emit_their_expected_rule
    @cases.select { |item| item.fetch("class") == "positive" }.each do |item|
      diagnostics = @engine.check_text(item.fetch("text"), "positive/#{item.fetch("id")}.md")
      assert_includes diagnostics.map { |diagnostic| diagnostic.fetch("rule") }, item.fetch("id"), item.fetch("note")
    end
  end

  def test_negative_cases_do_not_emit_their_expected_rule
    @cases.select { |item| item.fetch("class") == "negative" }.each do |item|
      diagnostics = @engine.check_text(item.fetch("text"), "negative/#{item.fetch("id")}.md")
      refute_includes diagnostics.map { |diagnostic| diagnostic.fetch("rule") }, item.fetch("id"), item.fetch("note")
    end
  end

  def test_json_result_has_stable_contract
    runner = PteLint::Runner.new(level: "pte-ia", locale: "pt-BR")
    diagnostics = runner.check([File.join(ROOT, "corpus", "fixtures", "positive", "R040.md")])
    result = runner.result(diagnostics, files: 1)
    assert_equal "1.0", result.fetch("schema_version")
    assert_equal "pte-lint", result.dig("tool", "name")
    assert_equal "R040", result.dig("diagnostics", 0, "rule")
    assert_equal 1, result.dig("summary", "files")
  end

  def test_decimal_rule_ignores_versions_and_section_numbers
    diagnostics = @engine.check_text("Versão 1.25.3. Consulte a seção 5.1.", "versions.md")
    refute_includes diagnostics.map { |diagnostic| diagnostic.fetch("rule") }, "R042"
  end

  def test_range_rule_requires_a_measurement_unit
    diagnostics = @engine.check_text("Código de versão 2020-12.", "version.md")
    refute_includes diagnostics.map { |diagnostic| diagnostic.fetch("rule") }, "R040"
  end

  def test_decimal_rule_ignores_numbered_table_of_contents_items
    text = "2. Utilizando o interpretador Python 2.1. Chamando o interpretador"
    diagnostics = @engine.check_text(text, "toc.html#u1", context: {"element" => "li", "source_id" => "python-tutorial-ptbr"})
    refute_includes diagnostics.map { |diagnostic| diagnostic.fetch("rule") }, "R042"
  end

  def test_signal_word_rule_ignores_headings
    diagnostics = @engine.check_text("HTML: Linguagem de Marcação de Hipertexto", "heading.html#u1", context: {"element" => "h1"})
    refute_includes diagnostics.map { |diagnostic| diagnostic.fetch("rule") }, "R031"
  end

  def test_conditional_rule_distinguishes_reflexive_se
    refute_includes @engine.check_text("Você se torna responsável.", "reflexive.md").map { |d| d.fetch("rule") }, "R014"
    assert_includes @engine.check_text("Faça isso se necessário.", "condition.md").map { |d| d.fetch("rule") }, "R014"
  end

  def test_vocabulary_allows_torque_context_but_flags_button_context
    torque = @engine.check_text("Aperte os parafusos a 12 N·m.", "torque.md")
    button = @engine.check_text("Aperte o botão REINICIAR.", "button.md")
    refute_includes torque.map { |d| d.fetch("rule") }, "R001"
    assert_includes button.map { |d| d.fetch("rule") }, "R001"
  end

  def test_source_profile_extends_acronym_allowlist_without_global_change
    config = PteLint::Config.new("level" => "pte-ia", "locale" => "pt-BR", "profile_definitions" => {"mdn-web" => {"acronym_allowlist" => ["CSS"], "term_allowlist" => ["colocar"]}}, "source_profiles" => {"mdn-html-ptbr" => "mdn-web"})
    engine = PteLint::Engine.new(rule_pack: @pack, vocabulary: @vocabulary, config: config)
    mdn = engine.check_text("Use CSS.", "mdn.html#u1", context: {"source_id" => "mdn-html-ptbr"})
    generic = engine.check_text("Use CSS.", "generic.md")
    refute_includes mdn.map { |d| d.fetch("rule") }, "R004"
    assert_includes generic.map { |d| d.fetch("rule") }, "R004"
    refute_includes engine.check_text("Use colocar neste contexto.", "mdn.html#u2", context: {"source_id" => "mdn-html-ptbr"}).map { |d| d.fetch("rule") }, "R001"
  end
end
