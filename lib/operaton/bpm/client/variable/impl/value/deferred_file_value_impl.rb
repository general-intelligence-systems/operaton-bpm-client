# frozen_string_literal: true

require_relative "../../../../engine/variable/typed_value"
require_relative "../../value/deferred_file_value"
require_relative "../../../impl/engine_client_exception"
require_relative "../../../impl/external_task_client_logger"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          module Value
            # Mirrors org.operaton.bpm.client.variable.impl.value.DeferredFileValueImpl
            class DeferredFileValueImpl < Engine::Variable::FileValue
              include Variable::Value::DeferredFileValue

              attr_accessor :variable_name, :execution_id

              def initialize(filename, engine_client)
                super(filename)
                @engine_client = engine_client
                @is_loaded = false
              end

              def loaded?
                @is_loaded
              end

              # Returns the file content, fetching it from the engine on first access.
              def value
                load_content unless loaded?
                super
              end

              def to_s
                "DeferredFileValueImpl [mimeType=#{mime_type}, filename=#{filename}, " \
                  "type=#{type}, isTransient=#{transient?}, isLoaded=#{loaded?}]"
              end

              protected

              def load_content
                bytes = @engine_client.get_local_binary_variable(variable_name, execution_id)
                set_value(bytes)
                @is_loaded = true
              rescue Client::Impl::EngineClientException => e
                raise Client::Impl::ExternalTaskClientLogger.client_logger
                                                            .handled_engine_client_exception("loading deferred file", e)
              end
            end
          end
        end
      end
    end
  end
end
