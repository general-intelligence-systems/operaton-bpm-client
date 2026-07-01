# frozen_string_literal: true

require "spec_helper"

RSpec.describe Operaton::Bpm::Client::Task::Impl::ExternalTaskImpl do
  let(:object_mapper) { Operaton::Bpm::Client::Impl::ObjectMapper.new }

  let(:task) do
    described_class.from_json(
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
      object_mapper
    )
  end

  it "parses all scalar fields" do
    expect(task.id).to eq("task-1")
    expect(task.activity_id).to eq("ServiceTask_1")
    expect(task.business_key).to eq("order-4711")
    expect(task.process_definition_key).to eq("invoice")
    expect(task.retries).to eq(3)
    expect(task.priority).to eq(50)
    expect(task.tenant_id).to eq("tenant-1")
    expect(task.topic_name).to eq("invoice-topic")
  end

  it "parses dates with the configured format" do
    expect(task.create_time).to eq(Time.utc(2024, 5, 17, 10, 0, 0))
    expect(task.lock_expiration_time).to eq(Time.utc(2024, 5, 17, 10, 5, 0))
  end

  it "exposes extension properties" do
    expect(task.extension_properties).to eq("prop" => "value")
    expect(task.extension_property("prop")).to eq("value")
    expect(task.extension_property("missing")).to be_nil
  end

  it "returns empty extension properties when none were sent" do
    bare = described_class.from_json({ "id" => "t" }, object_mapper)
    expect(bare.extension_properties).to eq({})
  end

  it "parses raw variables into TypedValueFields" do
    expect(task.variables["amount"].type).to eq("Double")
    expect(task.variables["amount"].value).to eq(42.5)
  end
end
