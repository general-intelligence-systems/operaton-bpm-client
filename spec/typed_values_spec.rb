# frozen_string_literal: true

require "spec_helper"

RSpec.describe Operaton::Bpm::Client::Variable::Impl::TypedValues do
  let(:client_module) { Operaton::Bpm::Client }
  let(:variables_module) { Operaton::Bpm::Engine::Variable::Variables }
  let(:client_values) { client_module::Variable::ClientValues }

  let(:client) do
    client_module::ExternalTaskClient.create
                                     .base_url("http://localhost:8080/engine-rest")
                                     .disable_auto_fetching
                                     .build
  end
  let(:typed_values) { client.topic_subscription_manager.engine_client.typed_values }

  def serialize(value)
    typed_values.serialize_variables({ "var" => value })["var"]
  end

  describe "serialization of untyped values" do
    it "maps nil to Null" do
      expect(serialize(nil).as_json).to eq("value" => nil, "type" => "Null", "valueInfo" => {})
    end

    it "maps booleans to Boolean" do
      expect(serialize(false).as_json).to include("type" => "Boolean", "value" => false)
    end

    it "maps strings to String" do
      expect(serialize("hello").as_json).to include("type" => "String", "value" => "hello")
    end

    it "maps 32-bit integers to Integer" do
      expect(serialize(42).as_json).to include("type" => "Integer", "value" => 42)
    end

    it "maps large integers to Long" do
      expect(serialize(2**40).as_json).to include("type" => "Long", "value" => 2**40)
    end

    it "maps floats to Double" do
      expect(serialize(1.5).as_json).to include("type" => "Double", "value" => 1.5)
    end

    it "maps Time to Date using the configured date format" do
      time = Time.new(2024, 5, 17, 12, 30, 45 + Rational(123, 1000), "+02:00")
      json = serialize(time).as_json
      expect(json["type"]).to eq("Date")
      expect(json["value"]).to eq("2024-05-17T12:30:45.123+0200")
    end

    it "maps hashes to a JSON-serialized Object" do
      json = serialize({ "a" => [1, 2] }).as_json
      expect(json["type"]).to eq("Object")
      expect(json["value"]).to eq('{"a":[1,2]}')
      expect(json["valueInfo"]).to eq(
        "objectTypeName" => "Hash",
        "serializationDataFormat" => "application/json"
      )
    end
  end

  describe "serialization of explicitly typed values" do
    it "honors long_value for small numbers" do
      expect(serialize(variables_module.long_value(1)).as_json).to include("type" => "Long", "value" => 1)
    end

    it "honors short_value" do
      expect(serialize(variables_module.short_value(7)).as_json).to include("type" => "Short", "value" => 7)
    end

    it "serializes byte arrays base64-encoded" do
      json = serialize(variables_module.byte_array_value("bytes!")).as_json
      expect(json["type"]).to eq("Bytes")
      expect(Base64.decode64(json["value"])).to eq("bytes!")
    end

    it "serializes json values as json type" do
      json = serialize(client_values.json_value('{"x":1}')).as_json
      expect(json).to include("type" => "Json", "value" => '{"x":1}')
    end

    it "serializes xml values as xml type" do
      json = serialize(client_values.xml_value("<a/>")).as_json
      expect(json).to include("type" => "Xml", "value" => "<a/>")
    end

    it "marks transient values in valueInfo" do
      json = serialize(variables_module.string_value("secret", true)).as_json
      expect(json["valueInfo"]).to eq("transient" => true)
    end

    it "raises for values no mapper can handle" do
      value = variables_module.boolean_value("not a boolean")
      expect { serialize(value) }
        .to raise_error(client_module::ValueMapperException, /Cannot serialize variable 'var'/)
    end
  end

  describe "VariableMap support" do
    it "serializes typed values stored in a VariableMap" do
      map = variables_module.create_variables
      map.put_value("plain", 3)
      map.put_value_typed("typed", variables_module.long_value(3))

      result = typed_values.serialize_variables(map)
      expect(result["plain"].type).to eq("Integer")
      expect(result["typed"].type).to eq("Long")
    end
  end

  describe "#wrap_variables (deserialization)" do
    let(:task) do
      task = client_module::Task::Impl::ExternalTaskImpl.new
      task.execution_id = "execution-1"
      task
    end

    def wrap(field_hash)
      fields = field_hash.transform_values { |h| client_module::Variable::Impl::TypedValueField.from_json(h) }
      typed_values.wrap_variables(task, fields)
    end

    it "round-trips primitive values" do
      wrapped = wrap(
        "s" => { "value" => "text", "type" => "String", "valueInfo" => {} },
        "i" => { "value" => 42, "type" => "Integer", "valueInfo" => {} },
        "b" => { "value" => true, "type" => "Boolean", "valueInfo" => {} },
        "n" => { "value" => nil, "type" => "Null", "valueInfo" => {} }
      )
      expect(wrapped["s"].value).to eq("text")
      expect(wrapped["i"].value).to eq(42)
      expect(wrapped["b"].value).to be(true)
      expect(wrapped["n"].value).to be_nil
    end

    it "deserializes JSON object values lazily" do
      wrapped = wrap(
        "o" => { "value" => '{"k":"v"}', "type" => "Object",
                 "valueInfo" => { "objectTypeName" => "Hash",
                                  "serializationDataFormat" => "application/json" } }
      )
      typed = wrapped["o"].typed_value
      expect(typed).to be_deserialized
      expect(typed.value).to eq("k" => "v")
      expect(wrapped["o"].value).to eq("k" => "v")
    end

    it "returns the serialized form when deserialization is not requested" do
      wrapped = wrap(
        "o" => { "value" => '{"k":"v"}', "type" => "Object",
                 "valueInfo" => { "objectTypeName" => "Hash",
                                  "serializationDataFormat" => "application/json" } }
      )
      typed = wrapped["o"].typed_value(false)
      expect(typed).not_to be_deserialized
      expect(typed.value_serialized).to eq('{"k":"v"}')
    end

    it "parses date values with the configured format" do
      wrapped = wrap(
        "d" => { "value" => "2024-05-17T12:30:45.123+0200", "type" => "Date", "valueInfo" => {} }
      )
      expect(wrapped["d"].value).to be_a(Time)
      expect(wrapped["d"].value.year).to eq(2024)
    end

    it "decodes byte values from base64" do
      wrapped = wrap(
        "raw" => { "value" => Base64.strict_encode64("bin"), "type" => "Bytes", "valueInfo" => {} }
      )
      expect(wrapped["raw"].value).to eq("bin")
    end

    it "wraps json values with the json type" do
      wrapped = wrap(
        "j" => { "value" => "[1,2]", "type" => "Json", "valueInfo" => {} }
      )
      typed = wrapped["j"].typed_value
      expect(typed.type.name).to eq("json")
      expect(typed.value).to eq("[1,2]")
    end
  end
end
