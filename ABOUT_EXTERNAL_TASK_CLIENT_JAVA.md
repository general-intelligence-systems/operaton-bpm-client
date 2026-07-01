To recreate the external task client in Ruby, you need to implement the following core components based on the Java implementation:

## Core Files to Implement

### 1. Main Client Interface
- **`ExternalTaskClient`** - Main client interface with `subscribe()`, `start()`, `stop()`, and `isActive()` methods [1](#4-0) 

### 2. Builder Pattern
- **`ExternalTaskClientBuilder`** - Interface for fluent configuration (baseUrl, workerId, maxTasks, etc.) [2](#4-1) 
- **`ExternalTaskClientBuilderImpl`** - Implementation with default values and build logic [3](#4-2) 

### 3. HTTP Communication Layer
- **`EngineClient`** - Handles REST API calls to Operaton (fetchAndLock, complete, failure, bpmnError, extendLock, unlock) [4](#4-3) [5](#4-4) 

### 4. Task Service
- **`ExternalTaskService`** - Interface for task operations (complete, handleFailure, handleBpmnError, extendLock, lock, unlock) [6](#4-5) 
- **`ExternalTaskServiceImpl`** - Implementation that delegates to EngineClient [7](#4-6) 

### 5. Topic Subscription Management
- **`TopicSubscriptionManager`** - Runs polling loop, fetches tasks, and executes handlers [8](#4-7) 
- **`TopicSubscriptionBuilder`** - Builder for configuring topic subscriptions (handler, variables, process filters)
- **`TopicSubscriptionBuilderImpl`** - Implementation of subscription builder

### 6. Data Transfer Objects (DTOs)
You'll need Ruby equivalents for:
- **`FetchAndLockRequestDto`** - Request body for fetchAndLock
- **`TopicRequestDto`** - Per-topic configuration in fetchAndLock
- **`CompleteRequestDto`** - Request body for completing tasks
- **`FailureRequestDto`** - Request body for reporting failures
- **`BpmnErrorRequestDto`** - Request body for BPMN errors
- **`ExtendLockRequestDto`** - Request body for extending locks
- **`LockRequestDto`** - Request body for locking tasks
- **`ExternalTask`** - External task data model
- **`TypedValueField`** - Typed variable serialization

### 7. Supporting Components
- **`ExternalTaskHandler`** - Interface/lambda for user-provided task handling logic
- **`BackoffStrategy`** - Retry strategy for failed requests
- **`RequestExecutor`** - HTTP client wrapper
- **`TypedValues`** - Variable serialization/deserialization
- **`ValueMappers`** - Type-specific variable mappers

## REST API Endpoints to Implement

Based on `EngineClient`, you need to call these endpoints [9](#4-8) :

| Endpoint | Purpose |
|----------|---------|
| `/external-task/fetchAndLock` | Fetch and lock tasks |
| `/external-task/{id}/complete` | Complete a task |
| `/external-task/{id}/failure` | Report failure |
| `/external-task/{id}/bpmnError` | Report BPMN error |
| `/external-task/{id}/extendLock` | Extend lock duration |
| `/external-task/{id}/lock` | Lock a task |
| `/external-task/{id}/unlock` | Unlock a task |
| `/process-instance/{id}/variables` | Set variables |

## Notes

The Java client uses Apache HttpClient for HTTP requests. In Ruby, you would typically use `net/http`, `faraday`, or `httparty`. The client follows a subscription model where workers poll for tasks periodically using the `TopicSubscriptionManager`'s run loop [10](#4-9) . The builder pattern is used extensively for configuration [11](#4-10) .

Wiki pages you might want to explore:
- [External Task Client (operaton/operaton)](/wiki/operaton/operaton#3.3)

Wiki pages you might want to explore:
- [External Task Client (operaton/operaton)](/wiki/operaton/operaton#3.3)

### Citations

**File:** clients/java/client/src/main/java/org/operaton/bpm/client/ExternalTaskClient.java (L27-63)
```java
public interface ExternalTaskClient {

  /**
   * Creates a fluent builder to configure the Operaton client
   *
   * @return builder to apply configurations on
   */
  static ExternalTaskClientBuilder create() {
    return new ExternalTaskClientBuilderImpl();
  }

  /**
   * Creates a fluent builder to create and configure a topic subscription
   *
   * @param topicName the client subscribes to
   * @return builder to apply configurations on
   */
  TopicSubscriptionBuilder subscribe(String topicName);

  /**
   * Stops continuous fetching and locking of tasks
   */
  void stop();

  /**
   * Starts continuous fetching and locking of tasks
   */
  void start();

  /**
   * @return <ul>
   *           <li> {@code true} if the client is actively fetching for tasks
   *           <li> {@code false} if the client is not actively fetching for tasks
   *         </ul>
   */
  boolean isActive();

```

**File:** clients/java/client/src/main/java/org/operaton/bpm/client/ExternalTaskClientBuilder.java (L31-130)
```java
public interface ExternalTaskClientBuilder {

  /**
   * Base url of the Operaton BPM Platform REST API. This information is mandatory.
   * <p>
   * If this method is used, it will create a permanent URL resolver with the given baseUrl.
   *
   * @param baseUrl of the Operaton BPM Platform REST API
   * @return the builder
   */
  ExternalTaskClientBuilder baseUrl(String baseUrl);

  /**
   * URL resolver of the Operaton REST API. This information is mandatory.
   * <p>
   * If the server is in a cluster or you are using Spring Cloud, you can create a class which implements UrlResolver..
   * <p>
   * this is a sample for Spring Cloud DiscoveryClient
   * <pre>
   * {@code
   * public class CustomUrlResolver implements UrlResolver {
   * protected String serviceId;
   *
   * protected DiscoveryClient discoveryClient;
   *
   *   protected String getRandomServiceInstance() {
   *     List serviceInstances = discoveryClient.getInstances(serviceId);
   *     Random random = new Random();
   *
   *     return serviceInstances.get(random.nextInt(serviceInstances.size())).getUri().toString();
   *   }
   *
   *   public String getBaseUrl() {
   *     return getRandomServiceInstance();
   *   }
   * }
   * </pre>
   * @param urlResolver of the Operaton 7 REST API
   * @return the builder
   */
  ExternalTaskClientBuilder urlResolver(UrlResolver urlResolver);

  /**
   * A custom worker id the Workflow Engine is aware of. This information is optional.
   * Note: make sure to choose a unique worker id
   * <p>
   * If not given or null, a worker id is generated automatically which consists of the
   * hostname as well as a random and unique 128 bit string (UUID).
   *
   * @param workerId the Workflow Engine is aware of
   * @return the builder
   */
  ExternalTaskClientBuilder workerId(String workerId);

  /**
   * Adds an interceptor to change a request before it is sent to the http server.
   * This information is optional.
   *
   * @param interceptor which changes the request
   * @return the builder
   */
  ExternalTaskClientBuilder addInterceptor(ClientRequestInterceptor interceptor);

  /**
   * Specifies the maximum amount of tasks that can be fetched within one request.
   * This information is optional. Default is 10.
   *
   * @param maxTasks which are supposed to be fetched within one request
   * @return the builder
   */
  ExternalTaskClientBuilder maxTasks(int maxTasks);

  /**
   * Specifies whether tasks should be fetched based on their priority or arbitrarily.
   * This information is optional. Default is <code>true</code>.
   *
   * @param usePriority when fetching and locking tasks
   * @return the builder
   */
  ExternalTaskClientBuilder usePriority(boolean usePriority);

  /**
   * Specifies whether tasks should be fetched based on their create time.
   * If useCreateTime is passed using <code>true</code>, the tasks are going to be fetched in Descending order,
   * otherwise <code>false</code> will not consider create time.
   *
   * @param useCreateTime the flag to control whether create time should be considered
   *                      as a desc sorting criterion (newer tasks will be returned first)
   * @return the builder
   */
  ExternalTaskClientBuilder useCreateTime(boolean useCreateTime);

  /**
   * Fluent API method for configuring createTime as a sorting criterion for fetching of the tasks. Can be used in
   * conjunction with asc or desc methods to configure the respective order for createTime.
   * The method needs to be called first before specifying the order.
   *
   * @return the builder
   */
  ExternalTaskClientBuilder orderByCreateTime();
```

**File:** clients/java/client/src/main/java/org/operaton/bpm/client/impl/ExternalTaskClientBuilderImpl.java (L71-146)
```java
public class ExternalTaskClientBuilderImpl implements ExternalTaskClientBuilder {

  protected static final ExternalTaskClientLogger LOG = ExternalTaskClientLogger.CLIENT_LOGGER;

  protected String workerId;
  protected int maxTasks;
  protected boolean usePriority;
  protected OrderingConfig orderingConfig = OrderingConfig.empty();
  protected Long asyncResponseTimeout;
  protected long lockDuration;

  protected String defaultSerializationFormat = Variables.SerializationDataFormats.JSON.getName();

  protected String dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";

  protected ObjectMapper objectMapper;
  protected ValueMappers valueMappers;
  protected TypedValues typedValues;
  protected EngineClient engineClient;
  protected TopicSubscriptionManager topicSubscriptionManager;
  protected HttpClientBuilder httpClientBuilder;

  protected List<ClientRequestInterceptor> interceptors;
  protected boolean isAutoFetchingEnabled;
  protected BackoffStrategy backoffStrategy;
  protected boolean isBackoffStrategyDisabled;
  protected UrlResolver urlResolver;

  public ExternalTaskClientBuilderImpl() {
    // default values
    this.maxTasks = 10;
    this.usePriority = true;
    this.asyncResponseTimeout = null;
    this.lockDuration = 20_000;
    this.interceptors = new ArrayList<>();
    this.isAutoFetchingEnabled = true;
    this.backoffStrategy = new ExponentialBackoffStrategy();
    this.isBackoffStrategyDisabled = false;
    this.httpClientBuilder = HttpClients.custom().useSystemProperties();
    this.urlResolver = new PermanentUrlResolver(null);
  }

  @Override
  public ExternalTaskClientBuilder baseUrl(String baseUrl) {
    this.urlResolver = new PermanentUrlResolver(baseUrl);
    return this;
  }

  public ExternalTaskClientBuilder urlResolver(UrlResolver urlResolver) {
    this.urlResolver = urlResolver;
    return this;
  }

  @Override
  public ExternalTaskClientBuilder workerId(String workerId) {
    this.workerId = workerId;
    return this;
  }

  @Override
  public ExternalTaskClientBuilder addInterceptor(ClientRequestInterceptor interceptor) {
    this.interceptors.add(interceptor);
    return this;
  }

  @Override
  public ExternalTaskClientBuilder maxTasks(int maxTasks) {
    this.maxTasks = maxTasks;
    return this;
  }

  @Override
  public ExternalTaskClientBuilder usePriority(boolean usePriority) {
    this.usePriority = usePriority;
    return this;
  }
```

**File:** clients/java/client/src/main/java/org/operaton/bpm/client/impl/ExternalTaskClientBuilderImpl.java (L224-253)
```java
  public ExternalTaskClient build() {
    if (maxTasks <= 0) {
      throw LOG.maxTasksNotGreaterThanZeroException(maxTasks);
    }

    if (asyncResponseTimeout != null && asyncResponseTimeout <= 0) {
      throw LOG.asyncResponseTimeoutNotGreaterThanZeroException(asyncResponseTimeout);
    }

    if (lockDuration <= 0L) {
      throw LOG.lockDurationIsNotGreaterThanZeroException(lockDuration);
    }

    if (urlResolver == null || getBaseUrl() == null || getBaseUrl().isEmpty()) {
      throw LOG.baseUrlNullException();
    }

    checkInterceptors();

    orderingConfig.validateOrderingProperties();

    initBaseUrl();
    initWorkerId();
    initObjectMapper();
    initEngineClient();
    initVariableMappers();
    initTopicSubscriptionManager();

    return new ExternalTaskClientImpl(topicSubscriptionManager);
  }
```

**File:** clients/java/client/src/main/java/org/operaton/bpm/client/impl/EngineClient.java (L40-146)
```java
public class EngineClient {

  protected static final String EXTERNAL_TASK_RESOURCE_PATH = "/external-task";
  protected static final String EXTERNAL_TASK_PROCESS_RESOURCE_PATH = "/process-instance";
  protected static final String FETCH_AND_LOCK_RESOURCE_PATH = EXTERNAL_TASK_RESOURCE_PATH + "/fetchAndLock";
  public static final String ID_PATH_PARAM = "{id}";
  protected static final String ID_RESOURCE_PATH = EXTERNAL_TASK_RESOURCE_PATH + "/" + ID_PATH_PARAM;
  public static final String LOCK_RESOURCE_PATH = ID_RESOURCE_PATH + "/lock";
  public static final String EXTEND_LOCK_RESOURCE_PATH = ID_RESOURCE_PATH + "/extendLock";
  public static final String SET_VARIABLES_RESOURCE_PATH = EXTERNAL_TASK_PROCESS_RESOURCE_PATH + "/" + ID_PATH_PARAM + "/variables";
  public static final String UNLOCK_RESOURCE_PATH = ID_RESOURCE_PATH + "/unlock";
  public static final String COMPLETE_RESOURCE_PATH = ID_RESOURCE_PATH + "/complete";
  public static final String FAILURE_RESOURCE_PATH = ID_RESOURCE_PATH + "/failure";
  public static final String BPMN_ERROR_RESOURCE_PATH = ID_RESOURCE_PATH + "/bpmnError";
  public static final String NAME_PATH_PARAM = "{name}";
  public static final String PROCESS_INSTANCE_RESOURCE_PATH = "/process-instance";
  public static final String PROCESS_INSTANCE_ID_RESOURCE_PATH = PROCESS_INSTANCE_RESOURCE_PATH + "/" + ID_PATH_PARAM;
  public static final String GET_BINARY_VARIABLE =
      PROCESS_INSTANCE_ID_RESOURCE_PATH + "/variables/" + NAME_PATH_PARAM + "/data";
  protected UrlResolver urlResolver;
  protected String workerId;
  protected int maxTasks;
  protected boolean usePriority;
  protected OrderingConfig orderingConfig;
  protected Long asyncResponseTimeout;
  protected RequestExecutor engineInteraction;
  protected TypedValues typedValues;

  public EngineClient(String workerId,
                      int maxTasks,
                      Long asyncResponseTimeout,
                      String baseUrl,
                      RequestExecutor engineInteraction) {
    this(workerId, maxTasks, asyncResponseTimeout, baseUrl, engineInteraction, true, OrderingConfig.empty());
  }

  public EngineClient(String workerId,
                      int maxTasks,
                      Long asyncResponseTimeout,
                      String baseUrl,
                      RequestExecutor engineInteraction,
                      boolean usePriority,
                      OrderingConfig orderingConfig) {
    this.workerId = workerId;
    this.asyncResponseTimeout = asyncResponseTimeout;
    this.maxTasks = maxTasks;
    this.usePriority = usePriority;
    this.engineInteraction = engineInteraction;
    this.urlResolver = new PermanentUrlResolver(baseUrl);
    this.orderingConfig = orderingConfig;
  }

  public EngineClient(String workerId,
                      int maxTasks,
                      Long asyncResponseTimeout,
                      UrlResolver urlResolver,
                      RequestExecutor engineInteraction) {
    this(workerId, maxTasks, asyncResponseTimeout, urlResolver, engineInteraction, true, OrderingConfig.empty());
  }

  public EngineClient(String workerId,
                      int maxTasks,
                      Long asyncResponseTimeout,
                      UrlResolver urlResolver,
                      RequestExecutor engineInteraction,
                      boolean usePriority,
                      OrderingConfig orderingConfig) {
    this.workerId = workerId;
    this.asyncResponseTimeout = asyncResponseTimeout;
    this.maxTasks = maxTasks;
    this.usePriority = usePriority;
    this.engineInteraction = engineInteraction;
    this.urlResolver = urlResolver;
    this.orderingConfig = orderingConfig;
  }

  public List<ExternalTask> fetchAndLock(List<TopicRequestDto> topics) {
    FetchAndLockRequestDto payload = new FetchAndLockRequestDto(workerId, maxTasks, asyncResponseTimeout, topics,
        usePriority, orderingConfig);

    String resourceUrl = getBaseUrl() + FETCH_AND_LOCK_RESOURCE_PATH;
    ExternalTask[] externalTasks = engineInteraction.postRequest(resourceUrl, payload, ExternalTaskImpl[].class);
    return Arrays.asList(externalTasks);
  }

  public void lock(String taskId, long lockDuration) {
    LockRequestDto payload = new LockRequestDto(workerId, lockDuration);
    String resourcePath = LOCK_RESOURCE_PATH.replace("{id}", taskId);
    String resourceUrl = getBaseUrl() + resourcePath;
    engineInteraction.postRequest(resourceUrl, payload, Void.class);
  }

  public void unlock(String taskId) {
    String resourcePath = UNLOCK_RESOURCE_PATH.replace("{id}", taskId);
    String resourceUrl = getBaseUrl() + resourcePath;
    engineInteraction.postRequest(resourceUrl, null, Void.class);
  }

  public void complete(String taskId, Map<String, Object> variables, Map<String, Object> localVariables) {
    Map<String, TypedValueField> typedValueDtoMap = typedValues.serializeVariables(variables);
    Map<String, TypedValueField> localTypedValueDtoMap = typedValues.serializeVariables(localVariables);

    CompleteRequestDto payload = new CompleteRequestDto(workerId, typedValueDtoMap, localTypedValueDtoMap);
    String resourcePath = COMPLETE_RESOURCE_PATH.replace("{id}", taskId);
    String resourceUrl = getBaseUrl() + resourcePath;
    engineInteraction.postRequest(resourceUrl, payload, Void.class);
  }
```

**File:** clients/java/client/src/main/java/org/operaton/bpm/client/impl/EngineClient.java (L181-211)
```java
  public void extendLock(String taskId, long newDuration)  {
    ExtendLockRequestDto payload = new ExtendLockRequestDto(workerId, newDuration);
    String resourcePath = EXTEND_LOCK_RESOURCE_PATH.replace("{id}", taskId);
    String resourceUrl = getBaseUrl() + resourcePath;
    engineInteraction.postRequest(resourceUrl, payload, Void.class);
  }

  public byte[] getLocalBinaryVariable(String variableName, String executionId)  {
    String resourcePath =  getBaseUrl()  + GET_BINARY_VARIABLE
            .replace(ID_PATH_PARAM, executionId)
            .replace(NAME_PATH_PARAM, variableName);

    return engineInteraction.getRequest(resourcePath);
  }

  public String getBaseUrl() {
    return urlResolver.getBaseUrl();
  }

  public String getWorkerId() {
    return workerId;
  }

  public void setTypedValues(TypedValues typedValues) {
    this.typedValues = typedValues;
  }

  public boolean isUsePriority() {
    return usePriority;
  }
}
```

**File:** clients/java/client/src/main/java/org/operaton/bpm/client/task/ExternalTaskService.java (L348-377)
```java
  void handleBpmnError(String externalTaskId, String errorCode, String errorMessage, Map<String, Object> variables);

  /**
   * Extends the timeout of the lock by a given amount of time.
   *
   * @param externalTask which lock will be extended
   * @param newDuration  specifies the new lock duration in milliseconds
   *
   * @throws NotFoundException if the task doesn't exist or has already been canceled or completed
   * @throws BadRequestException if an illegal operation was performed or the given data is invalid.
   * @throws EngineException if something went wrong during the engine execution (e.g., a persistence exception occurred)
   * @throws ConnectionLostException if the connection could not be established
   * @throws UnknownHttpErrorException if the HTTP status code is not known by the client.
   */
  void extendLock(ExternalTask externalTask, long newDuration);

  /**
   * Extends the timeout of the lock by a given amount of time.
   *
   * @param externalTaskId the id of the external task which lock will be extended
   * @param newDuration    specifies the new lock duration in milliseconds
   *
   * @throws NotFoundException if the task doesn't exist or has already been canceled or completed
   * @throws BadRequestException if an illegal operation was performed or the given data is invalid.
   * @throws EngineException if something went wrong during the engine execution (e.g., a persistence exception occurred)
   * @throws ConnectionLostException if the connection could not be established
   * @throws UnknownHttpErrorException if the HTTP status code is not known by the client.
   */
  void extendLock(String externalTaskId, long newDuration);

```

**File:** clients/java/client/src/main/java/org/operaton/bpm/client/task/impl/ExternalTaskServiceImpl.java (L30-164)
```java
public class ExternalTaskServiceImpl implements ExternalTaskService {

  protected static final ExternalTaskClientLogger LOG = ExternalTaskClientLogger.CLIENT_LOGGER;

  protected EngineClient engineClient;

  public ExternalTaskServiceImpl(EngineClient engineClient) {
    this.engineClient = engineClient;
  }

  @Override
  public void lock(ExternalTask externalTask, long lockDuration) {
    lock(externalTask.getId(), lockDuration);
  }

  @Override
  public void lock(String externalTaskId, long lockDuration) {
    try {
      engineClient.lock(externalTaskId, lockDuration);
    } catch (EngineClientException e) {
      throw LOG.handledEngineClientException("locking task", e);
    }
  }

  @Override
  public void unlock(ExternalTask externalTask) {
    try {
      engineClient.unlock(externalTask.getId());
    } catch (EngineClientException e) {
      throw LOG.handledEngineClientException("unlocking the external task", e);
    }
  }

  @Override
  public void complete(ExternalTask externalTask) {
    complete(externalTask, null, null);
  }

  @Override
  public void setVariables(String processInstanceId, Map<String, Object> variables) {
    try {
      engineClient.setVariables(processInstanceId, variables);
    } catch (EngineClientException e) {
      throw LOG.handledEngineClientException("setting variables for external task", e);
    }
  }

  @Override
  public void setVariables(ExternalTask externalTask, Map<String, Object> variables) {
    String processId = externalTask.getProcessInstanceId();
    try {
      engineClient.setVariables(processId, variables);
    } catch (EngineClientException e) {
      throw LOG.handledEngineClientException("setting variables for external task", e);
    }
  }

  @Override
  public void complete(ExternalTask externalTask, Map<String, Object> variables) {
    complete(externalTask, variables, null);
  }

  @Override
  public void complete(ExternalTask externalTask, Map<String, Object> variables,  Map<String, Object> localVariables) {
    complete(externalTask.getId(), variables, localVariables);
  }

  @Override
  public void complete(String externalTaskId, Map<String, Object> variables, Map<String, Object> localVariables) {
    try {
      engineClient.complete(externalTaskId, variables, localVariables);
    } catch (EngineClientException e) {
      throw LOG.handledEngineClientException("completing the external task", e);
    }
  }



  @Override
  public void handleFailure(ExternalTask externalTask, String errorMessage, String errorDetails, int retries, long retryTimeout) {
    handleFailure(externalTask.getId(), errorMessage, errorDetails, retries, retryTimeout);
  }

  @Override
  public void handleFailure(String externalTaskId, String errorMessage, String errorDetails, int retries, long retryTimeout) {
    handleFailure(externalTaskId, errorMessage, errorDetails, retries, retryTimeout, null, null);
  }

  @Override
  public void handleFailure(String externalTaskId, String errorMessage, String errorDetails, int retries, long retryTimeout, Map<String, Object> variables, Map<String, Object> locaclVariables) {
    try {
      engineClient.failure(externalTaskId, errorMessage, errorDetails, retries, retryTimeout, variables, locaclVariables);
    } catch (EngineClientException e) {
      throw LOG.handledEngineClientException("notifying a failure", e);
    }
  }

  @Override
  public void handleBpmnError(ExternalTask externalTask, String errorCode) {
    handleBpmnError(externalTask, errorCode, null, null);
  }

  @Override
  public void handleBpmnError(ExternalTask externalTask, String errorCode, String errorMessage) {
    handleBpmnError(externalTask, errorCode, errorMessage, null);
  }

  @Override
  public void handleBpmnError(ExternalTask externalTask, String errorCode, String errorMessage, Map<String, Object> variables) {
    handleBpmnError(externalTask.getId(), errorCode, errorMessage, variables);
  }

  @Override
  public void handleBpmnError(String externalTaskId, String errorCode, String errorMessage, Map<String, Object> variables) {
    try {
      engineClient.bpmnError(externalTaskId, errorCode, errorMessage, variables);
    } catch (EngineClientException e) {
      throw LOG.handledEngineClientException("notifying a BPMN error", e);
    }
  }

  @Override
  public void extendLock(ExternalTask externalTask, long newDuration) {
    extendLock(externalTask.getId(), newDuration);
  }

  @Override
  public void extendLock(String externalTaskId, long newDuration) {
    try {
      engineClient.extendLock(externalTaskId, newDuration);
    } catch (EngineClientException e) {
      throw LOG.handledEngineClientException("extending lock", e);
    }
  }
}
```

**File:** clients/java/client/src/main/java/org/operaton/bpm/client/topic/impl/TopicSubscriptionManager.java (L46-162)
```java
/**
 * @author Tassilo Weidner
 */
public class TopicSubscriptionManager implements Runnable {

  protected static final TopicSubscriptionManagerLogger LOG = ExternalTaskClientLogger.TOPIC_SUBSCRIPTION_MANAGER_LOGGER;

  protected ReentrantLock ACQUISITION_MONITOR = new ReentrantLock(false);
  protected Condition IS_WAITING = ACQUISITION_MONITOR.newCondition();
  protected AtomicBoolean isRunning = new AtomicBoolean(false);

  protected ExternalTaskServiceImpl externalTaskService;

  protected EngineClient engineClient;

  protected CopyOnWriteArrayList<TopicSubscription> subscriptions;
  protected List<TopicRequestDto> taskTopicRequests;
  protected Map<String, ExternalTaskHandler> externalTaskHandlers;

  protected Thread thread;

  protected BackoffStrategy backoffStrategy;
  protected AtomicBoolean isBackoffStrategyDisabled;

  protected TypedValues typedValues;

  protected long clientLockDuration;

  public TopicSubscriptionManager(EngineClient engineClient, TypedValues typedValues, long clientLockDuration) {
    this.engineClient = engineClient;
    this.subscriptions = new CopyOnWriteArrayList<>();
    this.taskTopicRequests = new ArrayList<>();
    this.externalTaskHandlers = new HashMap<>();
    this.clientLockDuration = clientLockDuration;
    this.typedValues = typedValues;
    this.externalTaskService = new ExternalTaskServiceImpl(engineClient);
    this.isBackoffStrategyDisabled = new AtomicBoolean(false);
  }

  @Override
  public void run() {
    while (isRunning.get()) {
      try {
        acquire();
      }
      catch (Exception e) {
        LOG.exceptionWhileAcquiringTasks(e);
      }
    }
  }

  protected void acquire() {
    taskTopicRequests.clear();
    externalTaskHandlers.clear();
    subscriptions.forEach(this::prepareAcquisition);

    if (!taskTopicRequests.isEmpty()) {
      FetchAndLockResponseDto fetchAndLockResponse = fetchAndLock(taskTopicRequests);

      fetchAndLockResponse.getExternalTasks().forEach(externalTask -> {
        String topicName = externalTask.getTopicName();
        ExternalTaskHandler taskHandler = externalTaskHandlers.get(topicName);

        if (taskHandler != null) {
          handleExternalTask(externalTask, taskHandler);
        }
        else {
          LOG.taskHandlerIsNull(topicName);
        }
      });

      if (!isBackoffStrategyDisabled.get()) {
        runBackoffStrategy(fetchAndLockResponse);
      }
    }
  }

  protected void prepareAcquisition(TopicSubscription subscription) {
    TopicRequestDto taskTopicRequest = TopicRequestDto.fromTopicSubscription(subscription, clientLockDuration);
    taskTopicRequests.add(taskTopicRequest);

    String topicName = subscription.getTopicName();
    ExternalTaskHandler externalTaskHandler = subscription.getExternalTaskHandler();
    externalTaskHandlers.put(topicName, externalTaskHandler);
  }

  protected FetchAndLockResponseDto fetchAndLock(List<TopicRequestDto> subscriptions) {
    List<ExternalTask> externalTasks = null;

    try {
      LOG.fetchAndLock(subscriptions);
      externalTasks = engineClient.fetchAndLock(subscriptions);

    } catch (EngineClientException ex) {
      LOG.exceptionWhilePerformingFetchAndLock(ex);
      return new FetchAndLockResponseDto(LOG.handledEngineClientException("fetching and locking task", ex));
    }

    return new FetchAndLockResponseDto(externalTasks);
  }

  @SuppressWarnings("rawtypes")
  protected void handleExternalTask(ExternalTask externalTask, ExternalTaskHandler taskHandler) {
    ExternalTaskImpl task = (ExternalTaskImpl) externalTask;

    Map<String, TypedValueField> variables = task.getVariables();
    Map<String, VariableValue> wrappedVariables = typedValues.wrapVariables(task, variables);
    task.setReceivedVariableMap(wrappedVariables);

    try {
      taskHandler.execute(task, externalTaskService);
    } catch (ExternalTaskClientException e) {
      LOG.exceptionOnExternalTaskServiceMethodInvocation(task.getTopicName(), e);
    } catch (Exception e) {
      LOG.exceptionWhileExecutingExternalTaskHandler(task.getTopicName(), e);
    }
  }
```
