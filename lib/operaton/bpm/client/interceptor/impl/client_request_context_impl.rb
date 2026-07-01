# frozen_string_literal: true

require_relative "../client_request_context"

module Operaton
  module Bpm
    module Client
      module Interceptor
        module Impl
          # Mirrors org.operaton.bpm.client.interceptor.impl.ClientRequestContextImpl
          class ClientRequestContextImpl
            include ClientRequestContext

            attr_reader :headers

            def initialize
              @headers = {}
            end

            def add_header(name, value)
              @headers[name] = value
            end
          end
        end
      end
    end
  end
end
