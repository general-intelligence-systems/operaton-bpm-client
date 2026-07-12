# frozen_string_literal: true

require_relative "permanent_url_resolver"
require_relative "request_executor"
require_relative "../task/impl/external_task_impl"
require_relative "../task/impl/dto/bpmn_error_request_dto"
require_relative "../task/impl/dto/complete_request_dto"
require_relative "../task/impl/dto/extend_lock_request_dto"
require_relative "../task/impl/dto/failure_request_dto"
require_relative "../task/impl/dto/lock_request_dto"
require_relative "../task/impl/dto/set_variables_request_dto"
require_relative "../task/ordering_config"
require_relative "../topic/impl/dto/fetch_and_lock_request_dto"

module Operaton
  module Bpm
    module Client
      module Impl
        # Mirrors org.operaton.bpm.client.impl.EngineClient
        class EngineClient
          EXTERNAL_TASK_RESOURCE_PATH = "/external-task"
          EXTERNAL_TASK_PROCESS_RESOURCE_PATH = "/process-instance"
          FETCH_AND_LOCK_RESOURCE_PATH = "#{EXTERNAL_TASK_RESOURCE_PATH}/fetchAndLock"
          ID_PATH_PARAM = "{id}"
          ID_RESOURCE_PATH = "#{EXTERNAL_TASK_RESOURCE_PATH}/#{ID_PATH_PARAM}"
          LOCK_RESOURCE_PATH = "#{ID_RESOURCE_PATH}/lock"
          EXTEND_LOCK_RESOURCE_PATH = "#{ID_RESOURCE_PATH}/extendLock"
          SET_VARIABLES_RESOURCE_PATH = "#{EXTERNAL_TASK_PROCESS_RESOURCE_PATH}/#{ID_PATH_PARAM}/variables"
          UNLOCK_RESOURCE_PATH = "#{ID_RESOURCE_PATH}/unlock"
          COMPLETE_RESOURCE_PATH = "#{ID_RESOURCE_PATH}/complete"
          FAILURE_RESOURCE_PATH = "#{ID_RESOURCE_PATH}/failure"
          BPMN_ERROR_RESOURCE_PATH = "#{ID_RESOURCE_PATH}/bpmnError"
          NAME_PATH_PARAM = "{name}"
          PROCESS_INSTANCE_RESOURCE_PATH = "/process-instance"
          PROCESS_INSTANCE_ID_RESOURCE_PATH = "#{PROCESS_INSTANCE_RESOURCE_PATH}/#{ID_PATH_PARAM}"
          GET_BINARY_VARIABLE = "#{PROCESS_INSTANCE_ID_RESOURCE_PATH}/variables/#{NAME_PATH_PARAM}/data"

          attr_reader :worker_id, :max_tasks, :async_response_timeout, :ordering_config
          attr_accessor :typed_values

          def initialize(worker_id, max_tasks, async_response_timeout, url_resolver, engine_interaction,
                         use_priority = true, ordering_config = Task::OrderingConfig.empty)
            @worker_id = worker_id
            @max_tasks = max_tasks
            @async_response_timeout = async_response_timeout
            @url_resolver = url_resolver.respond_to?(:base_url) ? url_resolver : PermanentUrlResolver.new(url_resolver)
            @engine_interaction = engine_interaction
            @use_priority = use_priority
            @ordering_config = ordering_config
          end

          def fetch_and_lock(topics)
            payload = Topic::Impl::Dto::FetchAndLockRequestDto.new(
              worker_id, max_tasks, async_response_timeout, topics, @use_priority, ordering_config
            )
            resource_url = base_url + FETCH_AND_LOCK_RESOURCE_PATH
            @engine_interaction.post_request(resource_url, payload, [Task::Impl::ExternalTaskImpl])
          end

          def lock(task_id, lock_duration)
            payload = Task::Impl::Dto::LockRequestDto.new(worker_id, lock_duration)
            post_task_request(LOCK_RESOURCE_PATH, task_id, payload)
          end

          def unlock(task_id)
            post_task_request(UNLOCK_RESOURCE_PATH, task_id, nil)
          end

          def complete(task_id, variables, local_variables)
            payload = Task::Impl::Dto::CompleteRequestDto.new(
              worker_id,
              typed_values.serialize_variables(variables),
              typed_values.serialize_variables(local_variables)
            )
            post_task_request(COMPLETE_RESOURCE_PATH, task_id, payload)
          end

          def set_variables(process_id, variables)
            payload = Task::Impl::Dto::SetVariablesRequestDto.new(
              worker_id, typed_values.serialize_variables(variables)
            )
            resource_url = base_url + SET_VARIABLES_RESOURCE_PATH.sub(ID_PATH_PARAM, process_id)
            @engine_interaction.post_request(resource_url, payload, RequestExecutor::VOID)
          end

          def failure(task_id, error_message, error_details, retries, retry_timeout, variables, local_variables)
            payload = Task::Impl::Dto::FailureRequestDto.new(
              worker_id, error_message, error_details, retries, retry_timeout,
              typed_values.serialize_variables(variables),
              typed_values.serialize_variables(local_variables)
            )
            post_task_request(FAILURE_RESOURCE_PATH, task_id, payload)
          end

          def bpmn_error(task_id, error_code, error_message, variables)
            payload = Task::Impl::Dto::BpmnErrorRequestDto.new(
              worker_id, error_code, error_message, typed_values.serialize_variables(variables)
            )
            post_task_request(BPMN_ERROR_RESOURCE_PATH, task_id, payload)
          end

          def extend_lock(task_id, new_duration)
            payload = Task::Impl::Dto::ExtendLockRequestDto.new(worker_id, new_duration)
            post_task_request(EXTEND_LOCK_RESOURCE_PATH, task_id, payload)
          end

          def get_local_binary_variable(variable_name, execution_id)
            resource_url = base_url + GET_BINARY_VARIABLE
                           .sub(ID_PATH_PARAM, execution_id)
                           .sub(NAME_PATH_PARAM, variable_name)
            @engine_interaction.get_request(resource_url)
          end

          def base_url
            @url_resolver.base_url
          end

          def use_priority?
            @use_priority
          end

          private

          def post_task_request(resource_path, task_id, payload)
            resource_url = base_url + resource_path.sub(ID_PATH_PARAM, task_id)
            @engine_interaction.post_request(resource_url, payload, RequestExecutor::VOID)
          end
        end
      end
    end
  end
