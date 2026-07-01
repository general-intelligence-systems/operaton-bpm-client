# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Topic
        module Impl
          module Dto
            # Mirrors org.operaton.bpm.client.topic.impl.dto.FetchAndLockResponseDto
            class FetchAndLockResponseDto
              attr_reader :external_tasks, :error

              def initialize(external_tasks_or_error)
                if external_tasks_or_error.is_a?(::Exception)
                  @external_tasks = []
                  @error = external_tasks_or_error
                else
                  @external_tasks = external_tasks_or_error
                  @error = nil
                end
              end

              def error?
                !error.nil?
              end
            end
          end
        end
      end
    end
  end
end
