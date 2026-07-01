# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          # Mirrors org.operaton.bpm.client.variable.impl.ValueMappers
          module ValueMappers
            def find_mapper_for_typed_value(typed_value)
              raise NotImplementedError
            end

            def find_mapper_for_typed_value_field(typed_value_field)
              raise NotImplementedError
            end

            def add_mapper(mapper)
              raise NotImplementedError
            end
          end
        end
      end
    end
  end
end
