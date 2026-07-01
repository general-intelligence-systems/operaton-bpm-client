# frozen_string_literal: true

require_relative "value_mappers"
require_relative "../../impl/external_task_client_logger"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          # Mirrors org.operaton.bpm.client.variable.impl.DefaultValueMappers
          class DefaultValueMappers
            include ValueMappers

            def initialize(default_serialization_format)
              @serializer_list = []
              @default_serialization_format = default_serialization_format
            end

            def find_mapper_for_typed_value(typed_value)
              type = typed_value.type
              raise logger.value_mapper_exception_while_serializing_abstract_value(type.name) if type&.abstract?

              matched_serializers = []
              @serializer_list.each do |serializer|
                next unless serializer.can_handle_typed_value(typed_value)

                matched_serializers << serializer
                break if serializer.type.primitive_value_type?
              end

              case matched_serializers.size
              when 1
                matched_serializers.first
              when 0
                raise logger.value_mapper_exception_due_to_serializer_not_found_for_typed_value(typed_value)
              else
                # ambiguous match, use default serializer
                matched_serializers.find { |s| s.serialization_dataformat == @default_serialization_format } ||
                  matched_serializers.first
              end
            end

            def find_mapper_for_typed_value_field(typed_value_field)
              matched_serializer = @serializer_list.find { |s| s.can_handle_typed_value_field(typed_value_field) }

              if matched_serializer.nil?
                raise logger.value_mapper_exception_due_to_serializer_not_found_for_typed_value_field(
                  typed_value_field.value
                )
              end

              matched_serializer
            end

            def add_mapper(serializer)
              @serializer_list << serializer
              self
            end

            protected

            def logger
              Client::Impl::ExternalTaskClientLogger.client_logger
            end
          end
        end
      end
    end
  end
end
