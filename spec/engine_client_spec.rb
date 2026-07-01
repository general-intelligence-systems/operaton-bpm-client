# frozen_string_literal: true

require "spec_helper"

RSpec.describe Operaton::Bpm::Client::Impl::EngineClient do
  let(:client_module) { Operaton::Bpm::Client }

  # Records post_request/get_request invocations instead of hitting HTTP.
  let(:recording_executor) do
    Class.new do
      attr_reader :calls

      def initialize
        @calls = []
      end

      def post_request(url, payload, response_type)
        @calls << [:post, url, payload&.as_json, response_type]
        []
      end

      def get_request(url)
        @calls << [:get, url]
        "bytes"
      end
    end.new
  end

  let(:engine_client) do
    described_class.new("worker-1", 10, nil, "http://engine/engine-rest", recording_executor).tap do |ec|
      # Wire up typed values exactly like the builder does
      built = client_module::ExternalTaskClient.create
                                               .base_url("http://engine/engine-rest")
                                               .disable_auto_fetching
                                               .build
      ec.typed_values = built.topic_subscription_manager.engine_client.typed_values
    end
  end

  it "posts fetchAndLock with worker id, maxTasks, priority and topics" do
    topic = client_module::Topic::Impl::Dto::TopicRequestDto.new("my-topic", 20_000, nil, nil)
    engine_client.fetch_and_lock([topic])

    method, url, payload, = recording_executor.calls.first
    expect(method).to eq(:post)
    expect(url).to eq("http://engine/engine-rest/external-task/fetchAndLock")
    expect(payload).to include(
      "workerId" => "worker-1",
      "maxTasks" => 10,
      "usePriority" => true,
      "sorting" => []
    )
    expect(payload).not_to have_key("asyncResponseTimeout")
    expect(payload["topics"].first).to include(
      "topicName" => "my-topic",
      "lockDuration" => 20_000,
      "localVariables" => false,
      "withoutTenantId" => false,
      "includeExtensionProperties" => false
    )
  end

  it "posts complete with serialized variables" do
    engine_client.complete("task-1", { "answer" => 42 }, { "local" => "yes" })

    _, url, payload, = recording_executor.calls.first
    expect(url).to eq("http://engine/engine-rest/external-task/task-1/complete")
    expect(payload["workerId"]).to eq("worker-1")
    expect(payload["variables"]).to eq(
      "answer" => { "value" => 42, "type" => "Integer", "valueInfo" => {} }
    )
    expect(payload["localVariables"]).to eq(
      "local" => { "value" => "yes", "type" => "String", "valueInfo" => {} }
    )
  end

  it "posts failure with retry configuration" do
    engine_client.failure("task-1", "msg", "details", 3, 1000, nil, nil)

    _, url, payload, = recording_executor.calls.first
    expect(url).to eq("http://engine/engine-rest/external-task/task-1/failure")
    expect(payload).to include(
      "errorMessage" => "msg", "errorDetails" => "details",
      "retries" => 3, "retryTimeout" => 1000
    )
  end

  it "posts bpmnError with error code and message" do
    engine_client.bpmn_error("task-1", "code-1", "oops", { "v" => true })

    _, url, payload, = recording_executor.calls.first
    expect(url).to eq("http://engine/engine-rest/external-task/task-1/bpmnError")
    expect(payload).to include("errorCode" => "code-1", "errorMessage" => "oops")
    expect(payload["variables"]["v"]).to include("type" => "Boolean", "value" => true)
  end

  it "posts extendLock with the new duration" do
    engine_client.extend_lock("task-1", 5000)
    _, url, payload, = recording_executor.calls.first
    expect(url).to eq("http://engine/engine-rest/external-task/task-1/extendLock")
    expect(payload).to include("newDuration" => 5000)
  end

  it "posts lock with the lock duration" do
    engine_client.lock("task-1", 5000)
    _, url, payload, = recording_executor.calls.first
    expect(url).to eq("http://engine/engine-rest/external-task/task-1/lock")
    expect(payload).to include("lockDuration" => 5000)
  end

  it "posts unlock without a body" do
    engine_client.unlock("task-1")
    _, url, payload, = recording_executor.calls.first
    expect(url).to eq("http://engine/engine-rest/external-task/task-1/unlock")
    expect(payload).to be_nil
  end

  it "posts setVariables as modifications on the process instance" do
    engine_client.set_variables("process-1", { "v" => 1 })
    _, url, payload, = recording_executor.calls.first
    expect(url).to eq("http://engine/engine-rest/process-instance/process-1/variables")
    expect(payload["modifications"]["v"]).to include("value" => 1, "type" => "Integer")
  end

  it "fetches binary variables via GET" do
    expect(engine_client.get_local_binary_variable("file-var", "execution-1")).to eq("bytes")
    method, url = recording_executor.calls.first
    expect(method).to eq(:get)
    expect(url).to eq("http://engine/engine-rest/process-instance/execution-1/variables/file-var/data")
  end
end
