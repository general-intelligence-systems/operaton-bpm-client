# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Spi
        # Mirrors org.operaton.bpm.client.spi.DataFormatProvider. Where Java
        # uses java.util.ServiceLoader, providers register themselves here.
        module DataFormatProvider
          class << self
            def register(provider)
              providers << provider
            end

            def providers
              @providers ||= []
            end
          end

          def data_format_name
            raise NotImplementedError
          end

          def create_instance
            raise NotImplementedError
          end
        end
      end
    end
  end
end
