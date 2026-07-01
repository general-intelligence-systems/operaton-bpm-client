# frozen_string_literal: true

require_relative "../exceptions"

module Operaton
  module Bpm
    module Client
      module Impl
        # Mirrors org.operaton.bpm.client.impl.EngineRestExceptionDto
        class EngineRestExceptionDto
          attr_accessor :message, :type, :code

          def self.from_json(hash)
            dto = new
            dto.message = hash["message"]
            dto.type = hash["type"]
            dto.code = hash["code"]
            dto
          end

          def to_rest_exception
            RestException.new(message, type, code)
          end
        end
      end
    end
  end
end
