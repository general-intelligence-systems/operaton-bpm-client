# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Backoff
        # Mirrors org.operaton.bpm.client.backoff.BackoffStrategy
        module BackoffStrategy
          def reconfigure(external_tasks)
            raise NotImplementedError, "#{self.class} must implement #reconfigure"
          end

          def calculate_backoff_time
            raise NotImplementedError, "#{self.class} must implement #calculate_backoff_time"
          end
        end
      end
    end
  end
end
