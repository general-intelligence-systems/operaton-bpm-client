# frozen_string_literal: true

require_relative "primitive_value_mapper"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.NumberValueMapper
            class NumberValueMapper < PrimitiveValueMapper
              protected

              def can_read_value(typed_value_field)
                value = typed_value_field.value
                value.nil? || value.is_a?(Numeric)
              end
            end
          end
        end
      end
    end
  end
end
