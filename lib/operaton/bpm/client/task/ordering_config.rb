# frozen_string_literal: true

require_relative "../impl/external_task_client_logger"
require_relative "sorting_dto"

module Operaton
  module Bpm
    module Client
      module Task
        # Mirrors org.operaton.bpm.client.task.OrderingConfig
        class OrderingConfig
          module SortingField
            CREATE_TIME = "createTime"
          end

          module Direction
            ASC = "asc"
            DESC = "desc"
          end

          attr_reader :ordering_properties

          def initialize(ordering_properties)
            @ordering_properties = ordering_properties
          end

          def self.empty
            new([])
          end

          def configure_field(field)
            ordering_properties << OrderingProperty.of(field, nil)
          end

          def configure_direction_on_last_field(direction)
            last_configured_property = validate_and_get_last_configured_property
            raise logger.double_direction_config_exception unless last_configured_property.direction.nil?

            last_configured_property.direction = direction
          end

          def validate_ordering_properties
            raise logger.missing_direction_exception if ordering_properties.any? { |p| p.direction.nil? }
          end

          def to_sorting_dtos
            ordering_properties.map { |property| SortingDto.from_ordering_property(property) }
          end

          protected

          def validate_and_get_last_configured_property
            last_configured_property = ordering_properties.last
            raise logger.unspecified_order_by_method_exception if last_configured_property.nil?

            last_configured_property
          end

          def logger
            Client::Impl::ExternalTaskClientLogger.client_logger
          end

          # Mirrors OrderingConfig.OrderingProperty
          class OrderingProperty
            attr_accessor :field, :direction

            def self.of(field, direction)
              property = new
              property.field = field
              property.direction = direction
              property
            end
          end
        end
      end
    end
  end
end
