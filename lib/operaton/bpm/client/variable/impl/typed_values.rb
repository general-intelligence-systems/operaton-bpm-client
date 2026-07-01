# frozen_string_literal: true

require_relative "typed_value_field"
require_relative "variable_value"
require_relative "../../impl/external_task_client_logger"
require_relative "../../../engine/variable/variables"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          # Mirrors org.operaton.bpm.client.variable.impl.TypedValues
          class TypedValues
            def initialize(serializers)
              @serializers = serializers
            end

            # Serializes a Hash (or Engine::Variable::VariableMap) of variables
            # into a map of variable name => TypedValueField.
            def serialize_variables(variables)
              result = {}
              return result if variables.nil?

              if variables.is_a?(Engine::Variable::VariableMap)
                variables.keys.each do |variable_name|
                  result[variable_name] = serialize_variable(variable_name,
                                                             variables.get_value_typed(variable_name))
                end
              else
                variables.each do |variable_name, variable_value|
                  result[variable_name] = serialize_variable(variable_name, variable_value)
                end
              end

              result
            end

            # Mirrors wrapVariables: builds lazily-deserialized VariableValue
            # objects out of the raw TypedValueFields received from the engine.
            def wrap_variables(external_task, variables)
              execution_id = external_task.execution_id
              result = {}

              variables&.each do |variable_name, variable_value|
                type_name = variable_value.type
                if type_name && !type_name.empty?
                  variable_value.type = type_name[0].downcase + type_name[1..]
                end
                result[variable_name] = VariableValue.new(execution_id, variable_name, variable_value, @serializers)
              end

              result
            end

            protected

            def serialize_variable(variable_name, variable_value)
              typed_value = create_typed_value(variable_value)
              to_typed_value_field(typed_value)
            rescue StandardError => e
              raise logger.cannot_serialize_variable(variable_name, e)
            end

            def to_typed_value_field(typed_value)
              serializer = find_serializer(typed_value)

              if typed_value.is_a?(Engine::Variable::UntypedValue)
                typed_value = serializer.convert_to_typed_value(typed_value)
              end

              typed_value_field = TypedValueField.new
              serializer.write_value(typed_value, typed_value_field)

              value_type = typed_value.type
              typed_value_field.value_info = value_type.value_info(typed_value)
              type_name = value_type.name
              typed_value_field.type = type_name[0].upcase + type_name[1..]
              typed_value_field
            end

            def find_serializer(typed_value)
              @serializers.find_mapper_for_typed_value(typed_value)
            end

            def create_typed_value(value)
              return value if value.is_a?(Engine::Variable::TypedValue)

              Engine::Variable::Variables.untyped_value(value)
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
