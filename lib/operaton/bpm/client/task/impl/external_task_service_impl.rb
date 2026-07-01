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
