# frozen_string_literal: true

require_relative "../abstract_typed_value_mapper"
require_relative "../../../../engine/variable/typed_value"
require_relative "../../../impl/external_task_client_logger"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.ObjectValueMapper
            class ObjectValueMapper < AbstractTypedValueMapper
              VALUE_INFO_OBJECT_TYPE_NAME =
                Engine::Variable::ObjectValueType::VALUE_INFO_OBJECT_TYPE_NAME
              VALUE_INFO_SERIALIZATION_DATA_FORMAT =
                Engine::Variable::ObjectValueType::VALUE_INFO_SERIALIZATION_DATA_FORMAT

              attr_reader :data_format

              def initialize(serialization_data_format, data_format)
                super(Engine::Variable::ValueType::OBJECT)
                @serialization_data_format = serialization_data_format
                @data_format = data_format
              end

              def serialization_dataformat
                @serialization_data_format
              end

              def convert_to_typed_value(untyped_value)
                Engine::Variable::Variables.object_value(untyped_value.value).create
              end

              def write_value(typed_value, typed_value_field)
                serialized_string_value = typed_value.value_serialized

                if typed_value.deserialized?
                  object_to_serialize = typed_value.instance_variable_get(:@value)
                  unless object_to_serialize.nil?
                    begin
                      serialized_string_value = data_format.write_value(object_to_serialize)
                    rescue StandardError => e
                      raise logger.value_mapper_exception_while_serializing_object(e)
                    end
                  end
                end

                typed_value_field.value = serialized_string_value
                update_typed_value(typed_value, serialized_string_value)
              end

              def read_value(typed_value_field, deserialize_object_value)
                serialized_string_value = typed_value_field.value

                if deserialize_object_value
                  deserialized_object = nil
                  unless serialized_string_value.nil?
                    begin
                      object_type_name = read_object_name_from_fields(typed_value_field)
                      deserialized_object = data_format.read_value(serialized_string_value, object_type_name)
                    rescue StandardError => e
                      raise logger.value_mapper_exception_while_deserializing_object(e)
                    end
                  end
                  create_deserialized_value(deserialized_object, serialized_string_value, typed_value_field)
                else
                  create_serialized_value(serialized_string_value, typed_value_field)
                end
              end

              protected

              def update_typed_value(value, serialized_value)
                object_type_name = object_type_name_for(value)
                value.object_type_name = object_type_name
                value.serialized_value = serialized_value
                value.serialization_data_format = @serialization_data_format
              end

              def object_type_name_for(value)
                object_type_name = value.object_type_name

                if object_type_name.nil? && !value.deserialized? && !value.value_serialized.nil?
                  raise logger.value_mapper_exception_due_to_no_object_type_name
                end

                if value.deserialized? && !value.instance_variable_get(:@value).nil?
                  object_type_name = data_format.canonical_type_name(value.instance_variable_get(:@value))
                end

                object_type_name
              end

              def can_write_value(typed_value)
                is_serializable = typed_value.is_a?(Engine::Variable::ObjectValue)
                is_untyped = typed_value.is_a?(Engine::Variable::UntypedValue)
                return false unless is_serializable || is_untyped

                if is_serializable
                  requested_data_format = typed_value.serialization_data_format

                  if typed_value.deserialized?
                    raw_value = typed_value.instance_variable_get(:@value)
                    can_serialize = raw_value.nil? || data_format.can_map(raw_value)
                    can_serialize && (requested_data_format.nil? ||
                                      @serialization_data_format == requested_data_format)
                  else
                    # serialized object => dataformat must match
                    @serialization_data_format == requested_data_format
                  end
                else
                  typed_value.value.nil? || data_format.can_map(typed_value.value)
                end
              end

              def can_read_value(typed_value_field)
                value_info = typed_value_field.value_info || {}
                serialization_dataformat_of_field = value_info[VALUE_INFO_SERIALIZATION_DATA_FORMAT]
                value = typed_value_field.value
                (value.nil? || value.is_a?(String)) &&
                  serialization_dataformat == serialization_dataformat_of_field
              end

              def create_deserialized_value(deserialized_object, serialized_value, typed_value_field)
                object_type_name = read_object_name_from_fields(typed_value_field)
                Engine::Variable::ObjectValue.new(deserialized_object, serialized_value,
                                                  @serialization_data_format, object_type_name, true)
              end

              def create_serialized_value(serialized_value, typed_value_field)
                object_type_name = read_object_name_from_fields(typed_value_field)
                Engine::Variable::ObjectValue.new(nil, serialized_value,
                                                  @serialization_data_format, object_type_name, false)
              end

              def read_object_name_from_fields(typed_value_field)
                (typed_value_field.value_info || {})[VALUE_INFO_OBJECT_TYPE_NAME]
              end

              def logger
                Client::Impl::ExternalTaskClientLogger.client_logger
              end
            end
          end
        end
      end
    end
  end
end
