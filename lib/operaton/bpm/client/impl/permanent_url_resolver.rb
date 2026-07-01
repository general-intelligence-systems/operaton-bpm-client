# frozen_string_literal: true

require_relative "../url_resolver"

module Operaton
  module Bpm
    module Client
      module Impl
        # Mirrors org.operaton.bpm.client.impl.PermanentUrlResolver
        class PermanentUrlResolver
          include UrlResolver

          attr_accessor :base_url

          def initialize(base_url)
            @base_url = base_url
          end
        end
      end
    end
  end
end
