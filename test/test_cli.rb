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

  def test_utf8_stdin_and_output_are_independent_of_locale
    ["Faça a checagem da pressão. 🛠️", "Verifique a pressão. 🛠️", ""].each do |text|
      %w[json text].each do |format|
        args = [RbConfig.ruby, CLI, "check", "--format", format, "--stdin-filename", "x.md"]
        expected, expected_stderr, expected_status = Open3.capture3({"LC_ALL" => "C.UTF-8"}, *args, stdin_data: text)
        assert_empty expected_stderr
        [{"LC_ALL" => "C", "LANG" => nil}, {"LC_ALL" => nil, "LANG" => nil, "LC_CTYPE" => nil}].each do |env|
          stdout, stderr, status = Open3.capture3(env, *args, stdin_data: text)
          assert_equal expected_status.exitstatus, status.exitstatus, stderr
          assert_equal expected, stdout
          assert_empty stderr
        end
      end
    end
  end

  def test_invalid_utf8_stdin_returns_input_error
    _stdout, stderr, status = Open3.capture3({"LC_ALL" => "C", "LANG" => nil}, RbConfig.ruby, CLI, "check", "--stdin-filename", "x.md", stdin_data: "\xff".b)

    assert_equal 3, status.exitstatus
    assert_match(/invalid byte sequence in UTF-8/, stderr)
  end

  def test_accented_arguments_are_independent_of_locale
    text = "É necessário que o operador faça a verificação."
    Tempfile.create(["ação-ã-é", ".md"]) do |document|
      document.write(text)
      document.flush
      Tempfile.create(["configuração-ã-é", ".yaml"]) do |config|
        config.write("level: pte-claro\nlocale: pt-BR\n")
        config.flush
        %w[json text sarif].each do |format|
          base = [RbConfig.ruby, CLI, "check", "--format", format, "--config", config.path, "--level", "pte-claro", "--locale", "pt-BR"]
          [[base + ["--stdin-filename", "ação-ã-é.md"], "ação-ã-é.md"], [base + [document.path], document.path]].each do |args, filename|
            expected = Open3.capture3({"LC_ALL" => "C.UTF-8"}, *args, stdin_data: text)
            assert_equal 1, expected.last.exitstatus, expected[1]
            assert_includes JSON.parse(expected[0]).fetch("diagnostics").map { |d| d["file"] }, filename if format == "json"
            [{"LC_ALL" => "C"}, {"LC_ALL" => "POSIX"}, {"LC_ALL" => nil, "LC_CTYPE" => nil}].each do |env|
              stdout, stderr, status = Open3.capture3(env.merge("LANG" => ""), *args, stdin_data: text)
              assert_equal expected.last.exitstatus, status.exitstatus, stderr
              assert_equal expected.first, stdout
              assert_empty stderr
            end
          end
        end
      end
    end
  end

  def test_accented_level_and_locale_arguments_are_independent_of_locale
    %w[level locale].each do |option|
      args = [RbConfig.ruby, CLI, "check", "--format", "json", "--#{option}", "inválido", "--stdin-filename", "ação.md"]
      expected = Open3.capture3({"LC_ALL" => "C.UTF-8"}, *args, stdin_data: "Verifique.")
      assert_equal(option == "level" ? 2 : 0, expected.last.exitstatus)
      %w[C POSIX].each do |locale|
        stdout, stderr, status = Open3.capture3({"LC_ALL" => locale, "LANG" => ""}, *args, stdin_data: "Verifique.")
        assert_equal expected.last.exitstatus, status.exitstatus
        assert_equal expected[0, 2], [stdout, stderr]
      end
    end
  end

  def test_fail_on_never_never_fails_the_command
    Tempfile.create(["pte-lint", ".yaml"]) do |config|
      config.write("fail_on: never\n")
      config.flush
      output, status = Open3.capture2e(RbConfig.ruby, CLI, "check", "--config", config.path, "--format", "json", stdin_data: "É necessário que o operador faça a verificação.")

      assert status.success?, output
    end
  end

  def test_text_output_includes_suggestion_and_summary
    output, status = Open3.capture2e(RbConfig.ruby, CLI, "check", "--format", "text", stdin_data: "Faça a checagem da bateria.")
    assert_equal 1, status.exitstatus, output
    assert_match(/sugestão:/, output)
    assert_match(/1 arquivo\(s\), \d+ erro\(s\), \d+ aviso\(s\)/, output)
  end

  def test_missing_path_returns_input_error
    _output, status = Open3.capture2e(RbConfig.ruby, CLI, "check", File.join(ROOT, "missing.md"))

    assert_equal 3, status.exitstatus
  end
  def test_missing_input_with_explicit_config_remains_an_input_error
    Tempfile.create(["pte-lint", ".yaml"]) do |config|
      config.write("level: pte-claro\nlocale: pt-BR\n")
      config.flush
      output, status = Open3.capture2e(RbConfig.ruby, CLI, "check", File.join(ROOT, "missing.md"), "--config", config.path)
      assert_equal 3, status.exitstatus, output
    end
  end

  def test_missing_explicit_configuration_returns_configuration_error
    output, status = Open3.capture2e(RbConfig.ruby, CLI, "check", "--config", File.join(ROOT, "missing.yaml"), stdin_data: "Use XYZ.")
    assert_equal 2, status.exitstatus, output
  end

end
