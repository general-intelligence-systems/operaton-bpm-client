# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Interceptor
        # Mirrors org.operaton.bpm.client.interceptor.ClientRequestInterceptor
        # (a functional interface in Java). Any object responding to
        # #intercept(request_context) — including a Proc via #to_proc — works.
        module ClientRequestInterceptor
          def intercept(request_context)
            raise NotImplementedError, "#{self.class} must implement #intercept"
          end
        end
      end
    end
  end
end
