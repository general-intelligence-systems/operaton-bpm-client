# frozen_string_literal: true

require_relative "../../../impl/request_dto"

module Operaton
  module Bpm
    module Client
      module Task
        module Impl
          module Dto
            # Mirrors org.operaton.bpm.client.task.impl.dto.BpmnErrorRequestDto
            class BpmnErrorRequestDto < Client::Impl::RequestDto
              attr_reader :error_code, :error_message, :variables

              def initialize(worker_id, error_code, error_message = nil, variables = nil)
                super(worker_id)
                @error_code = error_code
                @error_message = error_message
                @variables = variables
              end

              def as_json
                super.merge(
                  "errorCode" => error_code,
                  "errorMessage" => error_message,
                  "variables" => variables&.transform_values(&:as_json)
                )
              end
            end
          end
        end
      end
    end
  end
end
