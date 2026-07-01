#!/usr/bin/env ruby
# frozen_string_literal: true

# A more complete example in the style of the Java client's order-handling
# examples. It exercises the parts of the API the simple quick start does not:
#
#   * one client with several topic subscriptions and filters
#   * long polling (asyncResponseTimeout) and per-subscription lock durations
#   * object (JSON) variables, explicitly typed values, VariableMap access
#   * handleFailure with a retry counter and retryTimeout (transient errors)
#   * handleBpmnError caught by a boundary error event in the process
#   * extendLock, businessKey and variable filtering
#
# Run `docker compose up -d` first, then: ruby examples/complex/order_handling_worker.rb

require "time"
require "timeout"
require_relative "../../lib/operaton-bpm-client"
require_relative "../support/engine_rest"

Variables = Operaton::Bpm::Engine::Variable::Variables
ClientValues = Operaton::Bpm::Client::Variable::ClientValues

engine = Examples::EngineRest.new

puts "Waiting for Operaton at #{engine.base_url} ..."
engine.wait_until_ready
puts " engine is up."

engine.deploy("order-process-example", File.join(__dir__, "order_process.bpmn"))

# Three orders: one ships, one fails payment (BPMN error -> cancellation),
# one is rejected by validation (gateway routes straight to an end event).
orders = [
  { business_key: "order-1001", total: 249.90, items: %w[keyboard mouse], simulate_payment_failure: false },
  { business_key: "order-1002", total: 999.99, items: %w[gpu], simulate_payment_failure: true },
  { business_key: "order-1003", total: 15_000.00, items: %w[mainframe], simulate_payment_failure: false }
]

instances = orders.map do |order|
  engine.start_process(
    "order-process",
    business_key: order[:business_key],
    variables: {
      # An object variable, serialized as application/json by the engine REST API
      "order" => {
        "value" => JSON.generate({ "items" => order[:items], "total" => order[:total] }),
        "type" => "Object",
        "valueInfo" => { "serializationDataFormat" => "application/json",
                         "objectTypeName" => "java.util.LinkedHashMap" }
      },
      "simulatePaymentFailure" => order[:simulate_payment_failure]
    }
  ).tap { |instance| puts "Started #{order[:business_key]} as instance #{instance['id']}" }
end

outcomes = Queue.new
validation_attempts = Hash.new(0)

client = Operaton::Bpm::Client::ExternalTaskClient.create
                                                  .base_url(engine.base_url)
                                                  .worker_id("ruby-order-worker")
                                                  .max_tasks(5)
                                                  .async_response_timeout(5_000)
                                                  .lock_duration(10_000)
                                                  .build

# --- Topic 1: validation. Demonstrates object variables, transient failures
# with handleFailure + retries, and completing with typed values.
client.subscribe("order-validation")
      .process_definition_key("order-process")
      .lock_duration(5_000)
      .handler do |task, service|
        order = task.variable("order") # deserialized JSON -> Hash
        attempts = (validation_attempts[task.business_key] += 1)

        # Simulate a flaky validation service: the first attempt of every order
        # fails transiently. retries counts down from 2; the engine re-schedules
        # the task after retryTimeout instead of creating an incident.
        if attempts == 1
          retries = task.retries.nil? ? 2 : task.retries - 1
          puts "[validation] #{task.business_key}: transient error, #{retries} retries left"
          service.handle_failure(task, "validation service unavailable",
                                 "simulated transient failure (attempt #{attempts})",
                                 retries, 1_000)
        else
          approved = order["total"] <= 10_000
          puts "[validation] #{task.business_key}: total=#{order['total']} approved=#{approved} " \
               "(attempt #{attempts})"
          service.complete(task, {
                             "approved" => approved,
                             "validationScore" => Variables.long_value(order["items"].size * 100),
                             "validatedBy" => "ruby-order-worker"
                           })
          outcomes << [task.business_key, :rejected] unless approved
        end
      end
      .open

# --- Topic 2: payment. Demonstrates extendLock and handleBpmnError with
# variables; the process catches PAYMENT_FAILED with a boundary event.
client.subscribe("payment")
      .variables("order", "simulatePaymentFailure", "validationScore")
      .handler do |task, service|
        # Pretend the charge takes longer than expected
        service.extend_lock(task, 30_000)

        typed = task.variable_typed("validationScore")
        puts "[payment]    #{task.business_key}: validationScore=#{typed.value} (#{typed.type.name})"

        if task.variable("simulatePaymentFailure")
          puts "[payment]    #{task.business_key}: card declined -> BPMN error PAYMENT_FAILED"
          service.handle_bpmn_error(task, "PAYMENT_FAILED", "credit card declined",
                                    { "refundRequired" => false })
        else
          receipt = ClientValues.json_value(JSON.generate({ "receiptId" => "r-#{task.business_key}",
                                                            "paidAt" => Time.now.utc.iso8601 }))
          service.complete(task, { "receipt" => receipt })
        end
      end
      .open

# --- Topics 3 + 4: the two possible endings of the happy/error paths.
client.subscribe("order-shipping")
      .handler do |task, service|
        puts "[shipping]   #{task.business_key}: shipped (receipt=#{task.variable('receipt')})"
        service.complete(task)
        outcomes << [task.business_key, :shipped]
      end
      .open

client.subscribe("order-cancellation")
      .handler do |task, service|
        puts "[cancel]     #{task.business_key}: cancelled after payment failure"
        service.complete(task)
        outcomes << [task.business_key, :cancelled]
      end
      .open

results = {}
Timeout.timeout(120) do
  while results.size < orders.size
    business_key, outcome = outcomes.pop
    results[business_key] = outcome
  end
end

sleep 0.5 until engine.running_instance_count("order-process").zero?
client.stop

puts
puts "Outcomes:"
results.sort.each { |business_key, outcome| puts "  #{business_key}: #{outcome}" }

expected = { "order-1001" => :shipped, "order-1002" => :cancelled, "order-1003" => :rejected }
if results == expected
  puts "All order paths behaved exactly like the Java client would. ✓"
else
  puts "Unexpected outcomes! expected #{expected.inspect}"
  exit 1
end
