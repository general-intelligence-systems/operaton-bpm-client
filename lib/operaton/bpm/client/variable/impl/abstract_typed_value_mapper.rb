# frozen_string_literal: true

require_relative "value_mapper"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          # Mirrors org.operaton.bpm.client.variable.impl.AbstractTypedValueMapper
          class AbstractTypedValueMapper
            include ValueMapper

            attr_reader :value_type

            def initialize(value_type)
              @value_type = value_type
            end

            def type
              value_type
            end

            def serialization_dataformat
              nil
            end

            def can_handle_typed_value(typed_value)
              type = typed_value.type
              (type.nil? || type_matches?(type)) && can_write_value(typed_value)
            end

            def can_handle_typed_value_field(typed_value_field)
              type = typed_value_field.type
              !type.nil? && type == value_type.name && can_read_value(typed_value_field)
            end

            protected

            # In Java this is valueType.getClass().isAssignableFrom(type.getClass()),
            # where every value type has its own class. Ruby value types are
            # singleton instances, so identity comparison is the equivalent.
            def type_matches?(type)
              type.equal?(value_type)
            end

            def can_write_value(typed_value)
              raise NotImplementedError
            end

            def can_read_value(typed_value_field)
              raise NotImplementedError
            end
          end
        end
      end
    end
  end
end
