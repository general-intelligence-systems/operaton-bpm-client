# frozen_string_literal: true

require_relative "../../../impl/request_dto"

module Operaton
  module Bpm
    module Client
      module Task
        module Impl
          module Dto
            # Mirrors org.operaton.bpm.client.task.impl.dto.LockRequestDto
            class LockRequestDto < Client::Impl::RequestDto
              attr_reader :lock_duration

              def initialize(worker_id, lock_duration)
                super(worker_id)
                @lock_duration = lock_duration
              end

              def as_json
                super.merge("lockDuration" => lock_duration)
              end
            end
          end
        end
      end
    end
  end
end
