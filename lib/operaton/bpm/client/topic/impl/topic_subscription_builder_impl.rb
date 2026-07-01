# frozen_string_literal: true

require_relative "../topic_subscription_builder"
require_relative "topic_subscription_impl"
require_relative "../../impl/external_task_client_logger"

module Operaton
  module Bpm
    module Client
      module Topic
        module Impl
          # Mirrors org.operaton.bpm.client.topic.impl.TopicSubscriptionBuilderImpl
          class TopicSubscriptionBuilderImpl
            include TopicSubscriptionBuilder

            def initialize(topic_name, topic_subscription_manager)
              @topic_name = topic_name
              # if not nil, no variables are retrieved by default
              @variable_names = nil
              @lock_duration = nil
              @topic_subscription_manager = topic_subscription_manager
              @local_variables = false
              @business_key = nil
              @process_definition_id = nil
              @process_definition_ids = nil
              @process_definition_key = nil
              @process_definition_keys = nil
              @process_definition_version_tag = nil
              @process_variables = nil
              @without_tenant_id = false
              @tenant_ids = nil
              @external_task_handler = nil
              @include_extension_properties = false
            end

            def lock_duration(lock_duration)
              @lock_duration = lock_duration
              self
            end

            # Accepts a handler object responding to #execute, any callable, or a block.
            def handler(external_task_handler = nil, &block)
              @external_task_handler = external_task_handler || block
              self
            end

            def variables(*variable_names)
              ensure_not_nil(variable_names, "variableNames")
              @variable_names = variable_names.flatten
              self
            end

            def local_variables(local_variables)
              @local_variables = local_variables
              self
            end

            def business_key(business_key)
              @business_key = business_key
              self
            end

            def process_definition_id(process_definition_id)
              @process_definition_id = process_definition_id
              self
            end

            def process_definition_id_in(*process_definition_ids)
              ensure_not_nil(process_definition_ids, "processDefinitionIds")
              @process_definition_ids = process_definition_ids.flatten
              self
            end

            def process_definition_key(process_definition_key)
              @process_definition_key = process_definition_key
              self
            end

            def process_definition_key_in(*process_definition_keys)
              ensure_not_nil(process_definition_keys, "processDefinitionKeys")
              @process_definition_keys = process_definition_keys.flatten
              self
            end

            def process_definition_version_tag(process_definition_version_tag)
              ensure_not_nil(process_definition_version_tag, "processDefinitionVersionTag")
              @process_definition_version_tag = process_definition_version_tag
              self
            end

            def process_variables_equals_in(process_variables)
              ensure_not_nil(process_variables, "processVariables")
              @process_variables ||= {}
              process_variables.each do |name, value|
                ensure_not_nil(name, "processVariableName")
                @process_variables[name] = value
              end
              self
            end

            def process_variable_equals(name, value)
              ensure_not_nil(name, "processVariableName")
              @process_variables ||= {}
              @process_variables[name] = value
              self
            end

            def without_tenant_id
              @without_tenant_id = true
              self
            end

            def tenant_id_in(*tenant_ids)
              ensure_not_nil(tenant_ids, "tenantIds")
              @tenant_ids = tenant_ids.flatten
              self
            end

            def include_extension_properties(include_extension_properties)
              @include_extension_properties = include_extension_properties
              self
            end

            def open
              raise logger.topic_name_null_exception if @topic_name.nil?

              if !@lock_duration.nil? && @lock_duration <= 0
                raise logger.lock_duration_is_not_greater_than_zero_exception(@lock_duration)
              end

              raise logger.external_task_handler_null_exception if @external_task_handler.nil?

              subscription = TopicSubscriptionImpl.new(@topic_name, @lock_duration, @external_task_handler,
                                                       @topic_subscription_manager, @variable_names, @business_key)
              subscription.process_definition_id = @process_definition_id if @process_definition_id
              subscription.process_definition_id_in = @process_definition_ids if @process_definition_ids
              subscription.process_definition_key = @process_definition_key if @process_definition_key
              subscription.process_definition_key_in = @process_definition_keys if @process_definition_keys
              subscription.without_tenant_id = @without_tenant_id if @without_tenant_id
              subscription.tenant_id_in = @tenant_ids if @tenant_ids
              subscription.process_definition_version_tag = @process_definition_version_tag if @process_definition_version_tag
              subscription.process_variables = @process_variables if @process_variables
              subscription.local_variables = @local_variables if @local_variables
              subscription.include_extension_properties = @include_extension_properties if @include_extension_properties

              @topic_subscription_manager.subscribe(subscription)
              subscription
            end

            protected

            def ensure_not_nil(parameter, parameter_name)
              raise logger.pass_null_value_parameter(parameter_name) if parameter.nil?
            end

            def logger
              Client::Impl::ExternalTaskClientLogger.client_logger
            end
          end
        end
      end
    end
  end
end
