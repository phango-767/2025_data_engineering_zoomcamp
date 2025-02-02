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

---
### Triggers

---
### Flowable Tasks

---
### Errors and Retries

---
### Docker