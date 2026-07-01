# frozen_string_literal: true

require "json"
require_relative "../../../../spi/data_format"
require_relative "../../../../exceptions"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Format
            module Json
              # Stands in for org.operaton.bpm.client.variable.impl.format.json
              # .JacksonJsonDataFormat, using Ruby's JSON library.
              class JsonDataFormat
                include Spi::DataFormat

                NAME = "application/json"

                def name
                  NAME
                end

                def can_map(value)
                  json_native?(value) || value.respond_to?(:as_json) || value.respond_to?(:to_h)
                end

                def write_value(value)
                  JSON.generate(jsonify(value))
                end

                # type_identifier is the stored objectTypeName; JSON deserialization
                # in Ruby is generic (hashes/arrays), so it is not used for
                # reconstruction the way Jackson uses Java type names.
                def read_value(value, _type_identifier = nil)
                  JSON.parse(value)
                rescue JSON::ParserError => e
                  raise DataFormatException.new("Unable to parse JSON value", e)
                end

                def canonical_type_name(value)
                  value.class.name
                end

                protected

                def jsonify(value)
                  case value
                  when Hash
                    value.transform_values { |v| jsonify(v) }
                  when Array
                    value.map { |v| jsonify(v) }
                  when String, Numeric, TrueClass, FalseClass, NilClass
                    value
                  else
                    if value.respond_to?(:as_json)
                      value.as_json
                    elsif value.respond_to?(:to_h)
                      jsonify(value.to_h)
                    else
                      value
                    end
                  end
                end

                def json_native?(value)
                  case value
                  when Hash, Array, String, Numeric, TrueClass, FalseClass, NilClass
                    true
                  else
                    false
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
