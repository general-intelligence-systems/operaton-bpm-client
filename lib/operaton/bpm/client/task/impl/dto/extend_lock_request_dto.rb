# frozen_string_literal: true

require_relative "../../../impl/request_dto"

module Operaton
  module Bpm
    module Client
      module Task
        module Impl
          module Dto
            # Mirrors org.operaton.bpm.client.task.impl.dto.ExtendLockRequestDto
            class ExtendLockRequestDto < Client::Impl::RequestDto
              attr_reader :new_duration

              def initialize(worker_id, new_duration)
                super(worker_id)
                @new_duration = new_duration
              end

              def as_json
                super.merge("newDuration" => new_duration)
              end
            end
          end
        end
      end
    end
  end
end
