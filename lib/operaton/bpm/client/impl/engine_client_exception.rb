# frozen_string_literal: true

require_relative "../exceptions"

module Operaton
  module Bpm
    module Client
      module Impl
        # Mirrors org.operaton.bpm.client.impl.EngineClientException — the
        # internal exception wrapping transport/REST failures before they are
        # translated into the public exception hierarchy.
        class EngineClientException < StandardError
          def initialize(message = nil, cause = nil)
            super(message)
            @wrapped_cause = cause
          end

          def cause
            @wrapped_cause || super
          end
        end
      end
    end
  end
end
