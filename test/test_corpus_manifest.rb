# frozen_string_literal: true

require "minitest/autorun"
require "uri"
require "yaml"

class PteCorpusManifestTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def setup
    @manifest = YAML.safe_load(File.read(File.join(ROOT, "corpus", "sources.yaml"), encoding: "UTF-8"), permitted_classes: [], aliases: false)
  end

  def test_manifest_declares_three_complementary_sources
    assert_equal "pte-corpus-source@0.1", @manifest.fetch("schema")
    assert_equal %w[procedure reference tutorial], @manifest.fetch("sources").map { |source| source.fetch("kind") }.sort
  end

  def test_sources_have_reproducibility_and_license_metadata
    ids = @manifest.fetch("sources").map { |source| source.fetch("id") }
    assert_equal ids.uniq.sort, ids.sort
    @manifest.fetch("sources").each do |source|
      assert_match URI::DEFAULT_PARSER.make_regexp(%w[http https]), source.fetch("url")
      assert_equal "pt-BR", source.fetch("locale")
      assert source.fetch("license").fetch("attribution_required")
      refute_empty source.fetch("snapshot").fetch("strategy")
      refute_empty source.fetch("extraction").fetch("include")
    end
  end

  def test_snapshot_lock_covers_every_source
    lock = YAML.safe_load(File.read(File.join(ROOT, "corpus", "sources.lock.yaml"), encoding: "UTF-8"), permitted_classes: [], aliases: false)
    assert_equal @manifest.fetch("sources").map { |source| source.fetch("id") }.sort, lock.fetch("snapshots").map { |snapshot| snapshot.fetch("id") }.sort
    lock.fetch("snapshots").each do |snapshot|
      assert_match(/\A[0-9a-f]{64}\z/, snapshot.fetch("sha256"))
      assert_operator snapshot.fetch("units"), :>, 0
    end
  end
end
