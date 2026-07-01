# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          # Mirrors org.operaton.bpm.client.variable.impl.VariableValue —
          # lazily deserialized variable value received from the engine.
          class VariableValue
            def initialize(execution_id, variable_name, typed_value_field, mappers)
              @execution_id = execution_id
              @variable_name = variable_name
              @typed_value_field = typed_value_field
              @mappers = mappers
              @serializer = nil
              @cached_value = nil
            end

            def value
              typed_value&.value
            end

            def typed_value(deserialize_value = true)
              if deserialize_value && @cached_value.is_a?(Engine::Variable::ObjectValue) &&
                 !@cached_value.deserialized?
                @cached_value = nil
              end

              if @cached_value.nil?
                @cached_value = serializer.read_value(@typed_value_field, deserialize_value)

                if @cached_value.is_a?(Value::DeferredFileValueImpl)
                  @cached_value.execution_id = @execution_id
                  @cached_value.variable_name = @variable_name
                end
              end

              @cached_value
            end

            def serializer
              @serializer ||= @mappers.find_mapper_for_typed_value_field(@typed_value_field)
            end

            def to_s
              "VariableValue [cachedValue=#{@cached_value}, executionId=#{@execution_id}, " \
                "variableName=#{@variable_name}, typedValueField=#{@typed_value_field}]"
            end
          end
        end
      end
    end
  end
end
