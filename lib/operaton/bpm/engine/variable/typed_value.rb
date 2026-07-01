# frozen_string_literal: true

require_relative "value_type"

module Operaton
  module Bpm
    module Engine
      module Variable
        # Mirrors org.operaton.bpm.engine.variable.value.TypedValue
        class TypedValue
          attr_reader :value, :type

          def initialize(value, type, is_transient = false)
            @value = value
            @type = type
            @is_transient = is_transient
          end

          def transient?
            @is_transient
          end

          attr_writer :is_transient

          def to_s
            "Value '#{value}' of type '#{type}', isTransient=#{transient?}"
          end
        end

        # Mirrors org.operaton.bpm.engine.variable.value.PrimitiveValue
        class PrimitiveTypeValue < TypedValue
        end

        class BooleanValue < PrimitiveTypeValue
          def initialize(value, is_transient = false)
            super(value, ValueType::BOOLEAN, is_transient)
          end
        end

        class StringValue < PrimitiveTypeValue
          def initialize(value, is_transient = false)
            super(value, ValueType::STRING, is_transient)
          end
        end

        class DateValue < PrimitiveTypeValue
          def initialize(value, is_transient = false)
            super(value, ValueType::DATE, is_transient)
          end
        end

        class BytesValue < PrimitiveTypeValue
          def initialize(value, is_transient = false)
            super(value, ValueType::BYTES, is_transient)
          end
        end

        class IntegerValue < PrimitiveTypeValue
          def initialize(value, is_transient = false)
            super(value, ValueType::INTEGER, is_transient)
          end
        end

        class LongValue < PrimitiveTypeValue
          def initialize(value, is_transient = false)
            super(value, ValueType::LONG, is_transient)
          end
        end

        class ShortValue < PrimitiveTypeValue
          def initialize(value, is_transient = false)
            super(value, ValueType::SHORT, is_transient)
          end
        end

        class DoubleValue < PrimitiveTypeValue
          def initialize(value, is_transient = false)
            super(value, ValueType::DOUBLE, is_transient)
          end
        end

        # Mirrors org.operaton.bpm.engine.variable.impl.value.UntypedValueImpl
        class UntypedValue < TypedValue
          def initialize(value, is_transient = false)
            super(value, nil, is_transient)
          end
        end

        # Mirrors org.operaton.bpm.engine.variable.impl.value.NullValueImpl
        class NullValue < TypedValue
          def initialize(is_transient = false)
            super(nil, ValueType::NULL, is_transient)
          end

          INSTANCE = new
        end

        # Mirrors org.operaton.bpm.engine.variable.value.ObjectValue /
        # SerializableValue semantics.
        class ObjectValue < TypedValue
          attr_accessor :object_type_name, :serialization_data_format, :serialized_value

          def initialize(value, serialized_value = nil, serialization_data_format = nil,
                         object_type_name = nil, deserialized = true, is_transient = false)
            super(value, ValueType::OBJECT, is_transient)
            @serialized_value = serialized_value
            @serialization_data_format = serialization_data_format
            @object_type_name = object_type_name
            @deserialized = deserialized
          end

          def deserialized?
            @deserialized
          end

          def value_serialized
            @serialized_value
          end

          def value
            unless deserialized?
              raise Client::ValueMapperException,
                    "Object is not deserialized: call value_serialized instead"
            end
            @value
          end

          def set_value(value) # rubocop:disable Naming/AccessorMethodName
            @value = value
          end
        end

        # Mirrors org.operaton.bpm.engine.variable.value.FileValue (FileValueImpl)
        class FileValue < TypedValue
          attr_accessor :filename, :mime_type, :encoding

          def initialize(filename, byte_array = nil, is_transient = false)
            super(byte_array, ValueType::FILE, is_transient)
            @filename = filename
          end

          def byte_array
            @value
          end

          def set_value(bytes) # rubocop:disable Naming/AccessorMethodName
            @value = bytes
          end
        end
      end
    end
  end
end
