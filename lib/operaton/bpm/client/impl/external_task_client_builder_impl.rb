# frozen_string_literal: true

require "socket"
require "securerandom"

require_relative "../external_task_client_builder"
require_relative "external_task_client_logger"
require_relative "external_task_client_impl"
require_relative "permanent_url_resolver"
require_relative "object_mapper"
require_relative "engine_client"
require_relative "request_executor"
require_relative "../backoff/exponential_backoff_strategy"
require_relative "../interceptor/impl/request_interceptor_handler"
require_relative "../task/ordering_config"
require_relative "../topic/impl/topic_subscription_manager"
require_relative "../spi/data_format_provider"
require_relative "../spi/data_format_configurator"
require_relative "../variable/client_values"
require_relative "../variable/impl/default_value_mappers"
require_relative "../variable/impl/typed_values"
require_relative "../variable/impl/mapper/boolean_value_mapper"
require_relative "../variable/impl/mapper/byte_array_value_mapper"
require_relative "../variable/impl/mapper/date_value_mapper"
require_relative "../variable/impl/mapper/double_value_mapper"
require_relative "../variable/impl/mapper/file_value_mapper"
require_relative "../variable/impl/mapper/integer_value_mapper"
require_relative "../variable/impl/mapper/json_value_mapper"
require_relative "../variable/impl/mapper/long_value_mapper"
require_relative "../variable/impl/mapper/null_value_mapper"
require_relative "../variable/impl/mapper/object_value_mapper"
require_relative "../variable/impl/mapper/short_value_mapper"
require_relative "../variable/impl/mapper/string_value_mapper"
require_relative "../variable/impl/mapper/xml_value_mapper"
require_relative "../variable/impl/format/json/json_data_format_provider"

