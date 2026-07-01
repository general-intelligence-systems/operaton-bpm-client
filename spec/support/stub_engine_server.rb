# frozen_string_literal: true

require "socket"
require "json"

# Minimal in-process HTTP server used to test the RequestExecutor without
# external dependencies. Responses are queued; requests are recorded.
class StubEngineServer
  Request = Struct.new(:method, :path, :headers, :body, keyword_init: true)

  attr_reader :requests, :port

  def initialize
    @server = TCPServer.new("127.0.0.1", 0)
    @port = @server.addr[1]
    @requests = Queue.new
    @responses = Queue.new
    @thread = Thread.new { serve }
  end

  def base_url
    "http://127.0.0.1:#{port}"
  end

  def enqueue_response(status: 200, body: nil, content_type: "application/json")
    @responses << { status: status, body: body, content_type: content_type }
  end

  def last_request
    @requests.pop(true)
  rescue ThreadError
    nil
  end

  def stop
    @thread.kill
    @server.close
  end

  private

  def serve
    loop do
      client = @server.accept
      handle(client)
    rescue IOError, Errno::EBADF
      break
    end
  end

  def handle(client)
    request_line = client.gets
    return client.close if request_line.nil?

    method, path, = request_line.split
    headers = {}
    while (line = client.gets) && line != "\r\n"
      name, value = line.split(": ", 2)
      headers[name.downcase] = value&.strip
    end
    content_length = headers["content-length"].to_i
    body = content_length.positive? ? client.read(content_length) : nil

    @requests << Request.new(method: method, path: path, headers: headers, body: body)

    response = @responses.empty? ? { status: 204, body: nil } : @responses.pop
    payload = response[:body]
    payload = JSON.generate(payload) if payload && !payload.is_a?(String)

    status_text = { 200 => "OK", 204 => "No Content", 400 => "Bad Request",
                    404 => "Not Found", 500 => "Internal Server Error" }[response[:status]] || "Status"
    client.write("HTTP/1.1 #{response[:status]} #{status_text}\r\n")
    client.write("Content-Type: #{response[:content_type] || 'application/json'}\r\n")
    client.write("Content-Length: #{payload ? payload.bytesize : 0}\r\n")
    client.write("Connection: close\r\n\r\n")
    client.write(payload) if payload
    client.close
  end
end
