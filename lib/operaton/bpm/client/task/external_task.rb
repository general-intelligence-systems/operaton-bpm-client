# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Task
        # Mirrors org.operaton.bpm.client.task.ExternalTask. Documents the
        # contract implemented by Task::Impl::ExternalTaskImpl.
        module ExternalTask
          INTERFACE_METHODS = %i[
            activity_id activity_instance_id error_message error_details
            execution_id id lock_expiration_time create_time
            process_definition_id process_definition_key process_definition_version_tag
            process_instance_id retries worker_id topic_name tenant_id priority
            variable variable_typed all_variables all_variables_typed
            business_key extension_property extension_properties
          ].freeze
        end
      end
    end
  end
end
