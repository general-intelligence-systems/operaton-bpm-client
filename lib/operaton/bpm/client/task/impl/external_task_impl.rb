# frozen_string_literal: true

require_relative "../external_task"
require_relative "../../variable/impl/typed_value_field"
require_relative "../../../engine/variable/variable_map"

module Operaton
  module Bpm
    module Client
      module Task
        module Impl
          # Mirrors org.operaton.bpm.client.task.impl.ExternalTaskImpl
          class ExternalTaskImpl
            include ExternalTask

            attr_accessor :activity_id, :activity_instance_id, :error_message, :error_details,
                          :execution_id, :id, :lock_expiration_time, :create_time,
                          :process_definition_id, :process_definition_key,
                          :process_definition_version_tag, :process_instance_id, :retries,
                          :worker_id, :topic_name, :tenant_id, :priority, :variables,
                          :business_key, :received_variable_map

            def self.from_json(hash, object_mapper)
              task = new
              task.activity_id = hash["activityId"]
              task.activity_instance_id = hash["activityInstanceId"]
              task.error_message = hash["errorMessage"]
              task.error_details = hash["errorDetails"]
              task.execution_id = hash["executionId"]
              task.id = hash["id"]
              task.lock_expiration_time = parse_time(hash["lockExpirationTime"], object_mapper)
              task.create_time = parse_time(hash["createTime"], object_mapper)
              task.process_definition_id = hash["processDefinitionId"]
              task.process_definition_key = hash["processDefinitionKey"]
              task.process_definition_version_tag = hash["processDefinitionVersionTag"]
              task.process_instance_id = hash["processInstanceId"]
              task.retries = hash["retries"]
              task.worker_id = hash["workerId"]
              task.topic_name = hash["topicName"]
              task.tenant_id = hash["tenantId"]
              task.priority = hash["priority"] || 0
              task.business_key = hash["businessKey"]
              task.variables = (hash["variables"] || {}).transform_values do |field|
                Variable::Impl::TypedValueField.from_json(field)
              end
              task.set_extension_properties(hash["extensionProperties"])
              task
            end

            def self.parse_time(value, object_mapper)
              return nil if value.nil?

              object_mapper.parse_date(value)
            end
            private_class_method :parse_time

            def initialize
              @variables = {}
              @received_variable_map = {}
              @extension_properties = nil
              @priority = 0
            end

            # Mirrors getAllVariables
            def all_variables
              received_variable_map.keys.to_h { |name| [name, variable(name)] }
            end

            # Mirrors getVariable
            def variable(variable_name)
              variable_value = received_variable_map[variable_name]
              variable_value&.value
            end

            # Mirrors getAllVariablesTyped
            def all_variables_typed(deserialize_object_values = true)
              vars = Engine::Variable::VariableMap.new
              received_variable_map.each_key do |variable_name|
                vars.put_value_typed(variable_name, variable_typed(variable_name, deserialize_object_values))
              end
              vars
            end

            # Mirrors getVariableTyped
            def variable_typed(variable_name, deserialize_object_values = true)
              variable_value = received_variable_map[variable_name]
              variable_value&.typed_value(deserialize_object_values)
            end

            def extension_properties
              @extension_properties || {}
            end

            def set_extension_properties(extension_properties) # rubocop:disable Naming/AccessorMethodName
              @extension_properties = extension_properties
            end

            def extension_property(property_key)
              @extension_properties&.[](property_key)
            end

            def to_s
              "ExternalTaskImpl [" \
                "activityId=#{activity_id}, " \
                "activityInstanceId=#{activity_instance_id}, " \
                "businessKey=#{business_key}, " \
                "errorDetails=#{error_details}, " \
                "errorMessage=#{error_message}, " \
                "executionId=#{execution_id}, " \
                "id=#{id}, " \
                "lockExpirationTime=#{lock_expiration_time}, " \
                "createTime=#{create_time}, " \
                "priority=#{priority}, " \
                "processDefinitionId=#{process_definition_id}, " \
                "processDefinitionKey=#{process_definition_key}, " \
                "processDefinitionVersionTag=#{process_definition_version_tag}, " \
                "processInstanceId=#{process_instance_id}, " \
                "retries=#{retries}, " \
                "tenantId=#{tenant_id}, " \
                "topicName=#{topic_name}, " \
                "workerId=#{worker_id}]"
            end
          end
        end
      end
    end
  end
end
