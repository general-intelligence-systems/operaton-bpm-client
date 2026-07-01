# frozen_string_literal: true

require_relative "../../../../spi/data_format_provider"
require_relative "json_data_format"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Format
            module Json
              # Stands in for JacksonJsonDataFormatProvider; registered with the
              # provider registry when the gem is loaded.
              class JsonDataFormatProvider
                include Spi::DataFormatProvider

                def data_format_name
                  JsonDataFormat::NAME
                end

                def create_instance
                  JsonDataFormat.new
                end
              end

              Spi::DataFormatProvider.register(JsonDataFormatProvider.new)
            end
          end
        end
      end
    end
  end
end
