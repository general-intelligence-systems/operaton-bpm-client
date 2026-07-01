# frozen_string_literal: true

require "spec_helper"

RSpec.describe Operaton::Bpm::Client::Impl::RequestExecutor do
  let(:client_module) { Operaton::Bpm::Client }
  let(:object_mapper) { client_module::Impl::ObjectMapper.new }
  let(:server) { StubEngineServer.new }

  after { server.stop }

  def executor(interceptors: [])
    handler = client_module::Interceptor::Impl::RequestInterceptorHandler.new(interceptors)
    described_class.new(object_mapper, interceptor_handler: handler)
  end

  def simple_dto
    client_module::Task::Impl::Dto::LockRequestDto.new("worker-1", 1000)
  end

  it "sends JSON with the Operaton user agent" do
    server.enqueue_response(status: 204)
    executor.post_request("#{server.base_url}/external-task/t1/lock", simple_dto,
                          described_class::VOID)

    request = server.last_request
    expect(request.method).to eq("POST")
    expect(request.path).to eq("/external-task/t1/lock")
    expect(request.headers["user-agent"]).to eq("Operaton External Task Client")
    expect(request.headers["content-type"]).to eq("application/json")
    expect(JSON.parse(request.body)).to eq("workerId" => "worker-1", "lockDuration" => 1000)
  end

  it "deserializes array responses into DTO lists" do
    server.enqueue_response(status: 200, body: [{ "id" => "task-1", "topicName" => "topic-a" }])
    tasks = executor.post_request("#{server.base_url}/external-task/fetchAndLock", simple_dto,
                                  [client_module::Task::Impl::ExternalTaskImpl])
    expect(tasks.size).to eq(1)
    expect(tasks.first.id).to eq("task-1")
    expect(tasks.first.topic_name).to eq("topic-a")
  end

  it "wraps HTTP error responses in EngineClientException with a RestException cause" do
    server.enqueue_response(status: 404, body: { "type" => "RestException",
                                                 "message" => "task not found", "code" => 0 })
    expect do
      executor.post_request("#{server.base_url}/external-task/missing/complete", simple_dto,
                            described_class::VOID)
    end.to raise_error(client_module::Impl::EngineClientException) { |e|
      expect(e.cause).to be_a(client_module::RestException)
      expect(e.cause.http_status_code).to eq(404)
      expect(e.cause.message).to eq("task not found")
    }
  end

  it "wraps connection failures in EngineClientException with an IO cause" do
    closed_port_url = "http://127.0.0.1:1/external-task/fetchAndLock"
    expect do
      executor.post_request(closed_port_url, simple_dto, described_class::VOID)
    end.to raise_error(client_module::Impl::EngineClientException) { |e|
      expect(e.cause).to be_a(SystemCallError)
    }
  end

  it "applies request interceptors such as BasicAuthProvider" do
    server.enqueue_response(status: 204)
    auth = client_module::Interceptor::Auth::BasicAuthProvider.new("demo", "demo")
    executor(interceptors: [auth]).post_request("#{server.base_url}/external-task/t1/lock",
                                                simple_dto, described_class::VOID)

    request = server.last_request
    expect(request.headers["authorization"]).to eq("Basic #{Base64.strict_encode64('demo:demo')}")
  end

  it "supports callable interceptors" do
    server.enqueue_response(status: 204)
    interceptor = ->(context) { context.add_header("X-Custom", "yes") }
    executor(interceptors: [interceptor]).post_request("#{server.base_url}/external-task/t1/lock",
                                                       simple_dto, described_class::VOID)
    expect(server.last_request.headers["x-custom"]).to eq("yes")
  end

  it "returns raw bytes for GET requests" do
    server.enqueue_response(status: 200, body: "binary-data", content_type: "application/octet-stream")
    body = executor.get_request("#{server.base_url}/process-instance/e1/variables/f/data")
    expect(body).to eq("binary-data")
  end
end
