# frozen_string_literal: true

module Operaton
  module Bpm
    module Client
      module Backoff
        # Mirrors org.operaton.bpm.client.backoff.BackoffStrategy
        module BackoffStrategy
          def reconfigure(external_tasks)
            raise NotImplementedError, "#{self.class} must implement #reconfigure"
          end

          def calculate_backoff_time
            raise NotImplementedError, "#{self.class} must implement #calculate_backoff_time"
          end
        end
      end
    end
  end
end

__END__

require "operaton-bpm-client"

describe "backoff strategies" do
  describe Operaton::Bpm::Client::Backoff::ExponentialBackoffStrategy do
    before do
      @strategy = Operaton::Bpm::Client::Backoff::ExponentialBackoffStrategy.new
    end

    it "starts with no backoff" do
      @strategy.calculate_backoff_time.should == 0
    end

    it "doubles the backoff time on consecutive empty responses" do
      @strategy.reconfigure([])
      @strategy.calculate_backoff_time.should == 500
      @strategy.reconfigure([])
      @strategy.calculate_backoff_time.should == 1000
      @strategy.reconfigure([])
      @strategy.calculate_backoff_time.should == 2000
    end

    it "caps the backoff time at the maximum" do
      20.times { @strategy.reconfigure([]) }
      @strategy.calculate_backoff_time.should == 60_000
    end

    it "resets when tasks are received" do
      3.times { @strategy.reconfigure([]) }
      @strategy.reconfigure([:task])
      @strategy.calculate_backoff_time.should == 0
    end
  end

  describe Operaton::Bpm::Client::Backoff::ExponentialErrorBackoffStrategy do
    before do
      @strategy = Operaton::Bpm::Client::Backoff::ExponentialErrorBackoffStrategy.new
    end

    it "backs off only on errors" do
      @strategy.reconfigure([], nil)
      @strategy.calculate_backoff_time.should == 0

      error = Operaton::Bpm::Client::ExternalTaskClientException.new("boom")
      @strategy.reconfigure([], error)
      @strategy.calculate_backoff_time.should == 500
      @strategy.reconfigure([], error)
      @strategy.calculate_backoff_time.should == 1000

      @strategy.reconfigure([], nil)
      @strategy.calculate_backoff_time.should == 0
    end
  end
end
