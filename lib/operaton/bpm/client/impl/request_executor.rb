# frozen_string_literal: true

require "net/http"
require "uri"
require "openssl"
require "timeout"

require_relative "external_task_client_logger"
require_relative "engine_client_logger"
require_relative "engine_client_exception"
require_relative "engine_rest_exception_dto"
require_relative "object_mapper"

module Operaton
  module Bpm
    module Client
      module Impl
        # Mirrors org.operaton.bpm.client.impl.RequestExecutor, built on
        # Net::HTTP instead of Apache HttpClient.
        class RequestExecutor
          HEADER_CONTENT_TYPE_JSON = ["Content-Type", "application/json"].freeze
          HEADER_USER_AGENT = ["User-Agent", "Operaton External Task Client"].freeze

          # Sentinels standing in for the Java response-class parameters
          VOID = :void
          BYTES = :bytes

          def initialize(object_mapper, interceptor_handler: nil, http_customizer: nil, read_timeout: 60)
            @object_mapper = object_mapper
            @interceptor_handler = interceptor_handler
            @http_customizer = http_customizer
            @read_timeout = read_timeout
            @logger = ExternalTaskClientLogger.engine_client_logger
          end

          # response_type: VOID, BYTES, or a class/array responding to .from_json.
          # Passing [SomeDto] deserializes a JSON array into a list of DTOs.
          def post_request(resource_url, request_dto, response_type)
            body = serialize_request(request_dto)
            uri = URI(resource_url)

            request = Net::HTTP::Post.new(uri)
            request[HEADER_USER_AGENT[0]] = HEADER_USER_AGENT[1]
            request[HEADER_CONTENT_TYPE_JSON[0]] = HEADER_CONTENT_TYPE_JSON[1]
            request.body = body

            execute_request(uri, request, response_type)
          end

          def get_request(resource_url)
            uri = URI(resource_url)

            request = Net::HTTP::Get.new(uri)
            request[HEADER_USER_AGENT[0]] = HEADER_USER_AGENT[1]
            request[HEADER_CONTENT_TYPE_JSON[0]] = HEADER_CONTENT_TYPE_JSON[1]

            execute_request(uri, request, BYTES)
          end

          protected

          def execute_request(uri, request, response_type)
            @interceptor_handler&.process(request)

            response = perform_http_request(uri, request)
            handle_response(request, response, response_type)
          rescue RestException => e
            raise @logger.exception_while_receiving_response(describe(request), e)
          rescue IOError, SystemCallError, SocketError, Timeout::Error,
                 OpenSSL::SSL::SSLError, Net::OpenTimeout, Net::ReadTimeout => e
            raise @logger.exception_while_establishing_connection(describe(request), e)
          end

          def perform_http_request(uri, request)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = uri.scheme == "https"
            http.read_timeout = @read_timeout
            @http_customizer&.call(http)
            http.start { |conn| conn.request(request) }
          end

          def handle_response(request, response, response_type)
            status = response.code.to_i

            if status >= 300
              engine_exception = deserialize_error(response).to_rest_exception
              engine_exception.http_status_code = status
              raise engine_exception
            end

            return nil if response_type == VOID
            return response.body if response_type == BYTES
            return nil if response.body.nil? || response.body.empty?

            deserialize_response(response.body, response_type)
          end

          def deserialize_error(response)
            EngineRestExceptionDto.from_json(@object_mapper.read_value(response.body.to_s))
          rescue StandardError
            dto = EngineRestExceptionDto.new
            dto.message = response.body.to_s
            dto
          end

          def deserialize_response(body, response_type)
            parsed =
              begin
                @object_mapper.read_value(body)
              rescue JSON::ParserError => e
                raise @logger.exception_while_parsing_json_object(response_type, e)
              end

            begin
              if response_type.is_a?(Array)
                item_type = response_type.first
                parsed.map { |item| item_type.from_json(item, @object_mapper) }
              elsif response_type.respond_to?(:from_json)
                response_type.from_json(parsed, @object_mapper)
              else
                parsed
              end
            rescue StandardError => e
              raise @logger.exception_while_mapping_json_object(response_type, e)
            end
          end

          def serialize_request(request_dto)
            return nil if request_dto.nil?

            @object_mapper.write_value_as_string(request_dto.as_json)
          rescue StandardError => e
            raise @logger.exception_while_serializing_json_object(request_dto, e)
          end

          def describe(request)
            "#{request.method} #{request.uri}"
          end
        end
      end
    end
  end
end
