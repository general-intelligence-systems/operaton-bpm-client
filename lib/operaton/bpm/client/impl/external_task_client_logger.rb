# frozen_string_literal: true

require "logger"
require_relative "../exceptions"

module Operaton
  module Bpm
    module Client
      class << self
        # Library-wide logger, mirroring the "org.operaton.bpm.client" SLF4J logger.
        attr_writer :logger

        def logger
          @logger ||= Logger.new($stderr, progname: "org.operaton.bpm.client")
        end
      end

      module Impl
        # Mirrors org.operaton.bpm.client.impl.ExternalTaskClientLogger
        class ExternalTaskClientLogger
          PROJECT_CODE = "TASK/CLIENT"

          def self.client_logger
            @client_logger ||= new("01")
          end

          def self.engine_client_logger
            @engine_client_logger ||= EngineClientLogger.new("02")
          end

          def self.topic_subscription_manager_logger
            @topic_subscription_manager_logger ||= Topic::Impl::TopicSubscriptionManagerLogger.new("03")
          end

          def initialize(component_id)
            @component_id = component_id
          end

          def exception_message(id, message_template, *args)
            "#{PROJECT_CODE}-#{@component_id}#{id} #{format_template(message_template, *args)}"
          end

          def format_template(template, *args)
            args.reduce(template) { |msg, arg| msg.sub("{}", arg.to_s) }
          end

          def log_error(id, message_template, error = nil, *args)
            msg = exception_message(id, message_template, *args)
            msg += " : #{error.class}: #{error.message}" if error
            Client.logger.error(msg)
          end

          def log_info(id, message_template, *args)
            Client.logger.info(exception_message(id, message_template, *args))
          end

          def log_debug(id, message_template, *args)
            Client.logger.debug(exception_message(id, message_template, *args))
          end

          def base_url_null_exception
            ExternalTaskClientException.new(exception_message(
              "001", "Base URL cannot be null or an empty string"))
          end

          def cannot_get_hostname_exception(cause)
            ExternalTaskClientException.new(exception_message("002", "Cannot get hostname"), cause)
          end

          def double_direction_config_exception
            ExternalTaskClientException.new(
              "Invalid query: can specify only one direction desc() or asc() for an ordering constraint")
          end

          def unspecified_order_by_method_exception
            ExternalTaskClientException.new(
              "Invalid query: You should call any of the orderBy methods first before specifying a direction")
          end

          def missing_direction_exception
            ExternalTaskClientException.new(
              "Invalid query: call asc() or desc() after using orderByXX()")
          end

          def topic_name_null_exception
            ExternalTaskClientException.new(exception_message(
              "003", "Topic name cannot be null"))
          end

          def lock_duration_is_not_greater_than_zero_exception(lock_duration)
            ExternalTaskClientException.new(exception_message(
              "004", "Lock duration must be greater than 0, but was '{}'", lock_duration))
          end

          def external_task_handler_null_exception
            ExternalTaskClientException.new(exception_message(
              "005", "External task handler cannot be null"))
          end

          def topic_name_already_subscribed_exception(topic_name)
            ExternalTaskClientException.new(exception_message(
              "006", "Topic name '{}' has already been subscribed", topic_name))
          end

          # Mirrors handledEngineClientException: maps EngineClientException
          # causes to the public exception hierarchy.
          def handled_engine_client_exception(action_name, error)
            caused = error.cause

            if caused.is_a?(RestException)
              message = caused.message
              status = caused.http_status_code

              return case status
                     when 400 then BadRequestException.new(create_message("007", action_name, message), caused)
                     when 404 then NotFoundException.new(create_message("008", action_name, message), caused)
                     when 500 then EngineException.new(create_message("009", action_name, message), caused)
                     else
                       UnknownHttpErrorException.new(exception_message(
                         "031", "Exception while {}: The request failed with status code {} and message: \"{}\"",
                         action_name, status, message), caused)
                     end
            end

            if io_error?(caused)
              return ConnectionLostException.new(exception_message(
                "010", "Exception while {}: Connection could not be established with message: \"{}\"",
                action_name, caused.message), caused)
            end

            ExternalTaskClientException.new(exception_message(
              "011", "Exception while {}: ", action_name), error)
          end

          def create_message(id, action_name, message)
            exception_message(id, "Exception while {}: {}", action_name, message)
          end

          def basic_auth_credentials_null_exception
            ExternalTaskClientException.new(exception_message(
              "012", "Basic authentication credentials (username, password) cannot be null"))
          end

          def interceptor_null_exception
            ExternalTaskClientException.new(exception_message(
              "013", "Interceptor cannot be null"))
          end

          def max_tasks_not_greater_than_zero_exception(max_tasks)
            ExternalTaskClientException.new(exception_message(
              "014", "Maximum amount of fetched tasks must be greater than zero, but was '{}'", max_tasks))
          end

          def async_response_timeout_not_greater_than_zero_exception(async_response_timeout)
            ExternalTaskClientException.new(exception_message(
              "015", "Asynchronous response timeout must be greater than zero, but was '{}'", async_response_timeout))
          end

          def value_mapper_exception_while_parsing_date(date, error)
            ValueMapperException.new(exception_message(
              "018", "Exception while mapping value: Cannot parse date '{}'", date), error)
          end

          def value_mapper_exception_due_to_no_object_type_name
            ValueMapperException.new(exception_message(
              "019", "Exception while mapping value: " \
                     "Cannot write serialized value for variable: no 'objectTypeName' provided for non-null value."))
          end

          def value_mapper_exception_while_serializing_object(error)
            ValueMapperException.new(exception_message(
              "020", "Exception while mapping value: Cannot serialize object in variable."), error)
          end

          def value_mapper_exception_while_deserializing_object(error)
            ValueMapperException.new(exception_message(
              "021", "Exception while mapping value: Cannot deserialize object in variable."), error)
          end

          def value_mapper_exception_while_serializing_abstract_value(name)
            ValueMapperException.new(exception_message(
              "022", "Cannot serialize value of abstract type '{}'", name))
          end

          def value_mapper_exception_due_to_serializer_not_found_for_typed_value(typed_value)
            ValueMapperException.new(exception_message(
              "023", "Cannot find serializer for value '{}'", typed_value))
          end

          def value_mapper_exception_due_to_serializer_not_found_for_typed_value_field(value)
            ValueMapperException.new(exception_message(
              "024", "Cannot find serializer for value '{}'", value))
          end

          def cannot_serialize_variable(variable_name, error)
            ValueMapperException.new(exception_message(
              "025", "Cannot serialize variable '{}'", variable_name), error)
          end

          def log_data_format_provider(provider)
            log_info("026", "Discovered data format provider: {}[name = {}]",
                     provider.class.name, provider.data_format_name)
          end

          def log_data_format(data_format)
            log_info("025", "Discovered data format: {}[name = {}]", data_format.class.name, data_format.name)
          end

          def log_data_format_configurator(configurator)
            log_info("027", "Discovered data format configurator: {}[dataformat = {}]",
                     configurator.class.name, configurator.data_format_class.name)
          end

          def multiple_providers_for_dataformat(data_format_name)
            ExternalTaskClientException.new(exception_message(
              "028", "Multiple providers found for dataformat '{}'", data_format_name))
          end

          def pass_null_value_parameter(parameter_name)
            ExternalTaskClientException.new(exception_message(
              "030", "Null value is not allowed as '{}'", parameter_name))
          end

          private

          def io_error?(error)
            error.is_a?(IOError) || error.is_a?(SystemCallError) || error.is_a?(SocketError) ||
              error.is_a?(Timeout::Error) || error.is_a?(OpenSSL::SSL::SSLError)
          rescue NameError
            error.is_a?(IOError) || error.is_a?(SystemCallError)
          end
        end
      end
    end
  end
end
