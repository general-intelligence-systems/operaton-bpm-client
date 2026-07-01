# frozen_string_literal: true

require_relative "../../../impl/request_dto"

module Operaton
  module Bpm
    module Client
      module Task
        module Impl
          module Dto
            # Mirrors org.operaton.bpm.client.task.impl.dto.FailureRequestDto
            class FailureRequestDto < Client::Impl::RequestDto
              attr_reader :error_message, :error_details, :retries, :retry_timeout,
                          :variables, :local_variables

              def initialize(worker_id, error_message, error_details, retries, retry_timeout,
                             variables = nil, local_variables = nil)
                super(worker_id)
                @error_message = error_message
                @error_details = error_details
                @retries = retries
                @retry_timeout = retry_timeout
                @variables = variables
                @local_variables = local_variables
              end

              def as_json
                super.merge(
                  "errorMessage" => error_message,
                  "errorDetails" => error_details,
                  "retries" => retries,
                  "retryTimeout" => retry_timeout,
                  "variables" => variables&.transform_values(&:as_json),
                  "localVariables" => local_variables&.transform_values(&:as_json)
                )
              end
            end
          end
        end
      end
    end
  end
end
