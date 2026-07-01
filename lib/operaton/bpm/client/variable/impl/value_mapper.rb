# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          # Mirrors org.operaton.bpm.client.variable.impl.ValueMapper
          module ValueMapper
            def type
              raise NotImplementedError
            end

            def write_value(typed_value, typed_value_field)
              raise NotImplementedError
            end

            def read_value(typed_value_field, deserialize_value)
              raise NotImplementedError
            end

            def can_handle_typed_value(typed_value)
              raise NotImplementedError
            end

            def can_handle_typed_value_field(typed_value_field)
              raise NotImplementedError
            end

            def convert_to_typed_value(untyped_value)
              raise NotImplementedError
            end

            def serialization_dataformat
              nil
            end
          end
        end
      end
    end
  end
end
