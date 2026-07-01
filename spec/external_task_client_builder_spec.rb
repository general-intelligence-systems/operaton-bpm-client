# frozen_string_literal: true

require "spec_helper"

RSpec.describe Operaton::Bpm::Client::Impl::ExternalTaskClientBuilderImpl do
  let(:client_module) { Operaton::Bpm::Client }

  def builder
    client_module::ExternalTaskClient.create
      .base_url("http://localhost:8080/engine-rest")
      .disable_auto_fetching
  end

  it "builds a client with defaults matching the Java client" do
    client = builder.build
    expect(client).to be_a(client_module::Impl::ExternalTaskClientImpl)
    expect(client.active?).to be(false)

    engine_client = client.topic_subscription_manager.engine_client
    expect(engine_client.max_tasks).to eq(10)
    expect(engine_client.use_priority?).to be(true)
    expect(engine_client.async_response_timeout).to be_nil
    expect(engine_client.base_url).to eq("http://localhost:8080/engine-rest")
  end

  it "generates a worker id from hostname and uuid when not given" do
    engine_client = builder.build.topic_subscription_manager.engine_client
    expect(engine_client.worker_id).to include(Socket.gethostname)
    expect(engine_client.worker_id).to match(/\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
  end

  it "keeps an explicitly configured worker id" do
    client = builder.worker_id("worker-1").build
    expect(client.topic_subscription_manager.engine_client.worker_id).to eq("worker-1")
  end

  it "sanitizes trailing slashes from the base url" do
    client = client_module::ExternalTaskClient.create
                                              .base_url("  http://localhost:8080/engine-rest/// ")
                                              .disable_auto_fetching
                                              .build
    expect(client.topic_subscription_manager.engine_client.base_url)
      .to eq("http://localhost:8080/engine-rest")
  end

  it "rejects a missing base url" do
    expect { client_module::ExternalTaskClient.create.build }
      .to raise_error(client_module::ExternalTaskClientException, /Base URL cannot be null/)
  end

  it "rejects maxTasks <= 0" do
    expect { builder.max_tasks(0).build }
      .to raise_error(client_module::ExternalTaskClientException, /Maximum amount of fetched tasks/)
  end

  it "rejects asyncResponseTimeout <= 0" do
    expect { builder.async_response_timeout(0).build }
      .to raise_error(client_module::ExternalTaskClientException, /Asynchronous response timeout/)
  end

  it "rejects lockDuration <= 0" do
    expect { builder.lock_duration(0).build }
      .to raise_error(client_module::ExternalTaskClientException, /Lock duration must be greater than 0/)
  end

  it "rejects nil interceptors" do
    expect { builder.add_interceptor(nil).build }
      .to raise_error(client_module::ExternalTaskClientException, /Interceptor cannot be null/)
  end

  describe "ordering configuration" do
    it "rejects asc() without orderBy" do
      expect { builder.asc }
        .to raise_error(client_module::ExternalTaskClientException, /orderBy methods first/)
    end

    it "rejects a double direction" do
      expect { builder.order_by_create_time.desc.asc }
        .to raise_error(client_module::ExternalTaskClientException, /only one direction/)
    end

    it "rejects a missing direction on build" do
      expect { builder.order_by_create_time.build }
        .to raise_error(client_module::ExternalTaskClientException, /call asc\(\) or desc\(\)/)
    end

    it "accepts orderByCreateTime().desc()" do
      client = builder.order_by_create_time.desc.build
      sorting = client.topic_subscription_manager.engine_client.ordering_config.to_sorting_dtos
      expect(sorting.map(&:as_json)).to eq([{ "sortBy" => "createTime", "sortOrder" => "desc" }])
    end

    it "configures createTime desc through useCreateTime(true)" do
      client = builder.use_create_time(true).build
      sorting = client.topic_subscription_manager.engine_client.ordering_config.to_sorting_dtos
      expect(sorting.map(&:as_json)).to eq([{ "sortBy" => "createTime", "sortOrder" => "desc" }])
    end
  end

  it "starts fetching immediately unless auto fetching is disabled" do
    client = client_module::ExternalTaskClient.create
                                              .base_url("http://localhost:1") # never reached: no subscriptions
                                              .build
    expect(client.active?).to be(true)
    client.stop
    expect(client.active?).to be(false)
  end
end
