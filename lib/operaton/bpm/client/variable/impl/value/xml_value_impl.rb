# frozen_string_literal: true

require_relative "../../../../engine/variable/typed_value"
require_relative "../../value/xml_value"
require_relative "../type/xml_type_impl"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Value
            # Mirrors org.operaton.bpm.client.variable.impl.value.XmlValueImpl
            class XmlValueImpl < Engine::Variable::PrimitiveTypeValue
              include Variable::Value::XmlValue

              def initialize(value, is_transient = false)
                super(value, ClientValues::XML, is_transient)
              end
            end
          end
        end
      end
    end
  end
end
