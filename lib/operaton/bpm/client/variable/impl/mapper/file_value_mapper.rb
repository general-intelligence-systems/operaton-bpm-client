# frozen_string_literal: true

require "base64"
require_relative "../abstract_typed_value_mapper"
require_relative "../value/deferred_file_value_impl"
require_relative "../../../../engine/variable/typed_value"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.FileValueMapper
            class FileValueMapper < AbstractTypedValueMapper
              VALUE_INFO_FILE_NAME = Engine::Variable::FileValueType::VALUE_INFO_FILE_NAME
              VALUE_INFO_FILE_MIME_TYPE = Engine::Variable::FileValueType::VALUE_INFO_FILE_MIME_TYPE
              VALUE_INFO_FILE_ENCODING = Engine::Variable::FileValueType::VALUE_INFO_FILE_ENCODING

              def initialize(engine_client)
                super(Engine::Variable::ValueType::FILE)
                @engine_client = engine_client
              end

              def convert_to_typed_value(_untyped_value)
                raise NotImplementedError, "Currently no automatic conversation from UntypedValue to FileValue"
              end

              def read_value(typed_value_field, _deserialize_value = true)
                value_info = typed_value_field.value_info || {}
                filename = value_info[VALUE_INFO_FILE_NAME]

                file_value = Value::DeferredFileValueImpl.new(filename, @engine_client)
                mime_type = value_info[VALUE_INFO_FILE_MIME_TYPE]
                file_value.mime_type = mime_type if mime_type
                encoding = value_info[VALUE_INFO_FILE_ENCODING]
                file_value.encoding = encoding if encoding
                file_value
              end

              def write_value(file_value, typed_value_field)
                value_info = { VALUE_INFO_FILE_NAME => file_value.filename }
                value_info[VALUE_INFO_FILE_ENCODING] = file_value.encoding if file_value.encoding
                value_info[VALUE_INFO_FILE_MIME_TYPE] = file_value.mime_type if file_value.mime_type
                typed_value_field.value_info = value_info

                bytes = file_value.byte_array
                typed_value_field.value = Base64.strict_encode64(bytes) unless bytes.nil?
              end

              protected

              def can_write_value(typed_value)
                return false if typed_value.nil? || typed_value.type.nil? # untyped value

                typed_value.type.name == value_type.name && !deferred?(typed_value)
              end

              def can_read_value(typed_value_field)
                value = typed_value_field.value
                value.nil? || value.is_a?(String)
              end

              def deferred?(variable_value)
                variable_value.is_a?(Variable::Value::DeferredFileValue) && !variable_value.loaded?
              end
            end
          end
        end
      end
    end
  end
end
