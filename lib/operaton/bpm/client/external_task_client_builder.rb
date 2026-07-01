# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      # Mirrors org.operaton.bpm.client.ExternalTaskClientBuilder. Documents
      # the fluent contract implemented by Impl::ExternalTaskClientBuilderImpl.
      module ExternalTaskClientBuilder
        INTERFACE_METHODS = %i[
          base_url url_resolver worker_id add_interceptor max_tasks use_priority
          use_create_time order_by_create_time asc desc default_serialization_format
          date_format async_response_timeout lock_duration disable_auto_fetching
          backoff_strategy disable_backoff_strategy customize_http_client build
        ].freeze
      end
    end
  end
end
