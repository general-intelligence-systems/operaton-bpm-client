# Examples

Runnable examples that exercise the Ruby external task client against a real
Operaton engine, modeled on the examples the Java client documents (the
"charge card" quick start and an order-handling process).

## Prerequisites

Start the engine (uses the official `operaton/operaton` image, H2 in-memory
database, REST API on http://localhost:8080/engine-rest):

```sh
docker compose up -d
```

The examples deploy their own BPMN models through the REST API and wait for
the engine to become ready, so no further setup is needed. Set
`OPERATON_BASE_URL` if your engine runs elsewhere.

## Simple: charge card (quick start)

The [external task client quick start](https://docs.operaton.org/get-started/quick-start/):
a `payment-retrieval` process with a single external service task on topic
`charge-card`. The worker fetches the task, reads the `item` and `amount`
variables, and completes it — a line-for-line translation of the Java example.

```sh
ruby examples/simple/charge_card_worker.rb
```

Expected output ends with `Process instance completed.`

## Complex: order handling

An `order-process` with four external task topics and both failure paths,
covering the API surface the quick start does not:

| Feature | Where |
|---|---|
| Multiple subscriptions on one client | all four topics |
| Long polling + per-subscription lock durations | client + `order-validation` |
| Object (JSON) variables in and out | `order` variable, `receipt` |
| Explicitly typed values (`long_value`, `json_value`) | validation + payment |
| `variable_typed` access | payment |
| `handle_failure` with retries + retryTimeout | flaky validation service |
| `handle_bpmn_error` + boundary error event | declined payment → cancellation |
| `extend_lock` | payment |
| `business_key`, variable filtering, `process_definition_key` filter | payment/validation |

Three orders are started: one ships, one fails payment (BPMN error
`PAYMENT_FAILED` routes to cancellation), one is rejected by validation.

```sh
ruby examples/complex/order_handling_worker.rb
```

Expected output ends with:

```
Outcomes:
  order-1001: shipped
  order-1002: cancelled
  order-1003: rejected
All order paths behaved exactly like the Java client would. ✓
```
