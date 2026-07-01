# frozen_string_literal: true

require_relative "typed_value"

module Operaton
  module Bpm
    module Engine
      module Variable
        # Mirrors org.operaton.bpm.engine.variable.VariableMap: a map of
        # variable names to typed values, with untyped access convenience.
        class VariableMap
          include Enumerable

          def initialize
            @map = {}
          end

          # Mirrors VariableMap#putValue
          def put_value(name, value)
            put_value_typed(name, Variables.untyped_value(value))
          end
          alias []= put_value

          # Mirrors VariableMap#putValueTyped
          def put_value_typed(name, typed_value)
            @map[name] = typed_value
            self
          end

          # Mirrors VariableMap#getValue (raw value access)
          def get_value(name)
            typed = @map[name]
            typed&.value
          end
          alias [] get_value

          # Mirrors VariableMap#getValueTyped
          def get_value_typed(name)
            @map[name]
          end

          def keys
            @map.keys
          end

          def key?(name)
            @map.key?(name)
          end

          def size
            @map.size
          end
          alias length size

          def empty?
            @map.empty?
          end

          def each
            return enum_for(:each) unless block_given?

            @map.each_key { |name| yield name, get_value(name) }
          end

          def to_h
            @map.keys.to_h { |name| [name, get_value(name)] }
          end
        end
      end
    end
  end
end
