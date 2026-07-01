# frozen_string_literal: true

require_relative "../../../impl/request_dto"

module Operaton
  module Bpm
    module Client
      module Task
        module Impl
          module Dto
            # Mirrors org.operaton.bpm.client.task.impl.dto.SetVariablesRequestDto
            class SetVariablesRequestDto < Client::Impl::RequestDto
              attr_reader :modifications

              def initialize(worker_id, modifications)
                super(worker_id)
                @modifications = modifications
              end

              def as_json
                super.merge("modifications" => modifications&.transform_values(&:as_json))
              end
            end
          end
        end
      end
    end
  end
end
