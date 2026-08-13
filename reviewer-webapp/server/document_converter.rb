# frozen_string_literal: true

require "base64"
require "stringio"
require "timeout"

begin
  require "pdf/reader"
rescue LoadError
  # A capacidade informa a ausência da dependência sem impedir TXT/Markdown.
end

class DocumentConverter
  MAX_BYTES = 5 * 1024 * 1024
  MAX_PDF_PAGES = 200
  MAX_EXTRACTED_CHARACTERS = 1_500_000
  CONVERSION_TIMEOUT = 20
  TEXT_FORMATS = %w[markdown text].freeze

  class ConversionError < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super(message)
    end
  end

  def formats
    TEXT_FORMATS + (pdf_available? ? ["pdf"] : [])
  end

  def capabilities
    {
      "pdf" => {
        "available" => pdf_available?,
        "engine" => "pdf-reader",
        "mode" => "text-layer",
        "max_pages" => MAX_PDF_PAGES,
        "ocr" => false
      }
    }
  end

  def extract(document)
    format = document["format"].to_s
    return extract_text(document) if TEXT_FORMATS.include?(format)
    return extract_pdf(document) if format == "pdf"

    raise ConversionError.new("unsupported_format", "Formato não aceito. Use Markdown, texto simples ou PDF.")
  end

  def pdf_available?
    !defined?(PDF::Reader).nil?
  end

  private

  def extract_text(document)
    content = document["content"]
    unless content.is_a?(String) && content.valid_encoding?
      raise ConversionError.new("invalid_content", "O conteúdo deve ser texto UTF-8.")
    end
    raise ConversionError.new("document_too_large", "O documento excede o limite local de 5 MB.") if content.bytesize > MAX_BYTES
    raise ConversionError.new("empty_document", "O documento está vazio.") if content.strip.empty?

    content
  end

  def extract_pdf(document)
    unless pdf_available?
      raise ConversionError.new("converter_unavailable", "O conversor de PDF não está instalado. Execute bundle install na pasta do revisor.")
    end

    encoded = document["data_base64"]
    raise ConversionError.new("invalid_content", "Os dados do PDF não foram informados.") unless encoded.is_a?(String)

    bytes = Base64.strict_decode64(encoded)
    raise ConversionError.new("document_too_large", "O PDF excede o limite local de 5 MB.") if bytes.bytesize > MAX_BYTES
    raise ConversionError.new("invalid_pdf", "O arquivo não tem uma assinatura PDF válida.") unless bytes.start_with?("%PDF-")

    text = Timeout.timeout(CONVERSION_TIMEOUT) do
      reader = PDF::Reader.new(StringIO.new(bytes))
      if reader.page_count > MAX_PDF_PAGES
        raise ConversionError.new("document_too_large", "O PDF excede o limite local de #{MAX_PDF_PAGES} páginas.")
      end

      extracted = +""
      reader.pages.each do |page|
        extracted << "\n\n" unless extracted.empty?
        extracted << page.text
        if extracted.length > MAX_EXTRACTED_CHARACTERS
          raise ConversionError.new("document_too_large", "O texto extraído do PDF excede o limite local.")
        end
      end
      extracted
    end
    if text.strip.empty?
      raise ConversionError.new("pdf_without_text", "Este PDF não contém texto selecionável. OCR não está habilitado neste revisor.")
    end
    text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "�")
  rescue ArgumentError
    raise ConversionError.new("invalid_content", "Os dados do PDF estão corrompidos.")
  rescue Timeout::Error
    raise ConversionError.new("conversion_timeout", "A conversão do PDF excedeu o tempo permitido.")
  rescue ConversionError
    raise
  rescue StandardError
    raise ConversionError.new("invalid_pdf", "Não foi possível extrair o texto deste PDF.")
  end
end