end

__END__

require "operaton-bpm-client"

# Silence client logging during tests (mirrors spec_helper)
Operaton::Bpm::Client.logger = Logger.new(File::NULL)

describe Operaton::Bpm::Client::Impl::EngineClient do
  before do
    # Records post_request/get_request invocations instead of hitting HTTP.
    @recording_executor = Class.new do
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

    @engine_client =
      Operaton::Bpm::Client::Impl::EngineClient.new(
        "worker-1", 10, nil, "http://engine/engine-rest", @recording_executor
      ).tap do |ec|
        # Wire up typed values exactly like the builder does
        built = Operaton::Bpm::Client::ExternalTaskClient.create
                                                         .base_url("http://engine/engine-rest")
                                                         .disable_auto_fetching
                                                         .build
        ec.typed_values = built.topic_subscription_manager.engine_client.typed_values
      end
  end

  it "posts fetchAndLock with worker id, maxTasks, priority and topics" do
    topic = Operaton::Bpm::Client::Topic::Impl::Dto::TopicRequestDto.new("my-topic", 20_000, nil, nil)
    @engine_client.fetch_and_lock([topic])

    @recording_executor.calls.first => [method, url, payload, *]
    method.should == :post
    url.should == "http://engine/engine-rest/external-task/fetchAndLock"
    payload.slice("workerId", "maxTasks", "usePriority", "sorting").should == {
      "workerId" => "worker-1", "maxTasks" => 10, "usePriority" => true, "sorting" => []
    }
    payload.should.not.include("asyncResponseTimeout")
    payload["topics"].first.slice(
      "topicName", "lockDuration", "localVariables", "withoutTenantId", "includeExtensionProperties"
    ).should == {
      "topicName" => "my-topic", "lockDuration" => 20_000, "localVariables" => false,
      "withoutTenantId" => false, "includeExtensionProperties" => false
    }
  end

  it "posts complete with serialized variables" do
    @engine_client.complete("task-1", { "answer" => 42 }, { "local" => "yes" })

    @recording_executor.calls.first => [_, url, payload, *]
    url.should == "http://engine/engine-rest/external-task/task-1/complete"
    payload["workerId"].should == "worker-1"
    payload["variables"].should == { "answer" => { "value" => 42, "type" => "Integer", "valueInfo" => {} } }
    payload["localVariables"].should == { "local" => { "value" => "yes", "type" => "String", "valueInfo" => {} } }
  end

  it "posts failure with retry configuration" do
    @engine_client.failure("task-1", "msg", "details", 3, 1000, nil, nil)

    @recording_executor.calls.first => [_, url, payload, *]
    url.should == "http://engine/engine-rest/external-task/task-1/failure"
    payload.slice("errorMessage", "errorDetails", "retries", "retryTimeout").should == {
      "errorMessage" => "msg", "errorDetails" => "details", "retries" => 3, "retryTimeout" => 1000
    }
  end

  it "posts bpmnError with error code and message" do
    @engine_client.bpmn_error("task-1", "code-1", "oops", { "v" => true })

    @recording_executor.calls.first => [_, url, payload, *]
    url.should == "http://engine/engine-rest/external-task/task-1/bpmnError"
    payload.slice("errorCode", "errorMessage").should == { "errorCode" => "code-1", "errorMessage" => "oops" }
    payload["variables"]["v"].slice("type", "value").should == { "type" => "Boolean", "value" => true }
  end

  it "posts extendLock with the new duration" do
    @engine_client.extend_lock("task-1", 5000)
    @recording_executor.calls.first => [_, url, payload, *]
    url.should == "http://engine/engine-rest/external-task/task-1/extendLock"
    payload["newDuration"].should == 5000
  end

  it "posts lock with the lock duration" do
    @engine_client.lock("task-1", 5000)
    @recording_executor.calls.first => [_, url, payload, *]
    url.should == "http://engine/engine-rest/external-task/task-1/lock"
    payload["lockDuration"].should == 5000
  end

  it "posts unlock without a body" do
    @engine_client.unlock("task-1")
    @recording_executor.calls.first => [_, url, payload, *]
    url.should == "http://engine/engine-rest/external-task/task-1/unlock"
    payload.should.be.nil
  end

  it "posts setVariables as modifications on the process instance" do
    @engine_client.set_variables("process-1", { "v" => 1 })
    @recording_executor.calls.first => [_, url, payload, *]
    url.should == "http://engine/engine-rest/process-instance/process-1/variables"
    payload["modifications"]["v"].slice("value", "type").should == { "value" => 1, "type" => "Integer" }
  end

  it "fetches binary variables via GET" do
    @engine_client.get_local_binary_variable("file-var", "execution-1").should == "bytes"
    @recording_executor.calls.first => [method, url, *]
    method.should == :get
    url.should == "http://engine/engine-rest/process-instance/execution-1/variables/file-var/data"
  end
end
