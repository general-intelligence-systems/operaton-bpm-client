# frozen_string_literal: true

require "json"
require "time"

module Operaton
  module Bpm
    module Client
      module Impl
        # Stands in for the configured Jackson ObjectMapper: JSON encoding and
        # decoding plus date handling with the client's configured date format.
        #
        # The date format is a Ruby strftime pattern. The default corresponds to
        # the Java client's "yyyy-MM-dd'T'HH:mm:ss.SSSZ".
        class ObjectMapper
          DEFAULT_DATE_FORMAT = "%Y-%m-%dT%H:%M:%S.%L%z"

          attr_reader :date_format

          def initialize(date_format = DEFAULT_DATE_FORMAT)
            @date_format = date_format
          end

          def write_value_as_string(value)
            JSON.generate(value)
          end

          def read_value(json_string)
            JSON.parse(json_string)
          end

          def format_date(time)
            time = time.to_time if !time.is_a?(Time) && time.respond_to?(:to_time)
            time.strftime(date_format)
          end

          def parse_date(string)
            Time.strptime(string, date_format)
          end
        end
      end
    end
  end
end
