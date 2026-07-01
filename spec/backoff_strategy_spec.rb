# frozen_string_literal: true

require "spec_helper"

RSpec.describe "backoff strategies" do
  describe Operaton::Bpm::Client::Backoff::ExponentialBackoffStrategy do
    subject(:strategy) { described_class.new }

    it "starts with no backoff" do
      expect(strategy.calculate_backoff_time).to eq(0)
    end

    it "doubles the backoff time on consecutive empty responses" do
      strategy.reconfigure([])
      expect(strategy.calculate_backoff_time).to eq(500)
      strategy.reconfigure([])
      expect(strategy.calculate_backoff_time).to eq(1000)
      strategy.reconfigure([])
      expect(strategy.calculate_backoff_time).to eq(2000)
    end

    it "caps the backoff time at the maximum" do
      20.times { strategy.reconfigure([]) }
      expect(strategy.calculate_backoff_time).to eq(60_000)
    end

    it "resets when tasks are received" do
      3.times { strategy.reconfigure([]) }
      strategy.reconfigure([:task])
      expect(strategy.calculate_backoff_time).to eq(0)
    end
  end

  describe Operaton::Bpm::Client::Backoff::ExponentialErrorBackoffStrategy do
    subject(:strategy) { described_class.new }

    it "backs off only on errors" do
      strategy.reconfigure([], nil)
      expect(strategy.calculate_backoff_time).to eq(0)

      error = Operaton::Bpm::Client::ExternalTaskClientException.new("boom")
      strategy.reconfigure([], error)
      expect(strategy.calculate_backoff_time).to eq(500)
      strategy.reconfigure([], error)
      expect(strategy.calculate_backoff_time).to eq(1000)

      strategy.reconfigure([], nil)
      expect(strategy.calculate_backoff_time).to eq(0)
    end
  end
end
