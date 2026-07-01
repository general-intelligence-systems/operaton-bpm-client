# frozen_string_literal: true

# Mirrors the org.operaton.bpm.client.exception package. The classes live
# directly under Operaton::Bpm::Client to avoid shadowing Ruby's ::Exception.
module Operaton
  module Bpm
    module Client
      # Mirrors org.operaton.bpm.client.exception.ExternalTaskClientException
      class ExternalTaskClientException < StandardError
        def initialize(message = nil, cause = nil)
          super(message)
          @wrapped_cause = cause
        end

        def cause
          @wrapped_cause || super
        end
      end

      # Mirrors org.operaton.bpm.client.exception.RestException
      class RestException < ExternalTaskClientException
        attr_reader :type, :code

        def initialize(message, type_or_cause = nil, code = nil)
          if type_or_cause.is_a?(::Exception)
            super(message, type_or_cause)
            @type = nil
            @code = nil
          else
            super(message)
            @type = type_or_cause
            @code = code
          end
          @http_status_code = nil
        end

        def http_status_code
          cause.is_a?(RestException) ? cause.http_status_code : @http_status_code
        end

        attr_writer :http_status_code

        def type
          cause.is_a?(RestException) ? cause.type : @type
        end

        def code
          cause.is_a?(RestException) ? cause.code : @code
        end
      end

      # Thrown when the engine responds with HTTP 400
      class BadRequestException < RestException; end

      # Thrown when the engine responds with HTTP 500
      class EngineException < RestException; end

      # Thrown when the engine responds with HTTP 404
      class NotFoundException < RestException; end

      # Thrown when the engine responds with an HTTP status code not known by the client
      class UnknownHttpErrorException < RestException; end

      # Thrown when the connection to the engine could not be established
      class ConnectionLostException < ExternalTaskClientException; end

      # Thrown when a data format error occurs
      class DataFormatException < ExternalTaskClientException; end

      # Thrown when a variable value cannot be mapped
      class ValueMapperException < ExternalTaskClientException; end
    end
  end
end
