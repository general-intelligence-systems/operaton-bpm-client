# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          # Mirrors org.operaton.bpm.client.variable.impl.TypedValueField
          class TypedValueField
            attr_accessor :value, :type, :value_info

            def self.from_json(hash)
              field = new
              field.value = hash["value"]
              field.type = hash["type"]
              field.value_info = hash["valueInfo"] || {}
              field
            end

            def as_json
              {
                "value" => value,
                "type" => type,
                "valueInfo" => value_info
              }
            end

            def to_s
              "TypedValueField [type=#{type}, value=#{value}, valueInfo=#{value_info}]"
            end
          end
        end
      end
    end
  end
end
