# frozen_string_literal: true

require_relative "../../../../engine/variable/value_type"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Type
            # Mirrors org.operaton.bpm.client.variable.impl.type.JsonTypeImpl
            class JsonTypeImpl < Engine::Variable::PrimitiveValueType
              JSON_TYPE_NAME = "json"

              def initialize
                super(JSON_TYPE_NAME) { |v| v.is_a?(String) }
              end
            end
          end
        end
      end
    end
  end
end
