# frozen_string_literal: true

require_relative "typed_value_field"
require_relative "variable_value"
require_relative "../../impl/external_task_client_logger"
require_relative "../../../engine/variable/variables"

module Operaton
  module Bpm
    module Client
      module Variable
        module Impl
          # Mirrors org.operaton.bpm.client.variable.impl.TypedValues
          class TypedValues
            def initialize(serializers)
              @serializers = serializers
            end

            # Serializes a Hash (or Engine::Variable::VariableMap) of variables
            # into a map of variable name => TypedValueField.
            def serialize_variables(variables)
              result = {}
              return result if variables.nil?

              if variables.is_a?(Engine::Variable::VariableMap)
                variables.keys.each do |variable_name|
                  result[variable_name] = serialize_variable(variable_name,
                                                             variables.get_value_typed(variable_name))
                end
              else
                variables.each do |variable_name, variable_value|
                  result[variable_name] = serialize_variable(variable_name, variable_value)
                end
              end

              result
            end

            # Mirrors wrapVariables: builds lazily-deserialized VariableValue
            # objects out of the raw TypedValueFields received from the engine.
            def wrap_variables(external_task, variables)
              execution_id = external_task.execution_id
              result = {}

              variables&.each do |variable_name, variable_value|
                type_name = variable_value.type
                if type_name && !type_name.empty?
                  variable_value.type = type_name[0].downcase + type_name[1..]
                end
                result[variable_name] = VariableValue.new(execution_id, variable_name, variable_value, @serializers)
              end

              result
            end

            protected

            def serialize_variable(variable_name, variable_value)
              typed_value = create_typed_value(variable_value)
              to_typed_value_field(typed_value)
            rescue StandardError => e
              raise logger.cannot_serialize_variable(variable_name, e)
            end

            def to_typed_value_field(typed_value)
              serializer = find_serializer(typed_value)

              if typed_value.is_a?(Engine::Variable::UntypedValue)
                typed_value = serializer.convert_to_typed_value(typed_value)
              end

              typed_value_field = TypedValueField.new
              serializer.write_value(typed_value, typed_value_field)

              value_type = typed_value.type
              typed_value_field.value_info = value_type.value_info(typed_value)
              type_name = value_type.name
              typed_value_field.type = type_name[0].upcase + type_name[1..]
              typed_value_field
            end

            def find_serializer(typed_value)
              @serializers.find_mapper_for_typed_value(typed_value)
            end

            def create_typed_value(value)
              return value if value.is_a?(Engine::Variable::TypedValue)

              Engine::Variable::Variables.untyped_value(value)
            end

            def logger
              Client::Impl::ExternalTaskClientLogger.client_logger
            end
          end
        end
      end
    end
  end
end

__END__

require "operaton-bpm-client"
require "base64"

# Silence client logging during tests (mirrors spec_helper)
Operaton::Bpm::Client.logger = Logger.new(File::NULL)

