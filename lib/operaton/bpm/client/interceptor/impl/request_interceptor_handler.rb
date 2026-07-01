# frozen_string_literal: true

require_relative "client_request_context_impl"
require_relative "../../impl/external_task_client_logger"

module Operaton
  module Bpm
    module Client
      module Interceptor
        module Impl
          # Mirrors org.operaton.bpm.client.interceptor.impl.RequestInterceptorHandler.
          # Applied to every outgoing HTTP request by the RequestExecutor.
          class RequestInterceptorHandler
            attr_reader :interceptors

            def initialize(interceptors)
              @interceptors = interceptors
            end

            # http_request is a Net::HTTPRequest; interceptor headers are added to it.
            def process(http_request)
              intercepted_request = ClientRequestContextImpl.new

              interceptors.each do |request_interceptor|
                if request_interceptor.respond_to?(:intercept)
                  request_interceptor.intercept(intercepted_request)
                else
                  request_interceptor.call(intercepted_request)
                end
              rescue StandardError => e
                Client::Impl::ExternalTaskClientLogger.engine_client_logger.request_interceptor_exception(e)
              end

              intercepted_request.headers.each do |name, value|
                http_request[name] = value
              end
            end
          end
        end
      end
    end
  end
end
