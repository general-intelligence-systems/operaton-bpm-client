# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Topic
        # Mirrors org.operaton.bpm.client.topic.TopicSubscription. Documents
        # the contract implemented by Topic::Impl::TopicSubscriptionImpl.
        module TopicSubscription
          INTERFACE_METHODS = %i[
            close topic_name lock_duration external_task_handler variable_names
            local_variables? business_key process_definition_id process_definition_id_in
            process_definition_key process_definition_key_in process_definition_version_tag
            process_variables without_tenant_id? tenant_id_in include_extension_properties?
          ].freeze
        end
      end
    end
  end
end

__END__

require "operaton-bpm-client"
require "timeout"

# Silence client logging during tests (mirrors spec_helper)
Operaton::Bpm::Client.logger = Logger.new(File::NULL)

describe "topic subscriptions" do
  before do
    @client = Operaton::Bpm::Client::ExternalTaskClient.create
                                                       .base_url("http://localhost:8080/engine-rest")
                                                       .disable_auto_fetching
                                                       .build
    @manager = @client.topic_subscription_manager
  end

  after do
    @client.stop
  end

  describe "builder validation" do
    it "requires a handler" do
      err = lambda { @client.subscribe("topic-a").open }
            .should.raise(Operaton::Bpm::Client::ExternalTaskClientException)
      err.message.should.match(/handler cannot be null/)
    end

    it "requires a topic name" do
      err = lambda { @client.subscribe(nil).handler { |_t, _s| }.open }
            .should.raise(Operaton::Bpm::Client::ExternalTaskClientException)
      err.message.should.match(/Topic name cannot be null/)
    end

    it "rejects non-positive lock durations" do
      err = lambda { @client.subscribe("topic-a").lock_duration(0).handler { |_t, _s| }.open }
            .should.raise(Operaton::Bpm::Client::ExternalTaskClientException)
      err.message.should.match(/Lock duration/)
    end

    it "rejects duplicate topic subscriptions" do
      @client.subscribe("topic-a").handler { |_t, _s| }.open
      err = lambda { @client.subscribe("topic-a").handler { |_t, _s| }.open }
            .should.raise(Operaton::Bpm::Client::ExternalTaskClientException)
      err.message.should.match(/already been subscribed/)
    end

    it "allows re-subscribing after close" do
      subscription = @client.subscribe("topic-a").handler { |_t, _s| }.open
      subscription.close
      lambda { @client.subscribe("topic-a").handler { |_t, _s| }.open }
        .should.not.raise(Operaton::Bpm::Client::ExternalTaskClientException)
    end
  end

  describe "subscription configuration" do
    it "carries all filters into the TopicRequestDto" do
      subscription = @client.subscribe("topic-a")
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

      dto = Operaton::Bpm::Client::Topic::Impl::Dto::TopicRequestDto.from_topic_subscription(subscription, 20_000)
      dto.as_json.should == {
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
      }
    end

    it "falls back to the client lock duration" do
      subscription = @client.subscribe("topic-a").handler { |_t, _s| }.open
      dto = Operaton::Bpm::Client::Topic::Impl::Dto::TopicRequestDto.from_topic_subscription(subscription, 20_000)
      dto.lock_duration.should == 20_000
    end
  end

  describe "task dispatching" do
    before do
      @task_payload = {
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
      engine_client = @manager.engine_client
      task = Operaton::Bpm::Client::Task::Impl::ExternalTaskImpl.from_json(
        @task_payload, Operaton::Bpm::Client::Impl::ObjectMapper.new
      )
      calls = Queue.new
      complete_calls = []
      # Partial-stub the real engine client (stands in for allow(...).to receive).
      engine_client.define_singleton_method(:fetch_and_lock) { |*_a, **_k| [task] }
      engine_client.define_singleton_method(:complete) { |*args, **_k| complete_calls << args; nil }

      @client.subscribe("topic-a").handler do |external_task, service|
        service.complete(external_task, { "done" => true })
        calls << external_task
      end.open

      @client.start
      handled = Timeout.timeout(5) { calls.pop }
      @client.stop

      handled.id.should == "task-1"
      handled.variable("greeting").should == "hello"
      handled.all_variables.should == { "greeting" => "hello" }
      # have_received(:complete).with("task-1", { "done" => true }, nil).at_least(:once)
      complete_calls.should.include(["task-1", { "done" => true }, nil])
    end

    it "keeps polling when the handler raises" do
      engine_client = @manager.engine_client
      payload = @task_payload # capture: self is the engine_client inside the singleton method
      attempts = Queue.new
      engine_client.define_singleton_method(:fetch_and_lock) do |*_a, **_k|
        [Operaton::Bpm::Client::Task::Impl::ExternalTaskImpl.from_json(
          payload, Operaton::Bpm::Client::Impl::ObjectMapper.new
        )]
      end

      @client.subscribe("topic-a").handler do |_task, _service|
        attempts << :attempt
        raise "handler blew up"
      end.open

      @client.start
      Timeout.timeout(5) do
        attempts.pop
        attempts.pop # a second invocation proves the loop survived the error
      end
      @client.stop
      @client.active?.should == false
    end

    it "backs off after fetch errors without dying" do
      engine_client = @manager.engine_client
      fetches = Queue.new
      engine_client.define_singleton_method(:fetch_and_lock) do |*_a, **_k|
        fetches << :fetch
        raise Operaton::Bpm::Client::Impl::EngineClientException.new("down", Errno::ECONNREFUSED.new)
      end

      @client.subscribe("topic-a").handler { |_t, _s| }.open
      @client.start
      Timeout.timeout(5) do
        fetches.pop
        fetches.pop
      end
      @client.stop
      @client.active?.should == false
    end
  end
end
