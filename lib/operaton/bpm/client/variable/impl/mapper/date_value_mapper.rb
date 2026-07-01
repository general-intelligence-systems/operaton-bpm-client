# frozen_string_literal: true

require "time"
require_relative "primitive_value_mapper"
require_relative "../../../../engine/variable/variables"
require_relative "../../../impl/external_task_client_logger"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Mapper
            # Mirrors org.operaton.bpm.client.variable.impl.mapper.DateValueMapper.
            # The date format is a Ruby strftime pattern.
            class DateValueMapper < PrimitiveValueMapper
              def initialize(date_format)
                super(Engine::Variable::ValueType::DATE)
                @date_format = date_format
              end

              def convert_to_typed_value(untyped_value)
                Engine::Variable::Variables.date_value(to_time(untyped_value.value))
              end

              def read_typed_value(typed_value_field)
                date = nil
                value = typed_value_field.value
                unless value.nil?
                  begin
                    date = Time.strptime(value, @date_format)
                  rescue ArgumentError => e
                    raise Client::Impl::ExternalTaskClientLogger.client_logger
                                                                .value_mapper_exception_while_parsing_date(value, e)
                  end
                end
                Engine::Variable::Variables.date_value(date)
              end

              def write_value(date_value, typed_value_field)
                date = date_value.value
                typed_value_field.value = to_time(date).strftime(@date_format) unless date.nil?
              end

              protected

              def can_read_value(typed_value_field)
                value = typed_value_field.value
                value.nil? || value.is_a?(String)
              end

              def to_time(value)
                value.is_a?(Time) ? value : value.to_time
              end
            end
          end
        end
      end
    end
  end
end
