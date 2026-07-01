# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Task
        # Mirrors org.operaton.bpm.client.task.ExternalTaskService. The Java
        # overloads accepting either an ExternalTask or an id are collapsed
        # into single Ruby methods that accept either.
        module ExternalTaskService
          INTERFACE_METHODS = %i[
            lock unlock complete set_variables handle_failure handle_bpmn_error extend_lock
          ].freeze
        end
      end
    end
  end
end
