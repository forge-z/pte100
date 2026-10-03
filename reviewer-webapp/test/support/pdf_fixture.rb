# frozen_string_literal: true

module ReviewerPdfFixture
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
