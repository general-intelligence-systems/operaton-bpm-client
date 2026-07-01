# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Topic
        # Mirrors org.operaton.bpm.client.topic.TopicSubscription. Documents
        # the contract implemented by Topic::Impl::TopicSubscriptionImpl.
        module TopicSubscription
          INTERFACE_METHODS = %i[
            close topic_name lock_duration external_task_handler variable_names
            local_variables? business_key process_definition_id process_definition_id_in
            process_definition_key process_definition_key_in process_definition_version_tag
            process_variables without_tenant_id? tenant_id_in include_extension_properties?
          ].freeze
        end
      end
    end
  end
end
