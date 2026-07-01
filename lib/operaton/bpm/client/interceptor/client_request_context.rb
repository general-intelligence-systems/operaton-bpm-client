# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Interceptor
        # Mirrors org.operaton.bpm.client.interceptor.ClientRequestContext
        module ClientRequestContext
          def add_header(name, value)
            raise NotImplementedError, "#{self.class} must implement #add_header"
          end
        end
      end
    end
  end
end
