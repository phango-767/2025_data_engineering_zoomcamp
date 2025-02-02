## Installation guide
### Download the Docker Compose file
Download the Docker Compose file using the following command on Linux and macOs:

```
curl -o docker-compose.yml \
https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
```

### Launch Kestra
Use the following command to start the Kestra server:
```
docker-compose up -d
```
Open the URL `http://localhost:8080` in your browser to launch the UI.

#### Adjusting the configuration
The command from the previous section starts a standalone server (all architecture components in on JVM).

The configuration is done inside the `KESTRA_CONFIGURATION` environment variable of the Kestra container. You can update the environment varible inside the Docker compose file or pass it via the Docker command line argument. 

#### Use a config file

If you want to use a config file instead of the `KESTRA_CONFIGURATION` environment variable to configure Kestra, you can update the default `docker-compose.yml`.
First, create a configuration file containing the `KESTRA_CONFIGURATION` environment variable defined in the `docker-compose.yml` file. You can name it `application.yaml`.
Next, update `kestra` service in the `docker-compose.yml` file to mount this file into the container and start up Kestra using the `--config` option:

```yaml
# [...]
  kestra:
    image: kestra/kestra:latest
    pull_policy: always
    # Note that this is meant for development only. Refer to the documentation for production deployments of Kestra which runs without a root user.
    user: "root"
    command: server standalone --worker-thread=128 --config /etc/config/application.yaml
    volumes:
      - kestra-data:/app/storage
      - /var/run/docker.sock:/var/run/docker.sock
      - /tmp/kestra-wd:/tmp/kestra-wd
      - $PWD/application.yaml:/etc/config/application.yaml
    ports:
      - "8080:8080"
      - "8081:8081"
    depends_on:
      postgres:
        condition: service_started
```

## Tutorial

### Fundamentals

#### Flows

Flows are defined in a declarative YAML syntax to keep the orchestration code portable and language agnostic.
Each flow consists of three **required** components: `id`, `namespace`, and `tasks`:

1. `id` represents the name of the flow.
2. `namespace`  can be used to separate development and production environments.
3. `tasks` is a list that will be executed in the order they are defined.

Here are those three components in a YAML file:
```yaml
id: getting_started
namespace: company.team
tasks:
  - id: hello_world
    type: io.kestra.plugin.core.log.Log
    message: Hello World!
```
The `id`  of a flow must be **unique within a namespace**. For example:
- you can have a flow named `getting_started` in the `company.team1` namespace and another flow named `getting_started` in the `company.team2` namespace.
- you cannot have two flows named `getting_started` in the `company.team` namespace at the same time.

The combination of `id` and `namespace` serves as a unique identifier for a flow.

##### Namespaces

Namespaces are used to group flows and provide structure. Keep in mind that the allocation of a flow to a namespace is immutable. Once a flow is created, you cannot change its namespace. If you need to change the namespace of a flow, create a new flow within the desired namespace and delete the old flow.

##### Labels

To add another layer of organization, you can use labels, allowing you to group flows using key-value pairs.

##### Description(s)

You can optionally add a description property to document your flow's purpose or other useful information. The description is a string that supports markdown syntax. That markdown description will be rendered and displayed in the UI.

```yaml
id: getting_started
namespace: company.team

description: |
  # Getting Started
  Let's `write` some **markdown** - [first flow](https://t.ly/Vemr0) 🚀

labels:
  owner: rick.astley
  project: never-gonna-give-you-up

tasks:
  - id: hello_world
    type: io.kestra.plugin.core.log.Log
    message: Hello World!
    description: |
      ## About this task
      This task will print "Hello World!" to the logs.
```
---
#### Tasks

Tasks are atomic actions in your flows. You can design your tasks to be small and granular, such as fetching data from a REST API or running a self-contained Python script. However, tasks can also represent large and complex processes, like triggering containerized processes or long-running batch jobs (e.g. using dbt, Spark, AWS Batch, Azure Batch, etc.) and waiting for their completion.

##### The order of task execution

Tasks are defined in the form of a **list**. By default, all tasks in the list will be executed **sequentially** — the second task will start as soon as the first one finishes successfully.

