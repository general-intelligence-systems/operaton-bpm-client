# frozen_string_literal: true

require_relative "topic_subscription_manager_logger"
require_relative "dto/topic_request_dto"
require_relative "dto/fetch_and_lock_response_dto"
require_relative "../../task/impl/external_task_service_impl"
require_relative "../../task/external_task_handler"
require_relative "../../backoff/error_aware_backoff_strategy"
require_relative "../../impl/engine_client_exception"
require_relative "../../impl/external_task_client_logger"
require_relative "../../exceptions"

module Operaton
  module Bpm
    module Client
      module Topic
        module Impl
          # Mirrors org.operaton.bpm.client.topic.impl.TopicSubscriptionManager.
          # Runs the fetch-and-lock loop on a dedicated thread.
          class TopicSubscriptionManager
            attr_reader :engine_client

            def initialize(engine_client, typed_values, client_lock_duration)
              @engine_client = engine_client
              @subscriptions = []
              @subscriptions_mutex = Mutex.new
              @task_topic_requests = []
              @external_task_handlers = {}
              @client_lock_duration = client_lock_duration
              @typed_values = typed_values
              @external_task_service = Task::Impl::ExternalTaskServiceImpl.new(engine_client)
              @is_backoff_strategy_disabled = false
              @backoff_strategy = nil

              @is_running = false
              @state_mutex = Mutex.new
              @acquisition_monitor = Mutex.new
              @is_waiting = ConditionVariable.new
              @resume_signaled = false
              @thread = nil
            end

            def run
              while running?
                begin
                  acquire
                rescue StandardError => e
                  logger.exception_while_acquiring_tasks(e)
                end
              end
            end

            def stop
              @state_mutex.synchronize do
                return unless @is_running

                @is_running = false
              end
              resume
              begin
                @thread&.join
              rescue StandardError => e
                logger.exception_while_shutting_down(e)
              end
            end

            def start
              @state_mutex.synchronize do
                return if @is_running

                @is_running = true
                @thread = Thread.new { run }
                @thread.name = "TopicSubscriptionManager"
              end
            end

            def subscribe(subscription)
              @subscriptions_mutex.synchronize do
                if @subscriptions.include?(subscription)
                  raise logger.topic_name_already_subscribed_exception(subscription.topic_name)
                end

                @subscriptions << subscription
              end
              resume
            end

            def unsubscribe(subscription)
              @subscriptions_mutex.synchronize { @subscriptions.delete(subscription) }
            end

            def subscriptions
              @subscriptions_mutex.synchronize { @subscriptions.dup }
            end

            def running?
              @state_mutex.synchronize { @is_running }
            end
            alias is_running? running?

            def backoff_strategy=(backoff_strategy)
              @backoff_strategy = backoff_strategy
            end

            def disable_backoff_strategy
              @is_backoff_strategy_disabled = true
            end

            protected

            def acquire
              @task_topic_requests.clear
              @external_task_handlers.clear
              subscriptions.each { |subscription| prepare_acquisition(subscription) }

              return if @task_topic_requests.empty?

              fetch_and_lock_response = fetch_and_lock(@task_topic_requests)

              fetch_and_lock_response.external_tasks.each do |external_task|
                topic_name = external_task.topic_name
                task_handler = @external_task_handlers[topic_name]

                if task_handler
                  handle_external_task(external_task, task_handler)
                else
                  logger.task_handler_is_null(topic_name)
                end
              end

              run_backoff_strategy(fetch_and_lock_response) unless @is_backoff_strategy_disabled
            end

            def prepare_acquisition(subscription)
              @task_topic_requests << Dto::TopicRequestDto.from_topic_subscription(subscription, @client_lock_duration)
              @external_task_handlers[subscription.topic_name] = subscription.external_task_handler
            end

            def fetch_and_lock(task_topic_requests)
              logger.fetch_and_lock(task_topic_requests)
              external_tasks = @engine_client.fetch_and_lock(task_topic_requests)
              Dto::FetchAndLockResponseDto.new(external_tasks)
            rescue Client::Impl::EngineClientException => e
              logger.exception_while_performing_fetch_and_lock(e)
              Dto::FetchAndLockResponseDto.new(
                client_logger.handled_engine_client_exception("fetching and locking task", e)
              )
            end

            def handle_external_task(external_task, task_handler)
              variables = external_task.variables
              external_task.received_variable_map = @typed_values.wrap_variables(external_task, variables)

              begin
                Task::ExternalTaskHandler.invoke(task_handler, external_task, @external_task_service)
              rescue ExternalTaskClientException => e
                logger.exception_on_external_task_service_method_invocation(external_task.topic_name, e)
              rescue StandardError => e
                logger.exception_while_executing_external_task_handler(external_task.topic_name, e)
              end
            end

            def run_backoff_strategy(fetch_and_lock_response)
              external_tasks = fetch_and_lock_response.external_tasks

              if @backoff_strategy.is_a?(Backoff::ErrorAwareBackoffStrategy) ||
                 @backoff_strategy.method(:reconfigure).arity != 1
                @backoff_strategy.reconfigure(external_tasks, fetch_and_lock_response.error)
              else
                @backoff_strategy.reconfigure(external_tasks)
              end

              suspend(@backoff_strategy.calculate_backoff_time)
            rescue StandardError => e
              logger.exception_while_executing_backoff_strategy_method(e)
            end

            def suspend(wait_time_ms)
              return unless wait_time_ms.positive? && running?

              @acquisition_monitor.synchronize do
                end_time = monotonic_ms + wait_time_ms
                remaining = wait_time_ms

                while remaining.positive? && running?
                  break if @resume_signaled

                  @is_waiting.wait(@acquisition_monitor, remaining / 1000.0)
                  break if @resume_signaled

                  remaining = end_time - monotonic_ms
                end

                logger.timeout(wait_time_ms) if remaining <= 0 && running? && !@resume_signaled
                @resume_signaled = false
              end
            end

            def resume
              @acquisition_monitor.synchronize do
                @resume_signaled = true
                @is_waiting.signal
              end
            end

            def monotonic_ms
              Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
            end

            def logger
              Client::Impl::ExternalTaskClientLogger.topic_subscription_manager_logger
            end

            def client_logger
              Client::Impl::ExternalTaskClientLogger.client_logger
            end
          end
        end
      end
    end
  end
end
