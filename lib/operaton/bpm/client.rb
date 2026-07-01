# frozen_string_literal: true

# Ruby recreation of the Operaton external task client
# (org.operaton.bpm.client). The namespace mirrors the Java packages:
#
#   org.operaton.bpm.client            -> Operaton::Bpm::Client
#   org.operaton.bpm.client.impl       -> Operaton::Bpm::Client::Impl
#   org.operaton.bpm.client.task       -> Operaton::Bpm::Client::Task
#   org.operaton.bpm.client.topic      -> Operaton::Bpm::Client::Topic
#   org.operaton.bpm.client.backoff    -> Operaton::Bpm::Client::Backoff
#   org.operaton.bpm.client.variable   -> Operaton::Bpm::Client::Variable
#   org.operaton.bpm.engine.variable   -> Operaton::Bpm::Engine::Variable
#
# Exception classes from org.operaton.bpm.client.exception live directly
# under Operaton::Bpm::Client.

require_relative "client/version"
require_relative "client/exceptions"

# engine variable commons (org.operaton.bpm.engine.variable)
require_relative "engine/variable/value_type"
require_relative "engine/variable/typed_value"
require_relative "engine/variable/variable_map"
require_relative "engine/variable/variables"

# core interfaces
require_relative "client/url_resolver"
require_relative "client/external_task_client"
require_relative "client/external_task_client_builder"

# impl
require_relative "client/impl/external_task_client_logger"
require_relative "client/impl/engine_client_logger"
require_relative "client/impl/engine_client_exception"
require_relative "client/impl/engine_rest_exception_dto"
require_relative "client/impl/permanent_url_resolver"
require_relative "client/impl/request_dto"
require_relative "client/impl/object_mapper"
require_relative "client/impl/request_executor"
require_relative "client/impl/engine_client"
require_relative "client/impl/external_task_client_impl"
require_relative "client/impl/external_task_client_builder_impl"

# backoff
require_relative "client/backoff/backoff_strategy"
require_relative "client/backoff/error_aware_backoff_strategy"
require_relative "client/backoff/exponential_backoff_strategy"
require_relative "client/backoff/exponential_error_backoff_strategy"

# interceptor
require_relative "client/interceptor/client_request_context"
require_relative "client/interceptor/client_request_interceptor"
require_relative "client/interceptor/impl/client_request_context_impl"
require_relative "client/interceptor/impl/request_interceptor_handler"
require_relative "client/interceptor/auth/basic_auth_provider"

# spi
require_relative "client/spi/data_format"
require_relative "client/spi/data_format_provider"
require_relative "client/spi/data_format_configurator"

# task
require_relative "client/task/external_task"
require_relative "client/task/external_task_handler"
require_relative "client/task/external_task_service"
require_relative "client/task/ordering_config"
require_relative "client/task/sorting_dto"
require_relative "client/task/impl/external_task_impl"
require_relative "client/task/impl/external_task_service_impl"
require_relative "client/task/impl/dto/bpmn_error_request_dto"
require_relative "client/task/impl/dto/complete_request_dto"
require_relative "client/task/impl/dto/extend_lock_request_dto"
require_relative "client/task/impl/dto/failure_request_dto"
require_relative "client/task/impl/dto/lock_request_dto"
require_relative "client/task/impl/dto/set_variables_request_dto"

# topic
require_relative "client/topic/topic_subscription"
require_relative "client/topic/topic_subscription_builder"
require_relative "client/topic/impl/topic_subscription_impl"
require_relative "client/topic/impl/topic_subscription_builder_impl"
require_relative "client/topic/impl/topic_subscription_manager"
require_relative "client/topic/impl/topic_subscription_manager_logger"
require_relative "client/topic/impl/dto/fetch_and_lock_request_dto"
require_relative "client/topic/impl/dto/fetch_and_lock_response_dto"
require_relative "client/topic/impl/dto/topic_request_dto"

# variable
require_relative "client/variable/client_values"
require_relative "client/variable/value/json_value"
require_relative "client/variable/value/xml_value"
require_relative "client/variable/value/deferred_file_value"
require_relative "client/variable/impl/typed_value_field"
require_relative "client/variable/impl/typed_values"
require_relative "client/variable/impl/value_mapper"
require_relative "client/variable/impl/value_mappers"
require_relative "client/variable/impl/default_value_mappers"
require_relative "client/variable/impl/variable_value"
require_relative "client/variable/impl/abstract_typed_value_mapper"
require_relative "client/variable/impl/type/json_type_impl"
require_relative "client/variable/impl/type/xml_type_impl"
require_relative "client/variable/impl/value/json_value_impl"
require_relative "client/variable/impl/value/xml_value_impl"
require_relative "client/variable/impl/value/deferred_file_value_impl"
require_relative "client/variable/impl/mapper/primitive_value_mapper"
require_relative "client/variable/impl/mapper/number_value_mapper"
require_relative "client/variable/impl/mapper/boolean_value_mapper"
require_relative "client/variable/impl/mapper/byte_array_value_mapper"
require_relative "client/variable/impl/mapper/date_value_mapper"
require_relative "client/variable/impl/mapper/double_value_mapper"
require_relative "client/variable/impl/mapper/file_value_mapper"
require_relative "client/variable/impl/mapper/integer_value_mapper"
require_relative "client/variable/impl/mapper/json_value_mapper"
require_relative "client/variable/impl/mapper/long_value_mapper"
require_relative "client/variable/impl/mapper/null_value_mapper"
require_relative "client/variable/impl/mapper/object_value_mapper"
require_relative "client/variable/impl/mapper/short_value_mapper"
require_relative "client/variable/impl/mapper/string_value_mapper"
require_relative "client/variable/impl/mapper/xml_value_mapper"
require_relative "client/variable/impl/format/json/json_data_format"
require_relative "client/variable/impl/format/json/json_data_format_provider"
