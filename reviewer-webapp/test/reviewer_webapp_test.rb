# frozen_string_literal: true

require "json"
require "minitest/autorun"
require_relative "../server/reviewer_service"

class ReviewerWebappTest < Minitest::Test
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

  private

  def build_pdf(text)
    escaped = text.to_s.gsub(/[\\()]/) { |character| "\\#{character}" }
    stream = text ? "BT\n/F1 12 Tf\n72 720 Td\n(#{escaped}) Tj\nET\n" : "BT\nET\n"
    objects = [
      "<< /Type /Catalog /Pages 2 0 R >>",
      "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
      "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
      "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
      "<< /Length #{stream.bytesize} >>\nstream\n#{stream}endstream"
    ]
    pdf = +"%PDF-1.4\n"
    offsets = [0]
    objects.each_with_index do |object, index|
      offsets << pdf.bytesize
      pdf << "#{index + 1} 0 obj\n#{object}\nendobj\n"
    end
    xref_offset = pdf.bytesize
    pdf << "xref\n0 #{objects.length + 1}\n"
    pdf << "0000000000 65535 f \n"
    offsets.drop(1).each { |offset| pdf << format("%010d 00000 n \n", offset) }
    pdf << "trailer\n<< /Size #{objects.length + 1} /Root 1 0 R >>\n"
    pdf << "startxref\n#{xref_offset}\n%%EOF\n"
    pdf
  end
end
