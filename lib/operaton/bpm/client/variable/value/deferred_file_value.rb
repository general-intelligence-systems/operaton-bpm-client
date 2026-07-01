# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Variable
        module Value
          # Mirrors org.operaton.bpm.client.variable.value.DeferredFileValue —
          # a file value whose content is lazily fetched from the engine.
          module DeferredFileValue
            def loaded?
              raise NotImplementedError
            end
          end
        end
      end
    end
  end
end
