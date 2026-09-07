# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "tempfile"

class PteLintCliTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  CLI = File.join(ROOT, "bin", "pte-lint")

  def test_stdin_filename_is_reported
    output, status = Open3.capture2e(RbConfig.ruby, CLI, "check", "--format", "json", "--stdin-filename", "sample.md", stdin_data: "Use XYZ.")

    assert_equal 1, status.exitstatus, output
    assert_equal "sample.md", JSON.parse(output).dig("diagnostics", 0, "file")
  end

  def test_fail_on_never_never_fails_the_command
    Tempfile.create(["pte-lint", ".yaml"]) do |config|
      config.write("fail_on: never\n")
      config.flush
      output, status = Open3.capture2e(RbConfig.ruby, CLI, "check", "--config", config.path, "--format", "json", stdin_data: "É necessário que o operador faça a verificação.")

      assert status.success?, output
    end
  end

  def test_missing_path_returns_input_error
    _output, status = Open3.capture2e(RbConfig.ruby, CLI, "check", File.join(ROOT, "missing.md"))

    assert_equal 3, status.exitstatus
  end
end
