# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "timeout"
require "net/http"
require "json"
require "base64"
require_relative "support/pdf_fixture"

# Real HTTP service in a clean project copy; dependency acquisition is separate.
class ReviewerE2eTest < Minitest::Test
  include ReviewerPdfFixture
  ROOT = File.expand_path("../..", __dir__)
  NETWORK_GUARD = <<~'GUARD'
    require "socket"
    $stdout.sync = true
    module LocalSockets
      def new(host, *args, **kwargs)
        raise "External socket blocked: #{host}" unless %w[127.0.0.1 localhost ::1].include?(host.to_s)
        super
      end
    end
    TCPSocket.singleton_class.prepend(LocalSockets)
    module LocalConnect
      def connect(address)
        _, host = Socket.unpack_sockaddr_in(address)
        raise "External socket blocked: #{host}" unless %w[127.0.0.1 ::1].include?(host)
        super
      end
    end
    Socket.prepend(LocalConnect)
  GUARD

  def test_clean_copy_runs_without_external_socket_connections
    Dir.mktmpdir("pte reviewer clean ") do |clean|
      %w[bin lib rules vocabulary reviewer-webapp].each { |path| FileUtils.cp_r(File.join(ROOT, path), clean) }
      app = File.join(clean, "reviewer-webapp")
      guard = File.join(clean, "network_guard.rb")
      File.write(guard, NETWORK_GUARD)
      env = {"BUNDLE_GEMFILE" => File.join(app, "Gemfile"), "BUNDLE_FROZEN" => "true", "PTE_REVIEWER_PORT" => "0", "RUBYOPT" => "-r#{guard}"}
      # RUBYOPT cannot represent paths containing spaces. Keep the guard in cwd.
      env["RUBYOPT"] = "-r./network_guard.rb"
      with_server(env: env, command: ["bundle", "exec", RbConfig.ruby, File.join(app, "bin/reviewer-webapp")], chdir: clean) do |port, process|
        http = Net::HTTP.new("127.0.0.1", port, nil)
        http.open_timeout = http.read_timeout = 10
        response = http.get("/api/v1/capabilities")
        assert_equal "200", response.code
        capability = JSON.parse(response.body)
        assert_equal %w[markdown text pdf], capability.fetch("formats")
        assert_equal ["pt-BR"], capability.fetch("locales")
        assert_equal false, capability.dig("converters", "pdf", "ocr")
        assert_match "connect-src 'self'", response["content-security-policy"]
        assert_equal "no-store", response["cache-control"]
        %w[/ /app.js /app.css].each { |path| assert_equal "200", http.get(path).code }
        content = "1. Desligue a bomba se a pressão for superior a 20 kPa.\nO operador deverá efetuar a verificação do nível.\n"
        %w[markdown text].each do |format|
          result = review(http, capability, {"name" => "caso com espaços.#{format == 'markdown' ? 'md' : 'txt'}", "format" => format, "content" => content})
          assert_equal "200", result.code
          payload = JSON.parse(result.body)
          assert_includes payload.fetch("diagnostics").map { |d| d.fetch("rule") }, "R014"
          assert_includes payload.fetch("diagnostics").map { |d| d.fetch("rule") }, "R038"
          assert_equal 1, payload.dig("summary", "files")
        end
        pdf = review(http, capability, {"name" => "texto.pdf", "format" => "pdf", "data_base64" => Base64.strict_encode64(build_pdf("Pressao de 20 kPa."))})
        assert_equal "200", pdf.code
        assert_includes JSON.parse(pdf.body).fetch("diagnostics").map { |d| d.fetch("rule") }, "R038"
        scanned = review(http, capability, {"name" => "sem-texto.pdf", "format" => "pdf", "data_base64" => Base64.strict_encode64(build_pdf(nil))})
        assert_equal "422", scanned.code
        assert_equal "pdf_without_text", JSON.parse(scanned.body).dig("error", "code")
        literal = review(http, capability, {"name" => "literal.md", "format" => "markdown", "content" => "~~~text\n1. O operador deverá usar XYZ.\nIMPORTANTE: Faça isso se necessário.\n~~~\n"})
        assert_empty JSON.parse(literal.body).fetch("diagnostics")
        forbidden = Net::HTTP::Post.new("/api/v1/reviews", {"Content-Type" => "application/json", "Origin" => "https://evil.example", "X-PTE-Session" => capability.fetch("session_token")})
        forbidden.body = "{}"
        assert_equal "403", http.request(forbidden).code
        assert process.alive?, "Service exited during review"
      end
    end
  end


  def test_offline_guard_rejects_outbound_tcp_attempts
    Dir.mktmpdir("pte-guard-") do |directory|
      File.write(File.join(directory, "network_guard.rb"), NETWORK_GUARD)
      code = <<~'PROBE'
        require "socket"
        sockets = []
        attempts = [
          -> { TCPSocket.new("192.0.2.1", 80) },
          -> {
            socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
            sockets << socket
            socket.connect(Socket.sockaddr_in(80, "192.0.2.1"))
          }
        ]
        attempts.each do |attempt|
          begin
            attempt.call
            abort "External connection was not rejected"
          rescue RuntimeError => error
            raise unless error.message.start_with?("External socket blocked:")
          end
        end
        sockets.each(&:close)
        puts "PTE guarded paths: http://127.0.0.1:1/"
        sleep 60
      PROBE
      with_server(env: {"RUBYOPT" => "-r./network_guard.rb"}, command: [RbConfig.ruby, "-e", code], chdir: directory) do |port, process|
        assert_equal 1, port
        assert process.alive?, "Both outbound paths must be rejected before readiness"
      end
    end
  end

  def test_startup_eof_reports_error_without_waiting_for_open_stderr
    Dir.mktmpdir("pte-startup-") do |directory|
      code = '$stdout.reopen(File::NULL, "w"); warn "startup stopped"; sleep 60'
      error = assert_raises(RuntimeError) do
        Timeout.timeout(2) do
          with_server(env: {}, command: [RbConfig.ruby, "-e", code], chdir: directory, startup_timeout: 0.5, shutdown_timeout: 0.2) { flunk "No ready banner" }
        end
      end
      assert_match(/Server failed to start.*startup stopped/m, error.message)
    end
  end

  def test_cleanup_kills_unresponsive_child_and_preserves_original_failure
    skip "Signals unavailable on Windows" if Gem.win_platform?
    Dir.mktmpdir("pte-cleanup-") do |directory|
      code = '$stdout.sync=true; trap("TERM") {}; puts "PTE-100 Reviewer local: http://127.0.0.1:1/"; sleep 60'
      original = RuntimeError.new("original review failure")
      child = nil
      error = assert_raises(RuntimeError) do
        with_server(env: {}, command: [RbConfig.ruby, "-e", code], chdir: directory, startup_timeout: 0.5, shutdown_timeout: 0.2) do |_, process|
          child = process
          raise original
        end
      end
      assert_same original, error
      refute child.alive?, "Child must be reaped even when TERM is ignored"
    ensure
      if child&.alive?
        Process.kill("KILL", child.pid)
        Timeout.timeout(1) { child.value }
      end
    end
  end

  private

  # Files avoid deadlocks from full pipes or stderr held open by descendants.
  # Only this test's process group receives signals; the caller's error survives cleanup.
  def with_server(env:, command:, chdir:, startup_timeout: 15, shutdown_timeout: 2)
    Dir.mktmpdir("pte-e2e-logs-", chdir) do |logs|
      stdout_path = File.join(logs, "stdout.log")
      stderr_path = File.join(logs, "stderr.log")
      options = { chdir: chdir, in: File::NULL, out: stdout_path, err: stderr_path }
      options[:pgroup] = true unless Gem.win_platform?
      pid = Process.spawn(env, *command, **options)
      process = Process.detach(pid)
      begin
        deadline = monotonic_time + startup_timeout
        line = File.open(stdout_path, "r") do |output|
          loop do
            ready = output.gets
            break ready if ready
            unless process.alive? && monotonic_time < deadline
              raise "Server failed to start: #{File.read(stderr_path)}"
            end
            sleep 0.02
          end
        end
        match = line.match(/:(\d+)\//)
        raise "Invalid server startup banner: #{line}" unless match
        yield match[1].to_i, process
      ensure
        original_error = $!
        cleanup_error = nil
        begin
          signal_child("TERM", pid, process)
          begin
            Timeout.timeout(shutdown_timeout) { process.value }
          rescue Timeout::Error
            signal_child("KILL", pid, process)
            Timeout.timeout(2) { process.value }
          ensure
            # A descendant may remain after the parent has exited.
            signal_child("KILL", pid, process) unless Gem.win_platform?
          end
        rescue StandardError => error
          cleanup_error = error
        end
        raise cleanup_error if cleanup_error && !original_error
      end
      refute_match(/External socket blocked|server error|internal error/, File.read(stderr_path))
    end
  end

  def signal_child(signal, pid, process)
    return if Gem.win_platform? && !process.alive?
    Process.kill(signal, Gem.win_platform? ? pid : -pid)
  rescue Errno::ESRCH
    # The process/group exited before the signal.
  end

  def monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def review(http, capability, document)
    request = Net::HTTP::Post.new("/api/v1/reviews", {"Content-Type" => "application/json", "X-PTE-Session" => capability.fetch("session_token")})
    request.body = JSON.generate("document" => document, "configuration" => {"level" => "pte-claro", "locale" => "pt-BR"})
    http.request(request)
  end
end
