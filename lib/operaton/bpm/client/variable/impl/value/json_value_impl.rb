# frozen_string_literal: true

require_relative "../../../../engine/variable/typed_value"
require_relative "../../value/json_value"
require_relative "../type/json_type_impl"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Value
            # Mirrors org.operaton.bpm.client.variable.impl.value.JsonValueImpl
            class JsonValueImpl < Engine::Variable::PrimitiveTypeValue
              include Variable::Value::JsonValue

              def initialize(value, is_transient = false)
                super(value, ClientValues::JSON, is_transient)
              end
            end
          end
        end
      end
    end
  end
end
