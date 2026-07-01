# frozen_string_literal: true

require "base64"
require_relative "primitive_value_mapper"
require_relative "../../../../engine/variable/variables"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.ByteArrayValueMapper
            class ByteArrayValueMapper < PrimitiveValueMapper
              def initialize
                super(Engine::Variable::ValueType::BYTES)
              end

              def convert_to_typed_value(untyped_value)
                value = untyped_value.value
                byte_arr = value.respond_to?(:read) ? value.read : value
                Engine::Variable::Variables.byte_array_value(byte_arr)
              end

              def read_typed_value(typed_value_field)
                byte_arr = nil
                value = typed_value_field.value
                byte_arr = Base64.decode64(value) unless value.nil?
                Engine::Variable::Variables.byte_array_value(byte_arr)
              end

              def write_value(bytes_value, typed_value_field)
                bytes = bytes_value.value
                typed_value_field.value = Base64.strict_encode64(bytes) unless bytes.nil?
              end

              protected

              def can_write_value(typed_value)
                super || typed_value.value.respond_to?(:read)
              end

              def can_read_value(typed_value_field)
                value = typed_value_field.value
                value.nil? || value.is_a?(String)
              end
            end
          end
        end
      end
    end
  end
end
