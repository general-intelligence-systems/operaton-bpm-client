# frozen_string_literal: true

require_relative "../external_task"
require_relative "../../variable/impl/typed_value_field"
require_relative "../../../engine/variable/variable_map"

module Operaton
  module Bpm
    module Client
      module Task
        module Impl
          # Mirrors org.operaton.bpm.client.task.impl.ExternalTaskImpl
          class ExternalTaskImpl
            include ExternalTask

            attr_accessor :activity_id, :activity_instance_id, :error_message, :error_details,
                          :execution_id, :id, :lock_expiration_time, :create_time,
                          :process_definition_id, :process_definition_key,
                          :process_definition_version_tag, :process_instance_id, :retries,
                          :worker_id, :topic_name, :tenant_id, :priority, :variables,
                          :business_key, :received_variable_map

            def self.from_json(hash, object_mapper)
              task = new
              task.activity_id = hash["activityId"]
              task.activity_instance_id = hash["activityInstanceId"]
              task.error_message = hash["errorMessage"]
              task.error_details = hash["errorDetails"]
              task.execution_id = hash["executionId"]
              task.id = hash["id"]
              task.lock_expiration_time = parse_time(hash["lockExpirationTime"], object_mapper)
              task.create_time = parse_time(hash["createTime"], object_mapper)
              task.process_definition_id = hash["processDefinitionId"]
              task.process_definition_key = hash["processDefinitionKey"]
              task.process_definition_version_tag = hash["processDefinitionVersionTag"]
              task.process_instance_id = hash["processInstanceId"]
              task.retries = hash["retries"]
              task.worker_id = hash["workerId"]
              task.topic_name = hash["topicName"]
              task.tenant_id = hash["tenantId"]
              task.priority = hash["priority"] || 0
              task.business_key = hash["businessKey"]
              task.variables = (hash["variables"] || {}).transform_values do |field|
                Variable::Impl::TypedValueField.from_json(field)
              end
              task.set_extension_properties(hash["extensionProperties"])
              task
            end

            def self.parse_time(value, object_mapper)
              return nil if value.nil?

              object_mapper.parse_date(value)
            end
            private_class_method :parse_time

            def initialize
              @variables = {}
              @received_variable_map = {}
              @extension_properties = nil
              @priority = 0
            end

            # Mirrors getAllVariables
            def all_variables
              received_variable_map.keys.to_h { |name| [name, variable(name)] }
            end

            # Mirrors getVariable
            def variable(variable_name)
              variable_value = received_variable_map[variable_name]
              variable_value&.value
            end

            # Mirrors getAllVariablesTyped
            def all_variables_typed(deserialize_object_values = true)
              vars = Engine::Variable::VariableMap.new
              received_variable_map.each_key do |variable_name|
                vars.put_value_typed(variable_name, variable_typed(variable_name, deserialize_object_values))
              end
              vars
            end

            # Mirrors getVariableTyped
            def variable_typed(variable_name, deserialize_object_values = true)
              variable_value = received_variable_map[variable_name]
              variable_value&.typed_value(deserialize_object_values)
            end

            def extension_properties
              @extension_properties || {}
            end

            def set_extension_properties(extension_properties) # rubocop:disable Naming/AccessorMethodName
              @extension_properties = extension_properties
            end

            def extension_property(property_key)
              @extension_properties&.[](property_key)
            end

            def to_s
              "ExternalTaskImpl [" \
                "activityId=#{activity_id}, " \
                "activityInstanceId=#{activity_instance_id}, " \
                "businessKey=#{business_key}, " \
                "errorDetails=#{error_details}, " \
                "errorMessage=#{error_message}, " \
                "executionId=#{execution_id}, " \
                "id=#{id}, " \
                "lockExpirationTime=#{lock_expiration_time}, " \
                "createTime=#{create_time}, " \
                "priority=#{priority}, " \
                "processDefinitionId=#{process_definition_id}, " \
                "processDefinitionKey=#{process_definition_key}, " \
                "processDefinitionVersionTag=#{process_definition_version_tag}, " \
                "processInstanceId=#{process_instance_id}, " \
                "retries=#{retries}, " \
                "tenantId=#{tenant_id}, " \
                "topicName=#{topic_name}, " \
                "workerId=#{worker_id}]"
            end
          end
        end
      end
    end
  end
end

__END__

require "operaton-bpm-client"

describe Operaton::Bpm::Client::Task::Impl::ExternalTaskImpl do
  before do
    @object_mapper = Operaton::Bpm::Client::Impl::ObjectMapper.new
    @task = Operaton::Bpm::Client::Task::Impl::ExternalTaskImpl.from_json(
      {
        "activityId" => "ServiceTask_1",
        "activityInstanceId" => "ServiceTask_1:instance",
        "businessKey" => "order-4711",
        "createTime" => "2024-05-17T10:00:00.000+0000",
        "errorDetails" => nil,
        "errorMessage" => nil,
        "executionId" => "execution-1",
        "extensionProperties" => { "prop" => "value" },
        "id" => "task-1",
        "lockExpirationTime" => "2024-05-17T10:05:00.000+0000",
        "priority" => 50,
        "processDefinitionId" => "invoice:1:abc",
        "processDefinitionKey" => "invoice",
        "processDefinitionVersionTag" => "v1",
        "processInstanceId" => "process-1",
        "retries" => 3,
        "tenantId" => "tenant-1",
        "topicName" => "invoice-topic",
        "workerId" => "worker-1",
        "variables" => {
          "amount" => { "value" => 42.5, "type" => "Double", "valueInfo" => {} }
        }
      },
      @object_mapper
    )
  end

  it "parses all scalar fields" do
    @task.id.should == "task-1"
    @task.activity_id.should == "ServiceTask_1"
    @task.business_key.should == "order-4711"
    @task.process_definition_key.should == "invoice"
    @task.retries.should == 3
    @task.priority.should == 50
    @task.tenant_id.should == "tenant-1"
    @task.topic_name.should == "invoice-topic"
  end

  it "parses dates with the configured format" do
    @task.create_time.should == Time.utc(2024, 5, 17, 10, 0, 0)
    @task.lock_expiration_time.should == Time.utc(2024, 5, 17, 10, 5, 0)
  end

  it "exposes extension properties" do
    @task.extension_properties.should == { "prop" => "value" }
    @task.extension_property("prop").should == "value"
    @task.extension_property("missing").should.be.nil
  end

  it "returns empty extension properties when none were sent" do
    bare = Operaton::Bpm::Client::Task::Impl::ExternalTaskImpl.from_json({ "id" => "t" }, @object_mapper)
    bare.extension_properties.should == {}
  end

  it "parses raw variables into TypedValueFields" do
    @task.variables["amount"].type.should == "Double"
    @task.variables["amount"].value.should == 42.5
  end
end
