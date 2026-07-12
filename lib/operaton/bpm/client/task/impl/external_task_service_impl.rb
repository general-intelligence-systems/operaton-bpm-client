# frozen_string_literal: true

require_relative "../external_task_service"
require_relative "../../impl/engine_client_exception"
require_relative "../../impl/external_task_client_logger"

module Operaton
  module Bpm
    module Client
      module Task
        module Impl
          # Mirrors org.operaton.bpm.client.task.impl.ExternalTaskServiceImpl.
          # Methods accept either an ExternalTask or an external task id where
          # the Java interface declares overloads for both.
          class ExternalTaskServiceImpl
            include ExternalTaskService

            def initialize(engine_client)
              @engine_client = engine_client
            end

            def lock(task_or_id, lock_duration)
              handling_errors("locking task") do
                @engine_client.lock(task_id(task_or_id), lock_duration)
              end
            end

            def unlock(external_task)
              handling_errors("unlocking the external task") do
                @engine_client.unlock(task_id(external_task))
              end
            end

            def complete(task_or_id, variables = nil, local_variables = nil)
              handling_errors("completing the external task") do
                @engine_client.complete(task_id(task_or_id), variables, local_variables)
              end
            end

            def set_variables(task_or_process_instance_id, variables)
              process_instance_id =
                if task_or_process_instance_id.respond_to?(:process_instance_id)
                  task_or_process_instance_id.process_instance_id
                else
                  task_or_process_instance_id
                end

              handling_errors("setting variables for external task") do
                @engine_client.set_variables(process_instance_id, variables)
              end
            end

            def handle_failure(task_or_id, error_message, error_details, retries, retry_timeout,
                               variables = nil, local_variables = nil)
              handling_errors("notifying a failure") do
                @engine_client.failure(task_id(task_or_id), error_message, error_details,
                                       retries, retry_timeout, variables, local_variables)
              end
            end

            def handle_bpmn_error(task_or_id, error_code, error_message = nil, variables = nil)
              handling_errors("notifying a BPMN error") do
                @engine_client.bpmn_error(task_id(task_or_id), error_code, error_message, variables)
              end
            end

            def extend_lock(task_or_id, new_duration)
              handling_errors("extending lock") do
                @engine_client.extend_lock(task_id(task_or_id), new_duration)
              end
            end

            protected

            def task_id(task_or_id)
              task_or_id.respond_to?(:id) ? task_or_id.id : task_or_id
            end

            def handling_errors(action_name)
              yield
            rescue Client::Impl::EngineClientException => e
              raise Client::Impl::ExternalTaskClientLogger.client_logger
                                                          .handled_engine_client_exception(action_name, e)
            end
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

describe Operaton::Bpm::Client::Task::Impl::ExternalTaskServiceImpl do
  before do
    # A recording stand-in for EngineClient: captures every call as [name, args].
    @make_recorder = lambda do
      calls = []
      dbl = Object.new
      dbl.define_singleton_method(:__calls) { calls }
      dbl.define_singleton_method(:method_missing) { |name, *args, **_kw, &_blk| calls << [name, args]; nil }
      dbl.define_singleton_method(:respond_to_missing?) { |*| true }
      dbl
    end

    # A stand-in for EngineClient that raises the given error on any call.
    @make_raising = lambda do |error|
      dbl = Object.new
      dbl.define_singleton_method(:method_missing) { |*_args, **_kw, &_blk| raise error }
      dbl.define_singleton_method(:respond_to_missing?) { |*| true }
      dbl
    end

    @engine_client = @make_recorder.call
    @service = Operaton::Bpm::Client::Task::Impl::ExternalTaskServiceImpl.new(@engine_client)

    @task = Operaton::Bpm::Client::Task::Impl::ExternalTaskImpl.new
    @task.id = "task-1"
    @task.process_instance_id = "process-1"
  end

  it "completes by task object" do
    @service.complete(@task)
    @engine_client.__calls.should == [[:complete, ["task-1", nil, nil]]]
  end

  it "completes by id with variables" do
    @service.complete("task-1", { "a" => 1 }, { "b" => 2 })
    @engine_client.__calls.should == [[:complete, ["task-1", { "a" => 1 }, { "b" => 2 }]]]
  end

  it "locks, unlocks and extends locks by task or id" do
    @service.lock(@task, 500)
    @service.unlock(@task)
    @service.extend_lock("task-1", 800)
    @engine_client.__calls.should == [
      [:lock, ["task-1", 500]],
      [:unlock, ["task-1"]],
      [:extend_lock, ["task-1", 800]]
    ]
  end

  it "sets variables using the task's process instance" do
    @service.set_variables(@task, { "x" => 1 })
    @engine_client.__calls.should == [[:set_variables, ["process-1", { "x" => 1 }]]]
  end

  it "reports failures with retry configuration" do
    @service.handle_failure(@task, "msg", "det", 2, 100)
    @engine_client.__calls.should == [[:failure, ["task-1", "msg", "det", 2, 100, nil, nil]]]
  end

  it "reports bpmn errors" do
    @service.handle_bpmn_error(@task, "code")
    @engine_client.__calls.should == [[:bpmn_error, ["task-1", "code", nil, nil]]]
  end

  describe "engine exception translation" do
    before do
      @rest_exception = lambda do |status|
        e = Operaton::Bpm::Client::RestException.new("engine says no", "RestException", 0)
        e.http_status_code = status
        Operaton::Bpm::Client::Impl::EngineClientException.new("wrapped", e)
      end
    end

    it "maps 400 to BadRequestException" do
      service = Operaton::Bpm::Client::Task::Impl::ExternalTaskServiceImpl.new(@make_raising.call(@rest_exception.call(400)))
      lambda { service.lock("task-1", 1) }.should.raise(Operaton::Bpm::Client::BadRequestException)
    end

    it "maps 404 to NotFoundException" do
      service = Operaton::Bpm::Client::Task::Impl::ExternalTaskServiceImpl.new(@make_raising.call(@rest_exception.call(404)))
      lambda { service.lock("task-1", 1) }.should.raise(Operaton::Bpm::Client::NotFoundException)
    end

    it "maps 500 to EngineException" do
      service = Operaton::Bpm::Client::Task::Impl::ExternalTaskServiceImpl.new(@make_raising.call(@rest_exception.call(500)))
      lambda { service.lock("task-1", 1) }.should.raise(Operaton::Bpm::Client::EngineException)
    end

    it "maps other statuses to UnknownHttpErrorException" do
      service = Operaton::Bpm::Client::Task::Impl::ExternalTaskServiceImpl.new(@make_raising.call(@rest_exception.call(418)))
      lambda { service.lock("task-1", 1) }.should.raise(Operaton::Bpm::Client::UnknownHttpErrorException)
    end

    it "maps IO errors to ConnectionLostException" do
      wrapped = Operaton::Bpm::Client::Impl::EngineClientException.new("io", Errno::ECONNREFUSED.new)
      service = Operaton::Bpm::Client::Task::Impl::ExternalTaskServiceImpl.new(@make_raising.call(wrapped))
      lambda { service.lock("task-1", 1) }.should.raise(Operaton::Bpm::Client::ConnectionLostException)
    end
  end
end
