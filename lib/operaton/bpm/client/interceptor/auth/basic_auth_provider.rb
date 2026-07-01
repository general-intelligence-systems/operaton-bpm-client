# frozen_string_literal: true

require "base64"
require_relative "../client_request_interceptor"
require_relative "../../impl/external_task_client_logger"

module Operaton
  module Bpm
    module Client
      module Interceptor
        module Auth
          # Mirrors org.operaton.bpm.client.interceptor.auth.BasicAuthProvider
          class BasicAuthProvider
            include ClientRequestInterceptor

            AUTHORIZATION = "Authorization"

            def initialize(username, password)
              if username.nil? || password.nil?
                raise Client::Impl::ExternalTaskClientLogger.client_logger.basic_auth_credentials_null_exception
              end

              @username = username
              @password = password
            end

            def intercept(request_context)
              auth_token = "#{@username}:#{@password}"
              request_context.add_header(AUTHORIZATION, "Basic #{encode_to_base64(auth_token)}")
            end

            protected

            def encode_to_base64(decoded_string)
              Base64.strict_encode64(decoded_string)
            end
          end
        end
      end
    end
  end
end
