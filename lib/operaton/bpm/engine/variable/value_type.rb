# frozen_string_literal: true

module Operaton
  module Bpm
    module Engine
      module Variable
        # Mirrors org.operaton.bpm.engine.variable.type.ValueType and its
        # implementations, reduced to what the external task client needs.
        class ValueType
          attr_reader :name

          def initialize(name)
            @name = name
          end

          def primitive_value_type?
            false
          end

          def abstract?
            false
          end

          # Mirrors ValueType#getValueInfo(TypedValue)
          def value_info(typed_value)
            info = {}
            info[VALUE_INFO_TRANSIENT] = true if typed_value.transient?
            info
          end

          def to_s
            name
          end

          VALUE_INFO_TRANSIENT = "transient"
        end

        class PrimitiveValueType < ValueType
          def initialize(name, &assignable)
            super(name)
            @assignable = assignable
          end

          def primitive_value_type?
            true
          end

          # Mirrors PrimitiveValueType#getJavaType assignability checks.
          def assignable?(value)
            @assignable ? @assignable.call(value) : false
          end
        end

        class NumberValueType < PrimitiveValueType
          def abstract?
            true
          end
        end

        class ObjectValueType < ValueType
          VALUE_INFO_OBJECT_TYPE_NAME = "objectTypeName"
          VALUE_INFO_SERIALIZATION_DATA_FORMAT = "serializationDataFormat"

          def initialize
            super("object")
          end

          def value_info(typed_value)
            info = {}
            if typed_value.object_type_name
              info[VALUE_INFO_OBJECT_TYPE_NAME] = typed_value.object_type_name
            end
            if typed_value.serialization_data_format
              info[VALUE_INFO_SERIALIZATION_DATA_FORMAT] = typed_value.serialization_data_format
            end
            info[VALUE_INFO_TRANSIENT] = true if typed_value.transient?
            info
          end
        end

        class FileValueType < ValueType
          VALUE_INFO_FILE_NAME = "filename"
          VALUE_INFO_FILE_MIME_TYPE = "mimetype"
          VALUE_INFO_FILE_ENCODING = "encoding"

          def initialize
            super("file")
          end

          def value_info(typed_value)
            info = {}
            info[VALUE_INFO_FILE_NAME] = typed_value.filename
            info[VALUE_INFO_FILE_MIME_TYPE] = typed_value.mime_type if typed_value.mime_type
            info[VALUE_INFO_FILE_ENCODING] = typed_value.encoding if typed_value.encoding
            info[VALUE_INFO_TRANSIENT] = true if typed_value.transient?
            info
          end
        end

        class ValueType
          INTEGER_MIN = -2**31
          INTEGER_MAX = 2**31 - 1
          LONG_MIN = -2**63
          LONG_MAX = 2**63 - 1
          SHORT_MIN = -2**15
          SHORT_MAX = 2**15 - 1

          NULL = PrimitiveValueType.new("null") { |v| v.nil? }
          BOOLEAN = PrimitiveValueType.new("boolean") { |v| v == true || v == false }
          STRING = PrimitiveValueType.new("string") { |v| v.is_a?(String) }
          DATE = PrimitiveValueType.new("date") do |v|
            v.is_a?(Time) || (defined?(DateTime) && v.is_a?(DateTime)) || (defined?(::Date) && v.is_a?(::Date))
          end
          BYTES = PrimitiveValueType.new("bytes") { |v| v.is_a?(String) }
          INTEGER = PrimitiveValueType.new("integer") { |v| v.is_a?(Integer) && v.between?(INTEGER_MIN, INTEGER_MAX) }
          LONG = PrimitiveValueType.new("long") { |v| v.is_a?(Integer) && v.between?(LONG_MIN, LONG_MAX) }
          SHORT = PrimitiveValueType.new("short") { |v| v.is_a?(Integer) && v.between?(SHORT_MIN, SHORT_MAX) }
          DOUBLE = PrimitiveValueType.new("double") { |v| v.is_a?(Float) }
          NUMBER = NumberValueType.new("number") { |v| v.is_a?(Numeric) }
          OBJECT = ObjectValueType.new
          FILE = FileValueType.new
        end
      end
    end
  end
end
