# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

class PteIngestCorpusTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_convert_extracts_units_without_network
    Dir.mktmpdir("pte-corpus") do |directory|
      input_path = File.join(directory, "input.html")
      output_dir = File.join(directory, "units")
      File.write(input_path, <<~HTML, encoding: "UTF-8")
        <html><body><nav>Menu</nav><h1>Título</h1><p>Verifique a configuração.</p><pre>kubectl get pods</pre><script>ignore</script></body></html>
      HTML
      command = [RbConfig.ruby, File.join(ROOT, "tools", "ingest_corpus.rb"), "convert", "--source", "mdn-html-ptbr", "--input", input_path, "--output", output_dir]
      stdout, stderr, status = Open3.capture3(*command)
      assert status.success?, "#{stdout}\n#{stderr}"
      path = File.join(output_dir, "mdn-html-ptbr.jsonl")
      records = File.readlines(path, encoding: "UTF-8").map { |line| JSON.parse(line) }
      assert_equal ["h1", "p", "pre"], records.map { |record| record.fetch("element") }
      assert_equal "Título", records.first.fetch("text")
      assert_equal "kubectl get pods", records.last.fetch("text")
      assert records.all? { |record| record.fetch("source_id") == "mdn-html-ptbr" }
      assert records.all? { |record| record.fetch("retrieved_from").start_with?("cache://") }
      refute records.any? { |record| record.fetch("retrieved_from").include?(ROOT) }
    end
  end

  def test_annotation_template_does_not_require_source_text
    Dir.mktmpdir("pte-annotations") do |directory|
      input = File.join(directory, "result.json")
      output = File.join(directory, "annotations.jsonl")
      File.write(input, JSON.generate("results" => [{"id" => "source#u0001", "source_id" => "source", "source_url" => "https://example.org/doc", "license" => {"name" => "CC0"}, "element" => "p", "sha256" => "a" * 64, "text" => "texto", "diagnostics" => []}]), encoding: "UTF-8")
      command = [RbConfig.ruby, File.join(ROOT, "tools", "prepare_annotations.rb"), input, "--output", output, "--metadata-only"]
      stdout, stderr, status = Open3.capture3(*command)
      assert status.success?, "#{stdout}\n#{stderr}"
      annotation = JSON.parse(File.read(output, encoding: "UTF-8"))
      assert_equal "uncertain", annotation.fetch("decision")
      refute annotation.key?("text")
      refute annotation.values.any? { |value| value.is_a?(String) && value.include?(ROOT) }
    end
  end
end
