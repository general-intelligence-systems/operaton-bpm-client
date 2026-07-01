# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Topic
        module Impl
          module Dto
            # Mirrors org.operaton.bpm.client.topic.impl.dto.TopicRequestDto
            class TopicRequestDto
              attr_reader :topic_name, :lock_duration, :variables, :business_key
              attr_accessor :local_variables, :process_definition_id, :process_definition_id_in,
                            :process_definition_key, :process_definition_key_in,
                            :process_definition_version_tag, :process_variables,
                            :without_tenant_id, :tenant_id_in, :include_extension_properties

              def initialize(topic_name, lock_duration, variables, business_key)
                @topic_name = topic_name
                @lock_duration = lock_duration
                @variables = variables
                @business_key = business_key
                @local_variables = false
                @without_tenant_id = false
                @include_extension_properties = false
              end

              def self.from_topic_subscription(topic_subscription, client_lock_duration)
                lock_duration = topic_subscription.lock_duration || client_lock_duration

                dto = new(topic_subscription.topic_name, lock_duration,
                          topic_subscription.variable_names, topic_subscription.business_key)

                dto.process_definition_id = topic_subscription.process_definition_id
                dto.process_definition_id_in = topic_subscription.process_definition_id_in
                dto.process_definition_key = topic_subscription.process_definition_key
                dto.process_definition_key_in = topic_subscription.process_definition_key_in
                dto.without_tenant_id = topic_subscription.without_tenant_id?
                dto.tenant_id_in = topic_subscription.tenant_id_in
                dto.process_definition_version_tag = topic_subscription.process_definition_version_tag
                dto.process_variables = topic_subscription.process_variables
                dto.local_variables = topic_subscription.local_variables?
                dto.include_extension_properties = topic_subscription.include_extension_properties?
                dto
              end

              def as_json
                {
                  "topicName" => topic_name,
                  "lockDuration" => lock_duration,
                  "variables" => variables,
                  "localVariables" => local_variables,
                  "businessKey" => business_key,
                  "processDefinitionId" => process_definition_id,
                  "processDefinitionIdIn" => process_definition_id_in,
                  "processDefinitionKey" => process_definition_key,
                  "processDefinitionKeyIn" => process_definition_key_in,
                  "processDefinitionVersionTag" => process_definition_version_tag,
                  "processVariables" => process_variables,
                  "withoutTenantId" => without_tenant_id,
                  "tenantIdIn" => tenant_id_in,
                  "includeExtensionProperties" => include_extension_properties
                }
              end
            end
          end
        end
      end
    end
  end
end