Kestra provides additional **customization** allowing to run tasks **in parallel**, iterating (sequentially or in parallel) over a list of items, or to **allow failure** of specific tasks. These kinds of actions are called `Flowable` tasks because they define the flow logic.

A task in Kestra must have an `id` and a `type`. Other properties depend on the task type. You can think of a task as a step in a flow that should execute a specific action, such as running a Python or Node.js script in a Docker container, or loading data from a database.

```yaml
tasks:
  - id: python
    type: io.kestra.plugin.scripts.python.Script
    containerImage: python:slim
    script: |
      print("Hello World!")
```
##### Autocompletion
Kestra supports hundreds of tasks integrating with various external systems. Use the shortcut `CTRL + SPACE` on Windows/Linux or `fn + control + SPACE` on MacOS to trigger autocompletion to list available tasks or properties of a given task.

---
### Inputs
Inputs allow you to make your flows more dynamic and reusable.

Instead of hardcoding values in your flow, you can use inputs to make your workflows more adaptable to change.

#### How to retrieve inputs

Inputs can be accessed in any task using the following expression {{ inputs.input_name }}.

#### Defining inputs
Similar to `tasks`, `inputs` is a list of key-value pairs. Each input must have a `name` and a `type`. You can also set `defaults` for each input. Setting default values for an input is always recommended, especially if you want to run your flow on a schedule.

To reference an input value in your flow, use the `{{ inputs.input_name }}` syntax.

```yaml
id: inputs_demo
namespace: company.team

inputs:
  - id: user
    type: STRING
    defaults: Rick Astley

tasks:
  - id: hello
    type: io.kestra.plugin.core.log.Log
    message: Hey there, {{ inputs.user }}
```

#### Parametrize your flow
In our example below, we provide the URL of the API as an input. This way, we can easily change the URL when executing the flow without having to modify the flow itself.
```yaml

id: getting_started
namespace: company.team

inputs:
  - id: api_url
    type: STRING
    defaults: https://dummyjson.com/products

tasks:
  - id: api
    type: io.kestra.plugin.core.http.Request
    uri: "{{ inputs.api_url }}"
```
---
### Outputs
Outputs allow you to pass data between tasks and flows.

Tasks and flows can generate outputs, which can be passed to downstream processes. These outputs can be variables or files stored in the internal storage.

#### How to retrieve outputs
Use the syntax `{{ outputs.task_id.output_property }}` to retrieve a specific output of a task.

If your task id contains one or more hyphens (the `-` sign), wrap the task id in square brackets, like `{{ outputs['task-id'].output_property }}`.

The outputs are useful for troubleshooting and auditing. Additionally, you can use outputs to:

