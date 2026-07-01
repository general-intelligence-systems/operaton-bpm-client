# frozen_string_literal: true

require_relative "../../../../engine/variable/value_type"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Type
            # Mirrors org.operaton.bpm.client.variable.impl.type.XmlTypeImpl
            class XmlTypeImpl < Engine::Variable::PrimitiveValueType
              XML_TYPE_NAME = "xml"

              def initialize
                super(XML_TYPE_NAME) { |v| v.is_a?(String) }
              end
            end
          end
        end
      end
    end
  end
end
