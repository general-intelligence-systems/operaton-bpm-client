# frozen_string_literal: true

require_relative "../topic_subscription"

module Operaton
  module Bpm
    module Client
      module Topic
        module Impl
          # Mirrors org.operaton.bpm.client.topic.impl.TopicSubscriptionImpl
          class TopicSubscriptionImpl
            include TopicSubscription

            attr_reader :topic_name, :lock_duration, :external_task_handler, :variable_names, :business_key
            attr_accessor :process_definition_id, :process_definition_id_in,
                          :process_definition_key, :process_definition_key_in,
                          :process_definition_version_tag, :tenant_id_in

            def initialize(topic_name, lock_duration, external_task_handler,
                           topic_subscription_manager, variable_names, business_key)
              @topic_name = topic_name
              @lock_duration = lock_duration
              @external_task_handler = external_task_handler
              @topic_subscription_manager = topic_subscription_manager
              @variable_names = variable_names
              @business_key = business_key
              @local_variables = false
              @without_tenant_id = false
              @include_extension_properties = false
              @process_variables = nil
            end

            def close
              @topic_subscription_manager.unsubscribe(self)
            end

            def local_variables?
              @local_variables
            end

            attr_writer :local_variables

            attr_reader :process_variables

            def process_variables=(process_variables)
              @process_variables ||= {}
              @process_variables.merge!(process_variables)
            end

            def without_tenant_id?
              @without_tenant_id
            end

            attr_writer :without_tenant_id

            def include_extension_properties?
              @include_extension_properties
            end

            attr_writer :include_extension_properties

            # Java equality is based on class and topic name only.
            def ==(other)
              other.instance_of?(self.class) && topic_name == other.topic_name
            end
            alias eql? ==

            def hash
              [self.class, topic_name].hash
            end
          end
        end
      end
    end
  end
end
