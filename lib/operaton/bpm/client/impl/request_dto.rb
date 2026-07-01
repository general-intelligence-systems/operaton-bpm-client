# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Impl
        # Mirrors org.operaton.bpm.client.impl.RequestDto
        class RequestDto
          attr_reader :worker_id

          def initialize(worker_id)
            @worker_id = worker_id
          end

          # Subclasses add their fields; nil values are omitted from the JSON
          # payload (Jackson NON_NULL semantics where the Java DTO uses them).
          def as_json
            { "workerId" => worker_id }
          end
        end
      end
    end
  end
end