module Operaton
  module Bpm
    module Client
      module Impl
        # Mirrors org.operaton.bpm.client.impl.ExternalTaskClientBuilderImpl
        class ExternalTaskClientBuilderImpl
          include ExternalTaskClientBuilder

          attr_reader :object_mapper, :value_mappers, :typed_values, :engine_client

          def initialize
            # default values
            @worker_id = nil
            @max_tasks = 10
            @use_priority = true
            @ordering_config = Task::OrderingConfig.empty
            @async_response_timeout = nil
            @lock_duration = 20_000
            @default_serialization_format = Engine::Variable::Variables::SerializationDataFormats::JSON
            @date_format = ObjectMapper::DEFAULT_DATE_FORMAT
            @interceptors = []
            @is_auto_fetching_enabled = true
            @backoff_strategy = Backoff::ExponentialBackoffStrategy.new
            @is_backoff_strategy_disabled = false
            @http_customizer = nil
            @url_resolver = PermanentUrlResolver.new(nil)
            @object_mapper = nil
            @value_mappers = nil
            @typed_values = nil
            @engine_client = nil
            @topic_subscription_manager = nil
          end

          def base_url(base_url)
            @url_resolver = PermanentUrlResolver.new(base_url)
            self
          end

          def url_resolver(url_resolver)
            @url_resolver = url_resolver
            self
          end

          def worker_id(worker_id)
            @worker_id = worker_id
            self
          end

          def add_interceptor(interceptor)
            @interceptors << interceptor
            self
          end

          def max_tasks(max_tasks)
            @max_tasks = max_tasks
            self
          end

          def use_priority(use_priority)
            @use_priority = use_priority
            self
          end

          def use_create_time(use_create_time)
            if use_create_time
              @ordering_config.configure_field(Task::OrderingConfig::SortingField::CREATE_TIME)
              @ordering_config.configure_direction_on_last_field(Task::OrderingConfig::Direction::DESC)
            end
            self
          end

          def order_by_create_time
            @ordering_config.configure_field(Task::OrderingConfig::SortingField::CREATE_TIME)
            self
          end

          def asc
            @ordering_config.configure_direction_on_last_field(Task::OrderingConfig::Direction::ASC)
            self
          end

          def desc
            @ordering_config.configure_direction_on_last_field(Task::OrderingConfig::Direction::DESC)
            self
          end

          def async_response_timeout(async_response_timeout)
            @async_response_timeout = async_response_timeout
            self
          end

          def lock_duration(lock_duration)
            @lock_duration = lock_duration
            self
          end

          def disable_auto_fetching
            @is_auto_fetching_enabled = false
            self
          end

          def backoff_strategy(backoff_strategy)
            @backoff_strategy = backoff_strategy
            self
          end

          def disable_backoff_strategy
            @is_backoff_strategy_disabled = true
            self
          end

          def default_serialization_format(default_serialization_format)
            @default_serialization_format = default_serialization_format
            self
          end

          # A Ruby strftime pattern (default "%Y-%m-%dT%H:%M:%S.%L%z", the
          # equivalent of the Java client's "yyyy-MM-dd'T'HH:mm:ss.SSSZ").
          def date_format(date_format)
            @date_format = date_format
            self
          end

          # Accepts a block invoked with the Net::HTTP instance of every request.
          def customize_http_client(customizer = nil, &block)
            @http_customizer = customizer || block
            self
          end

          def build
            raise logger.max_tasks_not_greater_than_zero_exception(@max_tasks) if @max_tasks <= 0

            if !@async_response_timeout.nil? && @async_response_timeout <= 0
              raise logger.async_response_timeout_not_greater_than_zero_exception(@async_response_timeout)
            end

            raise logger.lock_duration_is_not_greater_than_zero_exception(@lock_duration) if @lock_duration <= 0

            raise logger.base_url_null_exception if @url_resolver.nil? || get_base_url.nil? || get_base_url.empty?

            check_interceptors
            @ordering_config.validate_ordering_properties

            init_base_url
            init_worker_id
            init_object_mapper
            init_engine_client
            init_variable_mappers
            init_topic_subscription_manager

            ExternalTaskClientImpl.new(@topic_subscription_manager)
          end

          def get_base_url # rubocop:disable Naming/AccessorMethodName
            @url_resolver.base_url
          end

          def get_default_serialization_format # rubocop:disable Naming/AccessorMethodName
            @default_serialization_format
          end

          def get_date_format # rubocop:disable Naming/AccessorMethodName
            @date_format
          end

          protected

          def init_base_url
            @url_resolver.base_url = sanitize_url(@url_resolver.base_url) if @url_resolver.is_a?(PermanentUrlResolver)
          end

          def sanitize_url(url)
            url.strip.sub(%r{/+\z}, "")
          end

          def init_worker_id
            return unless @worker_id.nil?

            hostname = check_hostname
            @worker_id = "#{hostname}#{SecureRandom.uuid}"
          end

          def check_interceptors
            @interceptors.each do |interceptor|
              raise logger.interceptor_null_exception if interceptor.nil?
            end
          end

          def init_object_mapper
            @object_mapper = ObjectMapper.new(@date_format)
          end

          def init_engine_client
            request_interceptor_handler = Interceptor::Impl::RequestInterceptorHandler.new(@interceptors)
            request_executor = RequestExecutor.new(
              @object_mapper,
              interceptor_handler: request_interceptor_handler,
              http_customizer: @http_customizer,
              read_timeout: compute_read_timeout
            )
            @engine_client = EngineClient.new(@worker_id, @max_tasks, @async_response_timeout, @url_resolver,
                                              request_executor, @use_priority, @ordering_config)
          end

          def init_variable_mappers
            @value_mappers = Variable::Impl::DefaultValueMappers.new(@default_serialization_format)

            @value_mappers.add_mapper(Variable::Impl::Mapper::NullValueMapper.new)
            @value_mappers.add_mapper(Variable::Impl::Mapper::BooleanValueMapper.new)
            @value_mappers.add_mapper(Variable::Impl::Mapper::StringValueMapper.new)
            @value_mappers.add_mapper(Variable::Impl::Mapper::DateValueMapper.new(@date_format))
            @value_mappers.add_mapper(Variable::Impl::Mapper::ByteArrayValueMapper.new)

            # number mappers
            @value_mappers.add_mapper(Variable::Impl::Mapper::IntegerValueMapper.new)
            @value_mappers.add_mapper(Variable::Impl::Mapper::LongValueMapper.new)
            @value_mappers.add_mapper(Variable::Impl::Mapper::ShortValueMapper.new)
            @value_mappers.add_mapper(Variable::Impl::Mapper::DoubleValueMapper.new)

            # object
            lookup_data_formats.each do |key, format|
              @value_mappers.add_mapper(Variable::Impl::Mapper::ObjectValueMapper.new(key, format))
            end

            # json/xml
            @value_mappers.add_mapper(Variable::Impl::Mapper::JsonValueMapper.new)
            @value_mappers.add_mapper(Variable::Impl::Mapper::XmlValueMapper.new)

            # file
            @value_mappers.add_mapper(Variable::Impl::Mapper::FileValueMapper.new(@engine_client))

            @typed_values = Variable::Impl::TypedValues.new(@value_mappers)
            @engine_client.typed_values = @typed_values
          end

          def init_topic_subscription_manager
            @topic_subscription_manager = Topic::Impl::TopicSubscriptionManager.new(
              @engine_client, @typed_values, @lock_duration
            )
            @topic_subscription_manager.backoff_strategy = @backoff_strategy
            @topic_subscription_manager.disable_backoff_strategy if @is_backoff_strategy_disabled
            @topic_subscription_manager.start if auto_fetching_enabled?
          end

          def lookup_data_formats
            data_formats = {}
            lookup_custom_data_formats(data_formats)
            apply_configurators(data_formats)
            data_formats
          end

          def lookup_custom_data_formats(data_formats)
            Spi::DataFormatProvider.providers.each do |provider|
              logger.log_data_format_provider(provider)
              lookup_provider(data_formats, provider)
            end
          end

          def lookup_provider(data_formats, provider)
            data_format_name = provider.data_format_name
            raise logger.multiple_providers_for_dataformat(data_format_name) if data_formats.key?(data_format_name)

            data_format_instance = provider.create_instance
            data_formats[data_format_name] = data_format_instance
            logger.log_data_format(data_format_instance)
          end

          def apply_configurators(data_formats)
            Spi::DataFormatConfigurator.configurators.each do |configurator|
              logger.log_data_format_configurator(configurator)
              apply_configurator(data_formats, configurator)
            end
          end

          def apply_configurator(data_formats, configurator)
            data_formats.each_value do |data_format|
              configurator.configure(data_format) if data_format.is_a?(configurator.data_format_class)
            end
          end

          def check_hostname
            hostname = get_hostname
            raise logger.cannot_get_hostname_exception(nil) if hostname.nil? || hostname.empty?

            hostname
          rescue StandardError => e
            raise logger.cannot_get_hostname_exception(e)
          end

          def get_hostname # rubocop:disable Naming/AccessorMethodName
            Socket.gethostname
          end

          def auto_fetching_enabled?
            @is_auto_fetching_enabled
          end

          def compute_read_timeout
            if @async_response_timeout
              (@async_response_timeout / 1000.0) + 30
            else
              60
            end
          end

          def logger
            ExternalTaskClientLogger.client_logger
          end
        end
      end
    end
  end
end