describe Operaton::Bpm::Client::Variable::Impl::TypedValues do
  before do
    @client = Operaton::Bpm::Client::ExternalTaskClient.create
                                                       .base_url("http://localhost:8080/engine-rest")
                                                       .disable_auto_fetching
                                                       .build
    @typed_values = @client.topic_subscription_manager.engine_client.typed_values
    @serialize = ->(value) { @typed_values.serialize_variables({ "var" => value })["var"] }
  end

  describe "serialization of untyped values" do
    it "maps nil to Null" do
      @serialize.call(nil).as_json.should == { "value" => nil, "type" => "Null", "valueInfo" => {} }
    end

    it "maps booleans to Boolean" do
      @serialize.call(false).as_json.slice("type", "value").should == { "type" => "Boolean", "value" => false }
    end

    it "maps strings to String" do
      @serialize.call("hello").as_json.slice("type", "value").should == { "type" => "String", "value" => "hello" }
    end

    it "maps 32-bit integers to Integer" do
      @serialize.call(42).as_json.slice("type", "value").should == { "type" => "Integer", "value" => 42 }
    end

    it "maps large integers to Long" do
      @serialize.call(2**40).as_json.slice("type", "value").should == { "type" => "Long", "value" => 2**40 }
    end

    it "maps floats to Double" do
      @serialize.call(1.5).as_json.slice("type", "value").should == { "type" => "Double", "value" => 1.5 }
    end

    it "maps Time to Date using the configured date format" do
      time = Time.new(2024, 5, 17, 12, 30, 45 + Rational(123, 1000), "+02:00")
      json = @serialize.call(time).as_json
      json["type"].should == "Date"
      json["value"].should == "2024-05-17T12:30:45.123+0200"
    end

    it "maps hashes to a JSON-serialized Object" do
      json = @serialize.call({ "a" => [1, 2] }).as_json
      json["type"].should == "Object"
      json["value"].should == '{"a":[1,2]}'
      json["valueInfo"].should == {
        "objectTypeName" => "Hash",
        "serializationDataFormat" => "application/json"
      }
    end
  end

  describe "serialization of explicitly typed values" do
    it "honors long_value for small numbers" do
      @serialize.call(Operaton::Bpm::Engine::Variable::Variables.long_value(1)).as_json
        .slice("type", "value").should == { "type" => "Long", "value" => 1 }
    end

    it "honors short_value" do
      @serialize.call(Operaton::Bpm::Engine::Variable::Variables.short_value(7)).as_json
        .slice("type", "value").should == { "type" => "Short", "value" => 7 }
    end

    it "serializes byte arrays base64-encoded" do
      json = @serialize.call(Operaton::Bpm::Engine::Variable::Variables.byte_array_value("bytes!")).as_json
      json["type"].should == "Bytes"
      Base64.decode64(json["value"]).should == "bytes!"
    end

    it "serializes json values as json type" do
      json = @serialize.call(Operaton::Bpm::Client::Variable::ClientValues.json_value('{"x":1}')).as_json
      json.slice("type", "value").should == { "type" => "Json", "value" => '{"x":1}' }
    end

    it "serializes xml values as xml type" do
      json = @serialize.call(Operaton::Bpm::Client::Variable::ClientValues.xml_value("<a/>")).as_json
      json.slice("type", "value").should == { "type" => "Xml", "value" => "<a/>" }
    end

    it "marks transient values in valueInfo" do
      json = @serialize.call(Operaton::Bpm::Engine::Variable::Variables.string_value("secret", true)).as_json
      json["valueInfo"].should == { "transient" => true }
    end

    it "raises for values no mapper can handle" do
      value = Operaton::Bpm::Engine::Variable::Variables.boolean_value("not a boolean")
      err = lambda { @serialize.call(value) }.should.raise(Operaton::Bpm::Client::ValueMapperException)
      err.message.should.match(/Cannot serialize variable 'var'/)
    end
  end

  describe "VariableMap support" do
    it "serializes typed values stored in a VariableMap" do
      map = Operaton::Bpm::Engine::Variable::Variables.create_variables
      map.put_value("plain", 3)
      map.put_value_typed("typed", Operaton::Bpm::Engine::Variable::Variables.long_value(3))

      result = @typed_values.serialize_variables(map)
      result["plain"].type.should == "Integer"
      result["typed"].type.should == "Long"
    end
  end

  describe "#wrap_variables (deserialization)" do
    before do
      @task = Operaton::Bpm::Client::Task::Impl::ExternalTaskImpl.new
      @task.execution_id = "execution-1"
      @wrap = lambda do |field_hash|
        fields = field_hash.transform_values do |h|
          Operaton::Bpm::Client::Variable::Impl::TypedValueField.from_json(h)
        end
        @typed_values.wrap_variables(@task, fields)
      end
    end

    it "round-trips primitive values" do
      wrapped = @wrap.call(
        "s" => { "value" => "text", "type" => "String", "valueInfo" => {} },
        "i" => { "value" => 42, "type" => "Integer", "valueInfo" => {} },
        "b" => { "value" => true, "type" => "Boolean", "valueInfo" => {} },
        "n" => { "value" => nil, "type" => "Null", "valueInfo" => {} }
      )
      wrapped["s"].value.should == "text"
      wrapped["i"].value.should == 42
      wrapped["b"].value.should == true
      wrapped["n"].value.should.be.nil
    end

    it "deserializes JSON object values lazily" do
      wrapped = @wrap.call(
        "o" => { "value" => '{"k":"v"}', "type" => "Object",
                 "valueInfo" => { "objectTypeName" => "Hash",
                                  "serializationDataFormat" => "application/json" } }
      )
      typed = wrapped["o"].typed_value
      typed.should.be.deserialized
      typed.value.should == { "k" => "v" }
      wrapped["o"].value.should == { "k" => "v" }
    end

    it "returns the serialized form when deserialization is not requested" do
      wrapped = @wrap.call(
        "o" => { "value" => '{"k":"v"}', "type" => "Object",
                 "valueInfo" => { "objectTypeName" => "Hash",
                                  "serializationDataFormat" => "application/json" } }
      )
      typed = wrapped["o"].typed_value(false)
      typed.should.not.be.deserialized
      typed.value_serialized.should == '{"k":"v"}'
    end

    it "parses date values with the configured format" do
      wrapped = @wrap.call(
        "d" => { "value" => "2024-05-17T12:30:45.123+0200", "type" => "Date", "valueInfo" => {} }
      )
      wrapped["d"].value.should.be.kind_of(Time)
      wrapped["d"].value.year.should == 2024
    end

    it "decodes byte values from base64" do
      wrapped = @wrap.call(
        "raw" => { "value" => Base64.strict_encode64("bin"), "type" => "Bytes", "valueInfo" => {} }
      )
      wrapped["raw"].value.should == "bin"
    end

    it "wraps json values with the json type" do
      wrapped = @wrap.call(
        "j" => { "value" => "[1,2]", "type" => "Json", "valueInfo" => {} }
      )
      typed = wrapped["j"].typed_value
      typed.type.name.should == "json"
      typed.value.should == "[1,2]"
    end
  end
end
