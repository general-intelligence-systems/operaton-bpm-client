# frozen_string_literal: true

require "spec_helper"

RSpec.describe "topic subscriptions" do
  let(:client_module) { Operaton::Bpm::Client }

  let(:client) do
    client_module::ExternalTaskClient.create
                                     .base_url("http://localhost:8080/engine-rest")
                                     .disable_auto_fetching
                                     .build
  end
  let(:manager) { client.topic_subscription_manager }

  after { client.stop }

  describe "builder validation" do
    it "requires a handler" do
      expect { client.subscribe("topic-a").open }
        .to raise_error(client_module::ExternalTaskClientException, /handler cannot be null/)
    end

    it "requires a topic name" do
      expect { client.subscribe(nil).handler { |_t, _s| }.open }
        .to raise_error(client_module::ExternalTaskClientException, /Topic name cannot be null/)
    end

    it "rejects non-positive lock durations" do
      expect { client.subscribe("topic-a").lock_duration(0).handler { |_t, _s| }.open }
        .to raise_error(client_module::ExternalTaskClientException, /Lock duration/)
    end

    it "rejects duplicate topic subscriptions" do
      client.subscribe("topic-a").handler { |_t, _s| }.open
      expect { client.subscribe("topic-a").handler { |_t, _s| }.open }
        .to raise_error(client_module::ExternalTaskClientException, /already been subscribed/)
    end

    it "allows re-subscribing after close" do
      subscription = client.subscribe("topic-a").handler { |_t, _s| }.open
      subscription.close
      expect { client.subscribe("topic-a").handler { |_t, _s| }.open }.not_to raise_error
    end
  end

  describe "subscription configuration" do
    it "carries all filters into the TopicRequestDto" do
      subscription = client.subscribe("topic-a")
                           .lock_duration(11_000)
                           .variables("a", "b")
                           .local_variables(true)
                           .business_key("bk")
                           .process_definition_id("pd-1")
                           .process_definition_key_in("k1", "k2")
                           .process_definition_version_tag("v1")
                           .process_variable_equals("state", "open")
                           .tenant_id_in("tenant-1")
                           .include_extension_properties(true)
                           .handler { |_task, _service| }
                           .open

      dto = client_module::Topic::Impl::Dto::TopicRequestDto.from_topic_subscription(subscription, 20_000)
      expect(dto.as_json).to eq(
        "topicName" => "topic-a",
        "lockDuration" => 11_000,
        "variables" => %w[a b],
        "localVariables" => true,
        "businessKey" => "bk",
        "processDefinitionId" => "pd-1",
        "processDefinitionIdIn" => nil,
        "processDefinitionKey" => nil,
        "processDefinitionKeyIn" => %w[k1 k2],
        "processDefinitionVersionTag" => "v1",
        "processVariables" => { "state" => "open" },
        "withoutTenantId" => false,
        "tenantIdIn" => ["tenant-1"],
        "includeExtensionProperties" => true
      )
    end

    it "falls back to the client lock duration" do
      subscription = client.subscribe("topic-a").handler { |_t, _s| }.open
      dto = client_module::Topic::Impl::Dto::TopicRequestDto.from_topic_subscription(subscription, 20_000)
      expect(dto.lock_duration).to eq(20_000)
    end
  end

  describe "task dispatching" do
    let(:task_payload) do
      {
        "id" => "task-1",
        "topicName" => "topic-a",
        "workerId" => "worker-1",
        "executionId" => "execution-1",
        "processInstanceId" => "process-1",
        "priority" => 5,
        "variables" => {
          "greeting" => { "value" => "hello", "type" => "String", "valueInfo" => {} }
        }
      }
    end

    it "invokes the handler with the fetched task and the task service" do
      engine_client = manager.engine_client
      task = client_module::Task::Impl::ExternalTaskImpl.from_json(
        task_payload, client_module::Impl::ObjectMapper.new
      )
      calls = Queue.new
      allow(engine_client).to receive(:fetch_and_lock) { [task] }
      allow(engine_client).to receive(:complete)

      client.subscribe("topic-a").handler do |external_task, service|
        service.complete(external_task, { "done" => true })
        calls << external_task
      end.open

      client.start
      handled = Timeout.timeout(5) { calls.pop }
      client.stop

      expect(handled.id).to eq("task-1")
      expect(handled.variable("greeting")).to eq("hello")
      expect(handled.all_variables).to eq("greeting" => "hello")
      expect(engine_client).to have_received(:complete).with("task-1", { "done" => true }, nil).at_least(:once)
    end

    it "keeps polling when the handler raises" do
      engine_client = manager.engine_client
      attempts = Queue.new
      allow(engine_client).to receive(:fetch_and_lock) do
        task = client_module::Task::Impl::ExternalTaskImpl.from_json(
          task_payload, client_module::Impl::ObjectMapper.new
        )
        [task]
      end

      client.subscribe("topic-a").handler do |_task, _service|
        attempts << :attempt
        raise "handler blew up"
      end.open

      client.start
      Timeout.timeout(5) do
        attempts.pop
        attempts.pop # a second invocation proves the loop survived the error
      end
      client.stop
      expect(client.active?).to be(false)
    end

    it "backs off after fetch errors without dying" do
      engine_client = manager.engine_client
      fetches = Queue.new
      allow(engine_client).to receive(:fetch_and_lock) do
        fetches << :fetch
        raise client_module::Impl::EngineClientException.new("down", Errno::ECONNREFUSED.new)
      end

      client.subscribe("topic-a").handler { |_t, _s| }.open
      client.start
      Timeout.timeout(5) do
        fetches.pop
        fetches.pop
      end
      client.stop
      expect(client.active?).to be(false)
    end
  end
end
