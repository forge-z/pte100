#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "webrick"
require_relative "reviewer_service"

class ReviewerServer
  CLIENT_ROOT = File.expand_path("../client", __dir__)
  MAX_REQUEST_BYTES = ((ReviewerService::MAX_BYTES + 2) / 3 * 4) + (128 * 1024)

  def initialize(host: "127.0.0.1", port: 0, client_root: CLIENT_ROOT, service: ReviewerService.new)
    @host = host
    @port = port
    @client_root = client_root
    @service = service
  end

  def start
    raise "O serviço só pode ser executado em loopback." unless %w[127.0.0.1 ::1 localhost].include?(@host)

    @server = WEBrick::HTTPServer.new(
      BindAddress: @host,
      Port: @port,
      AccessLog: [],
      Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN),
      DoNotReverseLookup: true
    )
    @server.mount_proc "/" do |request, response|
      handle(request, response)
    end
    trap("INT") { stop }
    begin
      trap("TERM") { stop }
    rescue ArgumentError
      # Algumas versões do Ruby no Windows não expõem SIGTERM.
    end
    puts "PTE-100 Reviewer local: http://#{@host}:#{@server.config[:Port]}/"
    puts "Privacidade: o serviço está ligado somente em loopback."
    @server.start
  end

  def stop
    @server&.shutdown
  end

  private

  def handle(request, response)
    set_common_headers(response)
    path = request.path
    if path == "/api/v1/capabilities" && request.request_method == "GET"
      json(response, 200, @service.capabilities)
    elsif path == "/api/v1/health" && request.request_method == "GET"
      json(response, 200, { "status" => "ok", "service_version" => "0.2.0" })
    elsif path.start_with?("/api/v1/rules/") && request.request_method == "GET"
      require_session(request, response) do
        result = @service.rule(path.split("/").last)
        json(response, result.key?("error") ? status_for(result["error"]["code"]) : 200, result)
      end
    elsif path == "/api/v1/reviews" && request.request_method == "POST"
      require_session(request, response) { handle_review(request, response) }
    elsif path.start_with?("/api/")
      json(response, 404, ReviewerService.error("not_found", "Endpoint local não encontrado."))
    else
      serve_client(path, response)
    end
  rescue WEBrick::HTTPStatus::RequestEntityTooLarge
    json(response, 413, ReviewerService.error("request_too_large", "A requisição excede o limite local."))
  rescue StandardError => error
    warn "reviewer-webapp server error: #{error.class}: #{error.message}" if ENV["PTE_REVIEWER_DEBUG"] == "1"
    json(response, 500, ReviewerService.error("internal_error", "Falha no serviço local."))
  end

  def handle_review(request, response)
    content_length = request.header["content-length"]&.first.to_i
    raise WEBrick::HTTPStatus::RequestEntityTooLarge if content_length > MAX_REQUEST_BYTES
    body = request.body.to_s
    raise WEBrick::HTTPStatus::RequestEntityTooLarge if body.bytesize > MAX_REQUEST_BYTES
    payload = JSON.parse(body)
    result = @service.review(payload)
    status = result.key?("error") ? status_for(result["error"]["code"]) : 200
    json(response, status, result)
  rescue JSON::ParserError
    json(response, 400, ReviewerService.error("invalid_json", "A requisição não é um JSON válido."))
  end

  def require_session(request, response)
    unless secure_request?(request)
      json(response, 403, ReviewerService.error("forbidden", "Origem ou sessão local inválida."))
      return
    end
    yield
  end

  def secure_request?(request)
    request.header["x-pte-session"]&.first == @service.session_token && allowed_origin?(request)
  end

  def allowed_origin?(request)
    origin = request.header["origin"]&.first
    return true if origin.nil? || origin.empty?
    origin == "http://#{request.host}:#{request.port}" || origin == "http://127.0.0.1:#{request.port}" || origin == "http://localhost:#{request.port}"
  end

  def status_for(code)
    { "invalid_json" => 400, "invalid_request" => 400, "invalid_document" => 400, "invalid_name" => 400, "unsupported_format" => 415, "converter_unavailable" => 503, "invalid_content" => 400, "invalid_pdf" => 422, "pdf_without_text" => 422, "empty_document" => 400, "document_too_large" => 413, "conversion_timeout" => 408, "conversion_failed" => 422, "invalid_level" => 400, "invalid_locale" => 400, "not_found" => 404 }.fetch(code, 500)
  end

  def json(response, status, payload)
    response.status = status
    response["Content-Type"] = "application/json; charset=utf-8"
    response.body = JSON.generate(payload)
  end

  def serve_client(path, response)
    relative = path == "/" ? "index.html" : path.sub(%r{\A/}, "")
    relative = "index.html" unless relative.match?(%r{\A(?:app\.css|app\.js|index\.html)\z})
    file = File.expand_path(relative, @client_root)
    unless file.start_with?(File.expand_path(@client_root) + File::SEPARATOR) && File.file?(file)
      response.status = 404
      response.body = "Not found"
      return
    end
    response.status = 200
    response["Content-Type"] = { ".html" => "text/html; charset=utf-8", ".css" => "text/css; charset=utf-8", ".js" => "text/javascript; charset=utf-8" }.fetch(File.extname(file), "application/octet-stream")
    response["Cache-Control"] = "no-store"
    response.body = File.binread(file)
  end

  def set_common_headers(response)
    response["Content-Security-Policy"] = "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"
    response["X-Content-Type-Options"] = "nosniff"
    response["Referrer-Policy"] = "no-referrer"
    response["Cache-Control"] = "no-store"
  end
end

if $PROGRAM_NAME == __FILE__
  port = (ENV["PTE_REVIEWER_PORT"] || "43100").to_i
  ReviewerServer.new(port: port).start
end
