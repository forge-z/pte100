# frozen_string_literal: true

require "json"
require_relative "support/pdf_fixture"
require "minitest/autorun"
require_relative "../server/reviewer_service"

class ReviewerWebappTest < Minitest::Test
  include ReviewerPdfFixture
  def setup
    @service = ReviewerService.new(root: File.expand_path("../..", __dir__), session_token: "test-token")
  end

  def test_capabilities_are_local_and_explicit
    capabilities = @service.capabilities
    assert_equal "pte-100-reviewer", capabilities["service"]
    assert_includes capabilities["formats"], "markdown"
    assert_includes capabilities["formats"], "text"
    assert_includes capabilities["formats"], "pdf"
    assert_equal "pdf-reader", capabilities.dig("converters", "pdf", "engine")
    assert_equal "test-token", capabilities["session_token"]
    assert_operator capabilities["max_bytes"], :>, 0
  end

  def test_review_matches_the_pte_lint_result_contract
    result = @service.review(
      "document" => {
        "name" => "procedimento.md",
        "format" => "markdown",
        "content" => "É necessário que o operador faça a verificação da qtd."
      },
      "configuration" => {"level" => "pte-claro", "locale" => "pt-BR"}
    )

    assert_equal "1.0", result["schema_version"]
    assert_equal "pte-lint", result.dig("tool", "name")
    assert_equal 1, result.dig("summary", "files")
    assert_operator result["diagnostics"].length, :>, 0
    assert result["diagnostics"].all? { |diagnostic| diagnostic["file"] == "procedimento.md" }
    assert result["diagnostics"].all? { |diagnostic| diagnostic.dig("range", "start", "line").is_a?(Integer) }
  end

  def test_review_rejects_paths_and_unknown_formats
    path_result = @service.review("document" => {"name" => "../secreto.md", "format" => "markdown", "content" => "texto"}, "configuration" => {"level" => "pte-claro", "locale" => "pt-BR"})
    format_result = @service.review("document" => {"name" => "arquivo.docx", "format" => "docx", "content" => "texto"}, "configuration" => {"level" => "pte-claro", "locale" => "pt-BR"})

    assert_equal "invalid_name", path_result.dig("error", "code")
    assert_equal "unsupported_format", format_result.dig("error", "code")
  end

  def test_pdf_is_extracted_in_memory_and_reviewed
    pdf = build_pdf("Procedimento tecnico local")
    result = @service.review(
      "document" => {"name" => "procedimento.pdf", "format" => "pdf", "data_base64" => Base64.strict_encode64(pdf)},
      "configuration" => {"level" => "pte-claro", "locale" => "pt-BR"}
    )

    assert_equal "1.0", result["schema_version"]
    assert_equal 1, result.dig("summary", "files")
    assert result["diagnostics"].all? { |diagnostic| diagnostic["file"] == "procedimento.pdf" }
  end

  def test_pdf_without_selectable_text_is_rejected
    pdf = build_pdf(nil)
    result = @service.review(
      "document" => {"name" => "digitalizado.pdf", "format" => "pdf", "data_base64" => Base64.strict_encode64(pdf)},
      "configuration" => {"level" => "pte-claro", "locale" => "pt-BR"}
    )

    assert_equal "pdf_without_text", result.dig("error", "code")
  end

  def test_review_rejects_invalid_configuration
    result = @service.review("document" => {"name" => "arquivo.md", "format" => "markdown", "content" => "texto"}, "configuration" => {"level" => "pte-inexistente", "locale" => "pt-BR"})

    assert_equal "invalid_level", result.dig("error", "code")
  end

  def test_rule_lookup_is_read_only_metadata
    result = @service.rule("R005")

    assert_equal "R005", result["id"]
    assert result["title"]
    refute result.key?("content")
  end

end
