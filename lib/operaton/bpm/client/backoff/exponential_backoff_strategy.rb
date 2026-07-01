# frozen_string_literal: true

require_relative "backoff_strategy"

module Operaton
  module Bpm
    module Client
      module Backoff
        # Mirrors org.operaton.bpm.client.backoff.ExponentialBackoffStrategy
        class ExponentialBackoffStrategy
          include BackoffStrategy

          def initialize(init_time = 500, factor = 2, max_time = 60_000)
            @init_time = init_time
            @factor = factor
            @level = 0
            @max_time = max_time
          end

          def reconfigure(external_tasks)
            if external_tasks.empty?
              @level += 1
            else
              @level = 0
            end
          end

          def calculate_backoff_time
            return 0 if @level.zero?

            backoff_time = (@init_time * (@factor**(@level - 1))).to_i
            [backoff_time, @max_time].min
          end
        end
      end
    end
  end
end
