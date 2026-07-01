# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      # Mirrors org.operaton.bpm.client.ExternalTaskClient. The static create()
      # factory returns a fluent builder; the built client is an
      # Impl::ExternalTaskClientImpl responding to #subscribe, #start, #stop
      # and #active?.
      module ExternalTaskClient
        # Creates a fluent builder to configure the Operaton client.
        def self.create
          Impl::ExternalTaskClientBuilderImpl.new
        end
      end
    end
  end
end

require_relative "impl/external_task_client_builder_impl"