- share **downloadable artifacts** with business stakeholders (e.g., a table generated by a SQL query or a CSV file generated by a Python script)
- **pass data** between decoupled processes (e.g., pass subflow's outputs or a file detected by S3 trigger to downstream tasks)

#### Use outputs in your flows
When fetching data from a REST API, Kestra stores that fetched data in the internal storage and makes it available to downstream tasks using the `body` output argument.

Use the `{{ outputs.task_id.body }}` syntax to process that fetched data in a downstream task, as shown in the Python script task below.

```yaml
id: getting_started_output
namespace: company.team

inputs:
  - id: api_url
    type: STRING
    defaults: https://dummyjson.com/products

tasks:
  - id: api
    type: io.kestra.plugin.core.http.Request
    uri: "{{ inputs.api_url }}"

  - id: python
    type: io.kestra.plugin.scripts.python.Script
    containerImage: python:slim
    beforeCommands:
      - pip install polars
    warningOnStdErr: false
    outputFiles:
      - "products.csv"
    script: |
      import polars as pl
      data = {{outputs.api.body | jq('.products') | first}}
      df = pl.from_dicts(data)
      df.glimpse()
      df.select(["brand", "price"]).write_csv("products.csv")
```
This flow processes data using Polars and stores the result as a CSV file.

#### Passing data between tasks
Let's add another task to the flow to process the CSV file generated by the Python script task. We use the `io.kestra.plugin.jdbc.duckdb.Query` task to run a SQL query on the CSV file and store the result as a downloadable artifact in the internal storage.

```yaml
id: getting_started
namespace: company.team

tasks:
  - id: api
    type: io.kestra.plugin.core.http.Request
    uri: https://dummyjson.com/products

  - id: python
    type: io.kestra.plugin.scripts.python.Script
    containerImage: python:slim
    beforeCommands:
      - pip install polars
    warningOnStdErr: false
    outputFiles:
      - "products.csv"
    script: |
      import polars as pl
      data = {{ outputs.api.body | jq('.products') | first }}
      df = pl.from_dicts(data)
      df.glimpse()
      df.select(["brand", "price"]).write_csv("products.csv")

  - id: sqlQuery
    type: io.kestra.plugin.jdbc.duckdb.Query
    inputFiles:
      in.csv: "{{ outputs.python.outputFiles['products.csv'] }}"
    sql: |
      SELECT brand, round(avg(price), 2) as avg_price
      FROM read_csv_auto('{{ workingDir }}/in.csv', header=True)
      GROUP BY brand
      ORDER BY avg_price DESC;
    store: true
```
This example flow passes data between tasks using outputs. The `inputFiles` argument of the `io.kestra.plugin.jdbc.duckdb.Query` task allows you to pass files from internal storage to the task. The `store: true` property ensures that the result of the SQL query is stored in the internal storage and can be previewed and downloaded from the Outputs tab.

To sum up, our flow extracts data from an API, uses that data in a Python script, executes a SQL query, and generates a downloadable artifact.
---
### Triggers
Triggers automatically start your flow based on events.

A trigger can be a scheduled date, a new file arrival, a new message in a queue, or the end of another flow's execution.

#### Defining triggers
Use the `triggers` keyword in the flow and define a list of triggers. You can have several triggers attached to a flow.

The `trigger` definition looks similar to the task definition — it contains an `id`, a `type`, and additional properties related to the specific trigger type.

The workflow below is automatically triggered every day at 10 AM, as well as anytime when the `first_flow` finishes its execution. Both triggers are independent of each other.

```yaml
id: getting_started
namespace: company.team
tasks:
  - id: hello_world
    type: io.kestra.plugin.core.log.Log
    message: Hello World!

triggers:
  - id: schedule_trigger
    type: io.kestra.plugin.core.trigger.Schedule
    cron: 0 10 * * *

  - id: flow_trigger
    type: io.kestra.plugin.core.trigger.Flow
    conditions:
      - type: io.kestra.plugin.core.condition.ExecutionFlowCondition
        namespace: company.team
        flowId: first_flow

```
#### Adding a trigger to your flow
Let's look at another trigger example. This trigger starts our flow every Monday at 10 AM.

```yaml
triggers:
  - id: every_monday_at_10_am
    type: io.kestra.plugin.core.trigger.Schedule
    cron: 0 10 * * 1
```
full workflow example with this Schedule trigger:

```yaml
id: getting_started
namespace: company.team

labels:
  owner: engineering

tasks:
  - id: api
    type: io.kestra.plugin.core.http.Request
    uri: https://dummyjson.com/products

  - id: python
    type: io.kestra.plugin.scripts.python.Script
    containerImage: python:slim
    beforeCommands:
      - pip install polars
    warningOnStdErr: false
    outputFiles:
      - "products.csv"
    script: |
      import polars as pl
      data = {{ outputs.api.body | jq('.products') | first }}
      df = pl.from_dicts(data)
      df.glimpse()
      df.select(["brand", "price"]).write_csv("products.csv")

  - id: sqlQuery
    type: io.kestra.plugin.jdbc.duckdb.Query
    inputFiles:
      in.csv: "{{ outputs.python.outputFiles['products.csv'] }}"
    sql: |
      SELECT brand, round(avg(price), 2) as avg_price
      FROM read_csv_auto('{{ workingDir }}/in.csv', header=True)
      GROUP BY brand
      ORDER BY avg_price DESC;
    store: true

triggers:
  - id: every_monday_at_10_am
    type: io.kestra.plugin.core.trigger.Schedule
    cron: 0 10 * * 1
```
---
### Flowable Tasks
Run tasks or subflows in parallel, create loops and conditional branching.

#### Add parallelism using Flowable tasks
One of the most common orchestration requirements is to execute independent processes in parallel. For example, you can process data for each partition in parallel. This can significantly speed up the processing time.

The flow below uses the `EachParallel` flowable task to execute a list of `tasks` in parallel.

1. The `value` property defines the list of items to iterate over.
2. The `tasks` property defines the list of tasks to execute for each item in the list. You can access the iteration value using the {{ taskrun.value }} variable.

```yaml
id: python_partitions
namespace: company.team

description: Process partitions in parallel

tasks:
  - id: getPartitions
    type: io.kestra.plugin.scripts.python.Script
    taskRunner:
      type: io.kestra.plugin.scripts.runner.docker.Docker
    containerImage: ghcr.io/kestra-io/pydata:latest
    script: |
      from kestra import Kestra
      partitions = [f"file_{nr}.parquet" for nr in range(1, 10)]
      Kestra.outputs({'partitions': partitions})

  - id: processPartitions
    type: io.kestra.plugin.core.flow.EachParallel
    value: '{{ outputs.getPartitions.vars.partitions }}'
    tasks:
      - id: partition
        type: io.kestra.plugin.scripts.python.Script
        taskRunner:
          type: io.kestra.plugin.scripts.runner.docker.Docker
        containerImage: ghcr.io/kestra-io/pydata:latest
        script: |
          import random
          import time
          from kestra import Kestra

          filename = '{{ taskrun.value }}'
          print(f"Reading and processing partition {filename}")
          nr_rows = random.randint(1, 1000)
          processing_time = random.randint(1, 20)
          time.sleep(processing_time)
          Kestra.counter('nr_rows', nr_rows, {'partition': filename})
          Kestra.timer('processing_time', processing_time, {'partition': filename})
```
---
### Errors and Retries
#### ​Errors and ​Retries
Handle errors with automatic retries and notifications.

Failure is inevitable. Kestra provides automatic retries and error handling to help you build resilient workflows.
#### Error handling
By default, a failure of any task will stop the execution and will mark it as failed. For more control over error handling, you can add `errors` tasks, `AllowFailure` tasks, or automatic retries.

The `errors` property allows you to execute one or more actions before terminating the flow, e.g. sending an email or a Slack message to your team. The property is named `errors` because they are triggered upon errors within your flow.

You can implement error handling at the flow-level or on a namespace-level.

1. **Flow-level**: Useful to implement custom alerting for a specific flow or task. This can be accomplished by adding `errors` tasks.
2. **Namespace-level**: Useful to send a notification for any failed Execution within a given namespace. This approach allows you to implement centralized error handling for all flows within a given namespace.

#### Flow-level error handling using `errors`

The `errors` is a property of a flow that accepts a list of tasks that will be executed when an error occurs. You can add as many tasks as you want, and they will be executed sequentially.

The example below sends a flow-level failure alert via Slack using the [SlackIncomingWebhook](https://kestra.io/plugins/plugin-notifications/tasks/slack/io.kestra.plugin.notifications.slack.slackincomingwebhook) task defined using the `errors` property.

```yaml
id: unreliable_flow
namespace: company.team

tasks:
  - id: fail
    type: io.kestra.plugin.core.execution.Fail

errors:
  - id: alert_on_failure
    type: io.kestra.plugin.notifications.slack.SlackIncomingWebhook
    url: "{{ secret('SLACK_WEBHOOK') }}" # https://hooks.slack.com/services/xyz/xyz/xyz
    payload: |
      {
        "channel": "#alerts",
        "text": "Failure alert for flow {{ flow.namespace }}.{{ flow.id }} with ID {{ execution.id }}"
      }
```

#### Namespace-level error handling using a Flow trigger
To get notified on a workflow failure, you can leverage Kestra's built-in notification tasks, including among others (the list keeps growing with new releases):

- Slack
- Microsoft Teams
- Email

For a centralized namespace-level alerting, we recommend adding a dedicated monitoring workflow with one of the above mentioned notification tasks and a Flow trigger. Below is an example workflow that automatically sends a Slack alert as soon as any flow in the namespace company.analytics fails or finishes with warnings.

```yaml
id: failure_alert
namespace: company.monitoring

tasks:
  - id: send
    type: io.kestra.plugin.notifications.slack.SlackExecution
    url: "{{ secret('SLACK_WEBHOOK') }}"
    channel: "#general"
    executionId: "{{trigger.executionId}}"

triggers:
  - id: listen
    type: io.kestra.plugin.core.trigger.Flow
    conditions:
      - type: io.kestra.plugin.core.condition.ExecutionStatusCondition
        in:
          - FAILED
          - WARNING
      - type: io.kestra.plugin.core.condition.ExecutionNamespaceCondition
        namespace: company.analytics
        prefix: true
```
#### Retries
When working with external systems, transient errors are common. For example, a file may not be available yet, an API might be temporarily unreachable, or a database can be under maintenance. In such cases, retries can automatically fix the issue without human intervention.

##### Configuring retries

Each task can be retried a certain number of times and in a specific way. Use the retry property with the desired type of retry.

The following types of retries are currently supported:
- Constant: The task will be retried every X seconds/minutes/hours/days.
- Exponential: The task will also be retried every X seconds/minutes/hours/days but with an exponential backoff (i.e., an exponential time interval in between each retry attempt.)
- Random: The task will be retried every X seconds/minutes/hours/days with a random delay (i.e., a random time interval in between each retry attempt.)

In this example, we will retry the task 5 times up to 1 minute of a total task run duration, with a constant interval of 2 seconds between each retry attempt.

```yaml
id: retries
namespace: company.team

tasks:
  - id: fail_four_times
    type: io.kestra.plugin.scripts.shell.Commands
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    commands:
      - 'if [ "{{ taskrun.attemptsCount }}" -eq 4 ]; then exit 0; else exit 1; fi'
    retry:
      type: constant
      interval: PT2S
      maxAttempt: 5
      maxDuration: PT1M
      warningOnRetry: false

errors:
  - id: will_never_run
    type: io.kestra.plugin.core.debug.Return
    format: This will never be executed as retries will fix the issue
```
##### Adding a retry configuration to our tutorial workflow
Let's get back to our example from the Fundamentals section. We will add a retry configuration to the api task. API calls are prone to transient errors, so we will retry that task up to 10 times, for at most 1 hour of total duration, every 10 seconds (i.e., with a constant interval of 10 seconds in between retry attempts).

```yaml
id: getting_started
namespace: company.team

tasks:
  - id: api
    type: io.kestra.plugin.core.http.Request
    uri: https://dummyjson.com/products
    retry:
      type: constant # type: string
      interval: PT20S # type: Duration
      maxDuration: PT1H # type: Duration
      maxAttempt: 10 # type: int
      warningOnRetry: true # type: boolean, default is false
```
---
### Docker
Run custom Python, R, Julia, Node.js, and Shell scripts in isolated containers.

#### Tasks running in Docker containers

Many tasks in Kestra will run in dedicated Docker containers, including among others:

- Script tasks running Python, Node.js, R, Julia, Bash, and more
- Singer tasks running data ingestion syncs
- dbt tasks running dbt jobs

Kestra uses Docker for those tasks to ensure that they run in a consistent environment and to avoid dependency conflicts.

#### Defining a Docker task runner

To run a task in a Docker container, set the `taskRunner` property with the type `io.kestra.plugin.scripts.runner.docker.Docker`:
```yaml
taskRunner:
  type: io.kestra.plugin.scripts.runner.docker.Docker
```
Many tasks, including Python, use the `io.kestra.plugin.scripts.runner.docker.Docker` task runner by default.

Using the `containerImage` property, you can define the Docker image for the task. You can use any image from a public or private container registry, as well as a custom local image built from a Dockerfile. You may even build a Docker image using the Docker plugin in one task and reference the built image by the tag in a downstream task.

```yaml
containerImage: ghcr.io/kestra-io/pydata:latest
```
The `taskRunner` property also allows you to configure `credentials` with nested `username` and `password` properties to authenticate a private container registry.

```yaml
id: private_docker_image
namespace: company.team

tasks:
  - id: custom_image
    type: io.kestra.plugin.scripts.python.Script
    taskRunner:
      type: io.kestra.plugin.scripts.runner.docker.Docker
      credentials:
        username: your_username
        password: "{{ secret('GITHUB_ACCESS_TOKEN') }}"
    containerImage: ghcr.io/your_org/your_package:tag
    script: |
        print("this runs using a private container image")
```