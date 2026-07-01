# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Task
        # Mirrors org.operaton.bpm.client.task.ExternalTaskHandler, a
        # functional interface. Handlers may be any object responding to
        # #execute(external_task, external_task_service) or any callable
        # (Proc/lambda) taking the same two arguments.
        module ExternalTaskHandler
          def execute(external_task, external_task_service)
            raise NotImplementedError, "#{self.class} must implement #execute"
          end

          # Invokes a handler regardless of which convention it follows.
          def self.invoke(handler, external_task, external_task_service)
            if handler.respond_to?(:execute)
              handler.execute(external_task, external_task_service)
            else
              handler.call(external_task, external_task_service)
            end
          end
        end
      end
    end
  end
end
