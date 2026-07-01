# Operaton External Task Client for Ruby

A faithful Ruby recreation of the [Operaton](https://github.com/operaton/operaton)
Java external task client (`org.operaton.bpm.client`). The class structure,
method contract, defaults, validation rules, REST payloads, and error handling
mirror the Java implementation one-to-one; names are translated from Java
camelCase to Ruby snake_case.

```
org.operaton.bpm.client              -> Operaton::Bpm::Client
org.operaton.bpm.client.impl         -> Operaton::Bpm::Client::Impl
org.operaton.bpm.client.task         -> Operaton::Bpm::Client::Task
org.operaton.bpm.client.topic        -> Operaton::Bpm::Client::Topic
org.operaton.bpm.client.backoff      -> Operaton::Bpm::Client::Backoff
org.operaton.bpm.client.interceptor  -> Operaton::Bpm::Client::Interceptor
org.operaton.bpm.client.variable     -> Operaton::Bpm::Client::Variable
org.operaton.bpm.engine.variable     -> Operaton::Bpm::Engine::Variable (shim)
```

Exception classes from `org.operaton.bpm.client.exception` live directly under
`Operaton::Bpm::Client` (`BadRequestException`, `NotFoundException`,
`EngineException`, `ConnectionLostException`, `UnknownHttpErrorException`,
`ValueMapperException`, ...).

## Usage

```ruby
require "operaton-external-task-client"

client = Operaton::Bpm::Client::ExternalTaskClient.create
  .base_url("http://localhost:8080/engine-rest")
  .worker_id("my-worker")                # optional; defaults to hostname + UUID
  .max_tasks(10)                         # default 10
  .lock_duration(20_000)                 # default 20s (milliseconds)
  .async_response_timeout(30_000)        # optional long polling
  .add_interceptor(
    Operaton::Bpm::Client::Interceptor::Auth::BasicAuthProvider.new("demo", "demo")
  )
  .build                                 # starts fetching immediately

subscription = client.subscribe("invoice-topic")
  .lock_duration(10_000)
  .process_definition_key("invoice")
  .handler do |task, service|
    amount = task.variable("amount")

    if amount.nil?
      service.handle_bpmn_error(task, "MISSING_AMOUNT")
    elsif amount.negative?
      service.handle_failure(task, "negative amount", nil, (task.retries || 3) - 1, 5_000)
    else
      service.complete(task, { "approved" => true })
    end
  end
  .open

sleep

# later:
subscription.close
client.stop
```

Like the Java client, `create` returns a fluent `ExternalTaskClientBuilder`,
`build` validates the configuration and (unless `disable_auto_fetching` was
called) starts the `TopicSubscriptionManager` polling thread, and `subscribe`
returns a fluent `TopicSubscriptionBuilder` whose `open` activates the
subscription. Handlers may be blocks, lambdas, or objects responding to
`execute(task, service)`.

## Typed variables

The engine's typed value API is recreated under `Operaton::Bpm::Engine::Variable`
and extended by `ClientValues`:

```ruby
Variables = Operaton::Bpm::Engine::Variable::Variables
ClientValues = Operaton::Bpm::Client::Variable::ClientValues

service.complete(task, {
  "count"    => 3,                                     # -> Integer
  "big"      => 2**40,                                 # -> Long
  "rate"     => 0.19,                                  # -> Double
  "ok"       => true,                                  # -> Boolean
  "when"     => Time.now,                              # -> Date
  "payload"  => { "items" => [1, 2, 3] },              # -> Object (application/json)
  "explicit" => Variables.long_value(5),               # force Long
  "raw"      => Variables.byte_array_value("\x00\x01"),# -> Bytes (base64)
  "doc"      => ClientValues.json_value('{"a":1}'),    # -> Json
  "xml"      => ClientValues.xml_value("<a/>"),        # -> Xml
})

task.variable("payload")            # deserialized value
task.variable_typed("payload")      # ObjectValue (lazily deserialized)
task.all_variables                  # Hash of plain values
task.all_variables_typed            # VariableMap of typed values
```

File variables are received as deferred values whose content is fetched from
the engine on first access, mirroring `DeferredFileValue`.

## Deviations from the Java client

Necessary adaptations to the Ruby ecosystem; everything else follows the Java
source:

- **HTTP**: `Net::HTTP` replaces Apache HttpClient. `customize_http_client`
  accepts a block invoked with the `Net::HTTP` instance of each request.
- **JSON**: Ruby's `json` replaces Jackson. Object values serialize any
  JSON-mappable Ruby value; `objectTypeName` records the Ruby class name.
- **Date format**: configured as a Ruby `strftime` pattern; the default
  `"%Y-%m-%dT%H:%M:%S.%L%z"` matches the Java default
  `"yyyy-MM-dd'T'HH:mm:ss.SSSZ"`.
- **SPI**: `java.util.ServiceLoader` is replaced by explicit registries
  (`Spi::DataFormatProvider.register`, `Spi::DataFormatConfigurator.register`).
  The JSON data format is registered by default; the Java-serialization and
  DOM/XML object data formats have no Ruby equivalent (string-typed `xml`
  values are fully supported).
- **Overloads**: Java method overloads collapse into single Ruby methods that
  accept either an `ExternalTask` or an id, with optional trailing arguments.
- **`useCreateTime(true)`**: the Java implementation appends the same ordering
  property twice (producing a duplicated sorting entry in the request); the
  Ruby port configures it once.

## Development

```sh
bundle install
bundle exec rspec
```

The spec suite covers builder validation, variable serialization round-trips,
every REST endpoint payload, HTTP error translation, interceptors, backoff
strategies, and the polling/dispatch loop (84 examples).
