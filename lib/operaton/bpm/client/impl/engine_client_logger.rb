# frozen_string_literal: true

require_relative "external_task_client_logger"
require_relative "engine_client_exception"

module Operaton
  module Bpm
    module Client
      module Impl
        # Mirrors org.operaton.bpm.client.impl.EngineClientLogger
        class EngineClientLogger < ExternalTaskClientLogger
          def exception_while_receiving_response(http_request, error)
            EngineClientException.new(exception_message(
              "001", "Request '{}' returned error: status code '{}' - message: {}",
              http_request, error.http_status_code, error.message), error)
          end

          def exception_while_establishing_connection(http_request, error)
            EngineClientException.new(exception_message(
              "002", "Exception while establishing connection for request '{}'", http_request), error)
          end

          def exception_while_closing_resource_stream(response, error)
            log_error("003", "Exception while closing resource stream of response '{}': ", error, response)
          end

          def exception_while_parsing_json_object(response_dto_class, error)
            EngineClientException.new(exception_message(
              "004", "Exception while parsing json object to response dto class '{}'", response_dto_class), error)
          end

          def exception_while_mapping_json_object(response_dto_class, error)
            EngineClientException.new(exception_message(
              "005", "Exception while mapping json object to response dto class '{}'", response_dto_class), error)
          end

          def exception_while_deserializing_json_object(response_dto_class, error)
            EngineClientException.new(exception_message(
              "006", "Exception while deserializing json object to response dto class '{}'", response_dto_class), error)
          end

          def exception_while_serializing_json_object(dto, error)
            EngineClientException.new(exception_message(
              "007", "Exception while serializing json object to '{}'", dto), error)
          end

          def request_interceptor_exception(error)
            log_error("008", "Exception while executing request interceptor: {}", error)
          end
        end
      end
    end
  end
end
