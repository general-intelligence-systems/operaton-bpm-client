# frozen_string_literal: true

require_relative "primitive_value_mapper"
require_relative "../../client_values"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.JsonValueMapper
            class JsonValueMapper < PrimitiveValueMapper
              def initialize
                super(ClientValues::JSON)
              end

              def convert_to_typed_value(untyped_value)
                ClientValues.json_value(untyped_value.value)
              end

              def write_value(json_value, typed_value_field)
                typed_value_field.value = json_value.value
              end

              def read_typed_value(typed_value_field)
                ClientValues.json_value(typed_value_field.value)
              end
            end
          end
        end
      end
    end
  end
end
