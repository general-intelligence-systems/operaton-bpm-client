# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Task
        # Mirrors org.operaton.bpm.client.task.SortingDto
        class SortingDto
          attr_accessor :sort_by, :sort_order

          def self.of(sort_by, sort_order)
            dto = new
            dto.sort_by = sort_by
            dto.sort_order = sort_order
            dto
          end

          def self.from_ordering_property(property)
            of(property.field, property.direction)
          end

          def as_json
            { "sortBy" => sort_by, "sortOrder" => sort_order }
          end
        end
      end
    end
  end
end
