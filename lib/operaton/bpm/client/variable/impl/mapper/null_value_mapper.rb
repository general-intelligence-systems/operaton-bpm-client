# frozen_string_literal: true

require_relative "../abstract_typed_value_mapper"
require_relative "../../../../engine/variable/typed_value"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.NullValueMapper
            class NullValueMapper < AbstractTypedValueMapper
              def initialize
                super(Engine::Variable::ValueType::NULL)
              end

              def convert_to_typed_value(_untyped_value)
                Engine::Variable::NullValue::INSTANCE
              end

              def write_value(_typed_value, typed_value_field)
                typed_value_field.value = nil
              end

              def read_value(_typed_value_field, _deserialize = true)
                Engine::Variable::NullValue::INSTANCE
              end

              protected

              def can_write_value(typed_value)
                typed_value.value.nil?
              end

              def can_read_value(typed_value_field)
                typed_value_field.value.nil?
              end
            end
          end
        end
      end
    end
  end
end
