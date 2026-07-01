# frozen_string_literal: true

require_relative "backoff_strategy"

module Operaton
  module Bpm
    module Client
      module Backoff
        # Mirrors org.operaton.bpm.client.backoff.ErrorAwareBackoffStrategy.
        # Implementations receive the exception (or nil) of the last
        # fetch-and-lock attempt in addition to the fetched tasks.
        module ErrorAwareBackoffStrategy
          include BackoffStrategy

          def reconfigure(external_tasks, exception = nil)
            raise NotImplementedError, "#{self.class} must implement #reconfigure"
          end
        end
      end
    end
  end
end
