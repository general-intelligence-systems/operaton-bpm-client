# frozen_string_literal: true

require_relative "typed_value"
require_relative "variable_map"

module Operaton
  module Bpm
    module Engine
      module Variable
        # Factory methods mirroring org.operaton.bpm.engine.variable.Variables.
        # Defined as a mixin so that Operaton::Bpm::Client::Variable::ClientValues
        # can "extend" Variables like the Java class does.
        module VariablesFactory
          def create_variables
            VariableMap.new
          end

          def untyped_value(value, is_transient = false)
            return value if value.is_a?(TypedValue)

            UntypedValue.new(value, is_transient)
          end

          def untyped_null_value(is_transient = false)
            UntypedValue.new(nil, is_transient)
          end

          def boolean_value(value, is_transient = false)
            BooleanValue.new(value, is_transient)
          end

          def string_value(value, is_transient = false)
            StringValue.new(value, is_transient)
          end

          def date_value(value, is_transient = false)
            DateValue.new(value, is_transient)
          end

          def byte_array_value(value, is_transient = false)
            BytesValue.new(value, is_transient)
          end

          def integer_value(value, is_transient = false)
            IntegerValue.new(value, is_transient)
          end

          def long_value(value, is_transient = false)
            LongValue.new(value, is_transient)
          end

          def short_value(value, is_transient = false)
            ShortValue.new(value, is_transient)
          end

          def double_value(value, is_transient = false)
            DoubleValue.new(value, is_transient)
          end

          # Mirrors Variables.objectValue(value) which returns an ObjectValueBuilder
          def object_value(value, is_transient = false)
            ObjectValueBuilder.new(value, is_transient)
          end

          # Mirrors Variables.serializedObjectValue(...)
          def serialized_object_value(serialized_value = nil)
            SerializedObjectValueBuilder.new(serialized_value)
          end

          # Mirrors Variables.fileValue(filename) which returns a FileValueBuilder
          def file_value(filename)
            FileValueBuilder.new(filename)
          end
        end

        module Variables
          extend VariablesFactory

          # Mirrors Variables.SerializationDataFormats
          module SerializationDataFormats
            JAVA = "application/x-java-serialized-object"
            JSON = "application/json"
            XML = "application/xml"

            def self.json
              JSON
            end
          end
        end

        # Mirrors org.operaton.bpm.engine.variable.value.builder.ObjectValueBuilder
        class ObjectValueBuilder
          def initialize(value, is_transient = false)
            @value = value
            @is_transient = is_transient
            @serialization_data_format = nil
          end

          def serialization_data_format(format)
            @serialization_data_format = format
            self
          end

          def set_transient(is_transient) # rubocop:disable Naming/AccessorMethodName
            @is_transient = is_transient
            self
          end

          def create
            ObjectValue.new(@value, nil, @serialization_data_format, nil, true, @is_transient)
          end
        end

        # Mirrors org.operaton.bpm.engine.variable.value.builder.SerializedObjectValueBuilder
        class SerializedObjectValueBuilder
          def initialize(serialized_value = nil)
            @serialized_value = serialized_value
            @serialization_data_format = nil
            @object_type_name = nil
            @is_transient = false
          end

          def serialized_value(value)
            @serialized_value = value
            self
          end

          def serialization_data_format(format)
            @serialization_data_format = format
            self
          end

          def object_type_name(name)
            @object_type_name = name
            self
          end

          def set_transient(is_transient) # rubocop:disable Naming/AccessorMethodName
            @is_transient = is_transient
            self
          end

          def create
            ObjectValue.new(nil, @serialized_value, @serialization_data_format,
                            @object_type_name, false, @is_transient)
          end
        end

        # Mirrors org.operaton.bpm.engine.variable.value.builder.FileValueBuilder
        class FileValueBuilder
          def initialize(filename)
            @filename = filename
            @bytes = nil
            @mime_type = nil
            @encoding = nil
            @is_transient = false
          end

          # Accepts a byte string, an IO, or a file path.
          def file(file)
            @bytes =
              if file.respond_to?(:read)
                file.read
              elsif file.is_a?(String) && !file.include?("\0") && ::File.file?(file)
                ::File.binread(file)
              else
                file
              end
            self
          end

          def mime_type(mime_type)
            @mime_type = mime_type
            self
          end

          def encoding(encoding)
            @encoding = encoding
            self
          end

          def set_transient(is_transient) # rubocop:disable Naming/AccessorMethodName
            @is_transient = is_transient
            self
          end

          def create
            value = FileValue.new(@filename, @bytes, @is_transient)
            value.mime_type = @mime_type
            value.encoding = @encoding
            value
          end
        end
      end
    end
  end
end
