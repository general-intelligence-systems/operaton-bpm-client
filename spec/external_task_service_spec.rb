# frozen_string_literal: true

require "spec_helper"

RSpec.describe Operaton::Bpm::Client::Task::Impl::ExternalTaskServiceImpl do
  let(:client_module) { Operaton::Bpm::Client }
  let(:engine_client) { instance_double(client_module::Impl::EngineClient) }
  subject(:service) { described_class.new(engine_client) }

  let(:task) do
    task = client_module::Task::Impl::ExternalTaskImpl.new
    task.id = "task-1"
    task.process_instance_id = "process-1"
    task
  end

  it "completes by task object" do
    expect(engine_client).to receive(:complete).with("task-1", nil, nil)
    service.complete(task)
  end

  it "completes by id with variables" do
    expect(engine_client).to receive(:complete).with("task-1", { "a" => 1 }, { "b" => 2 })
    service.complete("task-1", { "a" => 1 }, { "b" => 2 })
  end

  it "locks, unlocks and extends locks by task or id" do
    expect(engine_client).to receive(:lock).with("task-1", 500)
    service.lock(task, 500)

    expect(engine_client).to receive(:unlock).with("task-1")
    service.unlock(task)

    expect(engine_client).to receive(:extend_lock).with("task-1", 800)
    service.extend_lock("task-1", 800)
  end

  it "sets variables using the task's process instance" do
    expect(engine_client).to receive(:set_variables).with("process-1", { "x" => 1 })
    service.set_variables(task, { "x" => 1 })
  end

  it "reports failures with retry configuration" do
    expect(engine_client).to receive(:failure).with("task-1", "msg", "det", 2, 100, nil, nil)
    service.handle_failure(task, "msg", "det", 2, 100)
  end

  it "reports bpmn errors" do
    expect(engine_client).to receive(:bpmn_error).with("task-1", "code", nil, nil)
    service.handle_bpmn_error(task, "code")
  end

  describe "engine exception translation" do
    def rest_exception(status)
      e = client_module::RestException.new("engine says no", "RestException", 0)
      e.http_status_code = status
      client_module::Impl::EngineClientException.new("wrapped", e)
    end

    it "maps 400 to BadRequestException" do
      allow(engine_client).to receive(:lock).and_raise(rest_exception(400))
      expect { service.lock("task-1", 1) }.to raise_error(client_module::BadRequestException)
    end

    it "maps 404 to NotFoundException" do
      allow(engine_client).to receive(:lock).and_raise(rest_exception(404))
      expect { service.lock("task-1", 1) }.to raise_error(client_module::NotFoundException)
    end

    it "maps 500 to EngineException" do
      allow(engine_client).to receive(:lock).and_raise(rest_exception(500))
      expect { service.lock("task-1", 1) }.to raise_error(client_module::EngineException)
    end

    it "maps other statuses to UnknownHttpErrorException" do
      allow(engine_client).to receive(:lock).and_raise(rest_exception(418))
      expect { service.lock("task-1", 1) }.to raise_error(client_module::UnknownHttpErrorException)
    end

    it "maps IO errors to ConnectionLostException" do
      wrapped = client_module::Impl::EngineClientException.new("io", Errno::ECONNREFUSED.new)
      allow(engine_client).to receive(:lock).and_raise(wrapped)
      expect { service.lock("task-1", 1) }.to raise_error(client_module::ConnectionLostException)
    end
  end
end
