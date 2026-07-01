# frozen_string_literal: true

require_relative "../abstract_typed_value_mapper"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.PrimitiveValueMapper
            class PrimitiveValueMapper < AbstractTypedValueMapper
              def read_value(typed_value_field, _deserialize_object_value = true)
                read_typed_value(typed_value_field)
              end

              # Subclasses implement the single-argument variant, mirroring the
              # Java abstract readValue(TypedValueField).
              def read_typed_value(typed_value_field)
                raise NotImplementedError
              end

              protected

              def assignable?(value)
                value_type.assignable?(value)
              end

              def can_write_value(typed_value)
                value = typed_value.value
                value.nil? || assignable?(value)
              end

              def can_read_value(typed_value_field)
                value = typed_value_field.value
                value.nil? || assignable?(value)
              end
            end
          end
        end
      end
    end
  end
end
