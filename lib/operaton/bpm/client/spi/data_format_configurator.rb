# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Spi
        # Mirrors org.operaton.bpm.client.spi.DataFormatConfigurator. Where
        # Java uses java.util.ServiceLoader, configurators register themselves here.
        module DataFormatConfigurator
          class << self
            def register(configurator)
              configurators << configurator
            end

            def configurators
              @configurators ||= []
            end
          end

          def data_format_class
            raise NotImplementedError
          end

          def configure(data_format)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
