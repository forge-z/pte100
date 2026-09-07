# frozen_string_literal: true

require "json"
require "minitest/autorun"
require_relative "../server/reviewer_server"

class ReviewerServerTest < Minitest::Test
  Request = Struct.new(:path, :request_method, :header, :host, :port)

  class Response
    attr_accessor :status, :body

    def initialize
      @headers = {}
    end

    def []=(key, value)
      @headers[key] = value
    end
  end

  def setup
    @server = ReviewerServer.new(port: 43100, service: ReviewerService.new(session_token: "test-token"))
  end

  def test_capabilities_rejects_untrusted_host
    response = dispatch("/api/v1/capabilities", "GET", host: "evil.example")

    assert_equal 403, response.status
    assert_equal "forbidden", JSON.parse(response.body).dig("error", "code")
  end

  def test_protected_route_rejects_external_origin
    response = dispatch("/api/v1/rules/R004", "GET", origin: "http://evil.example:43100", token: "test-token")

    assert_equal 403, response.status
    assert_equal "forbidden", JSON.parse(response.body).dig("error", "code")
  end

  def test_capabilities_accepts_the_bound_loopback_origin
    response = dispatch("/api/v1/capabilities", "GET", origin: "http://127.0.0.1:43100")

    assert_equal 200, response.status
    assert_equal "pte-100-reviewer", JSON.parse(response.body).fetch("service")
  end

  def test_second_review_is_rejected_while_one_is_active
    @server.instance_variable_get(:@review_lock).lock
    response = dispatch("/api/v1/reviews", "POST", token: "test-token", body: "{}")

    assert_equal 429, response.status
    assert_equal "busy", JSON.parse(response.body).dig("error", "code")
  ensure
    lock = @server.instance_variable_get(:@review_lock)
    lock.unlock if lock.owned?
  end

  private

  def dispatch(path, method, host: "127.0.0.1", origin: nil, token: nil, body: nil)
    headers = {}
    headers["origin"] = [origin] if origin
    headers["x-pte-session"] = [token] if token
    headers["content-length"] = [body.bytesize.to_s] if body
    request = Request.new(path, method, headers, host, 43100)
    request.define_singleton_method(:body) { body }
    response = Response.new
    @server.send(:handle, request, response)
    response
  end
end
