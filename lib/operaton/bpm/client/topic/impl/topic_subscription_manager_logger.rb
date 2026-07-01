# frozen_string_literal: true

require_relative "../../impl/external_task_client_logger"

module Operaton
  module Bpm
    module Client
      module Topic
        module Impl
          # Mirrors org.operaton.bpm.client.topic.impl.TopicSubscriptionManagerLogger
          class TopicSubscriptionManagerLogger < Client::Impl::ExternalTaskClientLogger
            def exception_while_performing_fetch_and_lock(error)
              log_error("001", "Exception while fetching and locking task.", error)
            end

            def exception_while_executing_external_task_handler(topic_name, error)
              log_error("002", "Exception while executing external task handler '#{topic_name}'.", error)
            end

            def exception_while_shutting_down(error)
              log_error("003", "Exception while shutting down:", error)
            end

            def exception_on_external_task_service_method_invocation(topic_name, error)
              log_error("004", "Exception on external task service method invocation for topic '#{topic_name}':", error)
            end

            def exception_while_executing_backoff_strategy_method(error)
              log_error("005", "Exception while executing back off strategy method.", error)
            end

            def exception_while_acquiring_tasks(error)
              log_error("006", "Exception while acquiring tasks.", error)
            end

            def task_handler_is_null(topic_name)
              log_error("007", "Task handler is null for topic '#{topic_name}'.")
            end

            def fetch_and_lock(subscriptions)
              log_debug("008", "Fetch and lock new external tasks for #{subscriptions.size} topics")
            end

            def timeout(wait_time)
              log_debug("009", "Timed out after #{wait_time} ms without a signal.")
            end
          end
        end
      end
    end
  end
end
