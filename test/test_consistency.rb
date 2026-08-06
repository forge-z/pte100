# frozen_string_literal: true

require "minitest/autorun"
require "yaml"

class PteConsistencyTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def setup
    @rules = YAML.safe_load(File.read(File.join(ROOT, "rules", "rules.yaml"), encoding: "UTF-8"), permitted_classes: [], aliases: false).fetch("rules")
    @vocabulary = YAML.safe_load(File.read(File.join(ROOT, "vocabulary", "core.yaml"), encoding: "UTF-8"), permitted_classes: [], aliases: false).fetch("concepts")
    @readme = File.read(File.join(ROOT, "README.md"), encoding: "UTF-8")
    @catalog = File.read(File.join(ROOT, "rules", "catalog.md"), encoding: "UTF-8")
  end

  def test_catalog_contains_every_rule
    @rules.each { |rule| assert_includes @catalog, "### #{rule.fetch("id")} —" }
  end

  def test_automatic_count_matches_mvp_contract
    assert_equal 21, @rules.count { |rule| rule.dig("lint", "mode") == "automatic" }
    assert_equal 29, @rules.count { |rule| rule.dig("lint", "mode") == "assisted" }
  end

  def test_rule_correct_examples_do_not_use_forbidden_forms
    # A resolução de sentido ainda não faz parte do MVP. Portanto, a
    # consistência automática fica restrita ao conceito demonstrado por R001;
    # formas como "ligar" e "até" podem ser válidas em outros sentidos.
    concept = @vocabulary.find { |item| item.fetch("id") == "PTE-C0001" }
    forbidden = concept.fetch("forbidden").map { |form| form.fetch("term") }
    @rules.each do |rule|
      correct = rule.fetch("correct").downcase
      forbidden.each do |term|
        refute_match(/(?<![\p{L}\p{N}])#{Regexp.escape(term.downcase)}(?![\p{L}\p{N}])/u, correct, "#{rule.fetch("id")} usa '#{term}' no exemplo correto")
      end
    end
  end

  def test_readme_quick_example_does_not_use_forbidden_limit_expression
    refute_includes @readme, "até a marca **MÁX**"
    assert_includes @readme, "pare quando o nível alcançar a marca **MÁX**"
  end

  def test_r001_example_keeps_one_concept
    r001 = @rules.find { |rule| rule.fetch("id") == "R001" }
    assert_includes r001.fetch("incorrect"), "bateria"
    assert_includes r001.fetch("correct"), "bateria"
    refute_includes r001.fetch("correct"), "acumulador"
    refute_includes r001.fetch("correct"), "bateria auxiliar"
    assert_includes r001.fetch("correct"), "registre o estado"
  end
end
