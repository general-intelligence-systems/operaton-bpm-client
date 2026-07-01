# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Spi
        # Mirrors org.operaton.bpm.client.spi.DataFormat
        module DataFormat
          def name
            raise NotImplementedError
          end

          def can_map(value)
            raise NotImplementedError
          end

          def write_value(value)
            raise NotImplementedError
          end

          def read_value(value, type_identifier_or_class)
            raise NotImplementedError
          end

          def canonical_type_name(value)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
