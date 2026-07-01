# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Topic
        # Mirrors org.operaton.bpm.client.topic.TopicSubscriptionBuilder.
        # Documents the fluent contract implemented by
        # Topic::Impl::TopicSubscriptionBuilderImpl.
        module TopicSubscriptionBuilder
          INTERFACE_METHODS = %i[
            lock_duration handler variables local_variables business_key
            process_definition_id process_definition_id_in process_definition_key
            process_definition_key_in process_definition_version_tag
            process_variables_equals_in process_variable_equals without_tenant_id
            tenant_id_in include_extension_properties open
          ].freeze
        end
      end
    end
  end
end
