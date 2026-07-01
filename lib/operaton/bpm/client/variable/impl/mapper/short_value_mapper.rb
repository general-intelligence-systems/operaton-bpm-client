# frozen_string_literal: true

require_relative "number_value_mapper"
require_relative "../../../../engine/variable/variables"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.ShortValueMapper
            class ShortValueMapper < NumberValueMapper
              def initialize
                super(Engine::Variable::ValueType::SHORT)
              end

              def convert_to_typed_value(untyped_value)
                Engine::Variable::Variables.short_value(untyped_value.value)
              end

              def write_value(short_value, typed_value_field)
                typed_value_field.value = short_value.value
              end

              def read_typed_value(typed_value_field)
                value = typed_value_field.value
                Engine::Variable::Variables.short_value(value.nil? ? nil : Integer(value))
              end
            end
          end
        end
      end
    end
  end
end
