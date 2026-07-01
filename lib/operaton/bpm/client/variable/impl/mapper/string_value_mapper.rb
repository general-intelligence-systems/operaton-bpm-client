# frozen_string_literal: true

require_relative "primitive_value_mapper"
require_relative "../../../../engine/variable/variables"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.StringValueMapper
            class StringValueMapper < PrimitiveValueMapper
              def initialize
                super(Engine::Variable::ValueType::STRING)
              end

              def convert_to_typed_value(untyped_value)
                Engine::Variable::Variables.string_value(untyped_value.value)
              end

              def read_typed_value(typed_value_field)
                Engine::Variable::Variables.string_value(typed_value_field.value)
              end

              def write_value(string_value, typed_value_field)
                typed_value_field.value = string_value.value
              end
            end
          end
        end
      end
    end
  end
end
