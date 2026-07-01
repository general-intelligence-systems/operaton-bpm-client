# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      # Mirrors org.operaton.bpm.client.UrlResolver. Any object responding to
      # #base_url can act as a URL resolver.
      module UrlResolver
        def base_url
          raise NotImplementedError, "#{self.class} must implement #base_url"
        end
      end
    end
  end
end
