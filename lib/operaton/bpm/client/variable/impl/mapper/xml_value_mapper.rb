# frozen_string_literal: true

require_relative "primitive_value_mapper"
require_relative "../../client_values"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.XmlValueMapper
            class XmlValueMapper < PrimitiveValueMapper
              def initialize
                super(ClientValues::XML)
              end

              def convert_to_typed_value(untyped_value)
                ClientValues.xml_value(untyped_value.value)
              end

              def write_value(xml_value, typed_value_field)
                typed_value_field.value = xml_value.value
              end

              def read_typed_value(typed_value_field)
                ClientValues.xml_value(typed_value_field.value)
              end
            end
          end
        end
      end
    end
  end
end
