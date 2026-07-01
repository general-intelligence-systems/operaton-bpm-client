#!/usr/bin/env ruby
# frozen_string_literal: true

# The "charge card" quick start from the Operaton external task client docs,
# translated from Java:
#
#   ExternalTaskClient client = ExternalTaskClient.create()
#       .baseUrl("http://localhost:8080/engine-rest")
#       .asyncResponseTimeout(10000)
#       .build();
#
#   client.subscribe("charge-card")
#         .lockDuration(1000)
#         .handler((externalTask, externalTaskService) -> {
#             String item = externalTask.getVariable("item");
#             Integer amount = externalTask.getVariable("amount");
#             System.out.printf("Charging credit card with an amount of %d EUR for the item '%s'...", amount, item);
#             externalTaskService.complete(externalTask);
#         })
#         .open();
#
# Run `docker compose up -d` first, then: ruby examples/simple/charge_card_worker.rb

require_relative "../../lib/operaton-bpm-client"
require_relative "../support/engine_rest"

engine = Examples::EngineRest.new

puts "Waiting for Operaton at #{engine.base_url} ..."
engine.wait_until_ready
puts " engine is up."

engine.deploy("payment-retrieval-example", File.join(__dir__, "payment_retrieval.bpmn"))
instance = engine.start_process("payment-retrieval",
                                variables: { "item" => "camunda-fedora", "amount" => 99 })
puts "Started payment-retrieval instance #{instance['id']}"

handled = Queue.new

client = Operaton::Bpm::Client::ExternalTaskClient.create
                                                  .base_url(engine.base_url)
                                                  .async_response_timeout(10_000)
                                                  .build

client.subscribe("charge-card")
      .lock_duration(1_000)
      .handler do |external_task, external_task_service|
        item = external_task.variable("item")
        amount = external_task.variable("amount")

        puts format("Charging credit card with an amount of %d EUR for the item '%s'...", amount, item)

        external_task_service.complete(external_task)
        handled << external_task.id
      end
      .open

Timeout.timeout(60) { handled.pop }
sleep 0.5 until engine.running_instance_count("payment-retrieval").zero?
client.stop

puts "Process instance completed. The Ruby client is behaving like the Java quick start."
