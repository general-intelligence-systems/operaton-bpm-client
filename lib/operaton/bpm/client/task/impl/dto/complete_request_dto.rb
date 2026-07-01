# frozen_string_literal: true

require_relative "../../../impl/request_dto"

module Operaton
  module Bpm
    module Client
      module Task
        module Impl
          module Dto
            # Mirrors org.operaton.bpm.client.task.impl.dto.CompleteRequestDto
            class CompleteRequestDto < Client::Impl::RequestDto
              attr_reader :variables, :local_variables

              def initialize(worker_id, variables, local_variables)
                super(worker_id)
                @variables = variables
                @local_variables = local_variables
              end

              def as_json
                super.merge(
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
