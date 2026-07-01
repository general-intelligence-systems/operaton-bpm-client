# frozen_string_literal: true

require_relative "../topic/impl/topic_subscription_builder_impl"

module Operaton
  module Bpm
    module Client
      module Impl
        # Mirrors org.operaton.bpm.client.impl.ExternalTaskClientImpl
        class ExternalTaskClientImpl
          attr_reader :topic_subscription_manager

          def initialize(topic_subscription_manager)
            @topic_subscription_manager = topic_subscription_manager
          end

          # Creates a fluent builder to create and configure a topic subscription.
          def subscribe(topic_name)
            Topic::Impl::TopicSubscriptionBuilderImpl.new(topic_name, topic_subscription_manager)
          end

          # Stops continuous fetching and locking of tasks.
          def stop
            topic_subscription_manager.stop
          end

          # Starts continuous fetching and locking of tasks.
          def start
            topic_subscription_manager.start
          end

          # True while the client is actively fetching tasks.
          def active?
            topic_subscription_manager.running?
          end
          alias is_active? active?
        end
      end
    end
  end
end
