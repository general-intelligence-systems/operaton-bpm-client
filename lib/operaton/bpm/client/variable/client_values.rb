# frozen_string_literal: true

require_relative "../../engine/variable/variables"
require_relative "impl/type/json_type_impl"
require_relative "impl/type/xml_type_impl"

module Operaton
  module Bpm
    module Client
      module Variable
        # Mirrors org.operaton.bpm.client.variable.ClientValues, which extends
        # the engine Variables factory with json and xml typed values.
        module ClientValues
          extend Engine::Variable::VariablesFactory

          JSON = Impl::Type::JsonTypeImpl.new
          XML = Impl::Type::XmlTypeImpl.new

          def self.json_value(json_value, is_transient = false)
            Impl::Value::JsonValueImpl.new(json_value, is_transient)
          end

          def self.xml_value(xml_value, is_transient = false)
            Impl::Value::XmlValueImpl.new(xml_value, is_transient)
          end
        end
      end
    end
  end
end

require_relative "impl/value/json_value_impl"
require_relative "impl/value/xml_value_impl"
