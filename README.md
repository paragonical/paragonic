# _Paragonic_: Agency-Alliance for Neovim with Ollama

> _“Once, men turned their thinking over to machines in the hope that this
> would set them free. But that only permitted other men with machines to
> enslave them.”_ 
> &emsp;&emsp;&emsp;&emsp;&mdash; Frank Herbert, *Dune*

## Introduction 

I don't miss the irony of that quote, but I do recognize the value of
artificial intelligence in coding. Paragonic is designed to enhance the coding
experience in Neovim by providing an AI assistant that can help with code
generation, completion, and other tasks. It integrates with Ollama to leverage
the capabilities of AI via _owned infrastructures_ (e.g., running models on
local machines or private servers) rather than relying on third-party APIs that
may subtley compromise privacy or nerf functionality to benefit a business
model. The unfortunate reality is you have to become the _other men with
machines_ in order to avoid the worse outcome.

| ***Vision*** |
| :---: |
|**Paragonic** is a Neovim extension that integrates with Ollama to provide the infrastructure for alliance between AI-powered agents and humans while concurrently helping humans to improve themselves.|

This isn't a website or a SaaS product, but a Neovim plugin that provides a
framework for building structures for AI-powered agents and human
collaborations.  Anyone can learn Neovim and use Paragonic to create their own
AI-powered agents, or to collaborate with other humans. The plugin is designed
to be flexible and extensible, allowing users to customize their AI-powered
agents and human collaborations to suit their needs.

## Interfaces for Machines and Humans

Interfaces are the key to effective collaboration between humans and machines.
Different interfaces are needed for different tasks, and Paragonic provides a
within Neovim a set of them to facilitate this collaboration. The plugin
includes:
 
 - **Conversational Interface** &emsp; A chat-like interface for
interacting with the agent or human, allowing users to ask questions and
receive responses in natural language.

- **Intentional Interface** &emsp; A structured interface for the
management and execution of goals, projects,   operations and tasks, enabling
users to define and track tasks, assign them to the agent or human, and monitor
progress. This axial interface is designed to help users easily flip between
different activities and perspectives.

_Paragonic_ is a unified MCP host, client and server that together helps the user 
to manage agents and humans in a way that is both efficient and effective.

For expertise we have a balanced system: Machines trade breadth for adapation,
while humans trade speed for breadth. Machine models are trained on vast
datasets, allowing them to generate code quickly for many different situations,
but they may not always understand the specific context of a project. Humans,
on the other hand, have deep knowledge of their projects and can adapt to new
requirements quickly, but they may take longer to write code.

Because models have been trained on all known encoded human knowledge, they
are only getting better via processes like distillation and fine-tuning.

### Structures

Structures are the key to effective collaboration between humans and machines.
Paragonic provides a set of structures to facilitate this collaboration, including:

- **Intentions** &emsp; A structured interface for the display and use of structures. 
- **Axes** &emsp; Methods of organizing and categorizing intentions, allowing users
  to group related tasks and goals together for easier management or discover
  existing intents. Some common axes include:
  - **Alphabetical** &emsp; A simple alphabetical organization of intentions, allowing
    users to quickly find and access specific tasks or goals.
  - **Chronological** &emsp; A chronological organization of intentions, allowing users
    to view tasks and goals in the order they were created or due.
  - **Geospatial** &emsp; A geospatial organization of intentions, allowing users to
    group related tasks and goals together based on their location or spatial
    relationship.
  - **Hierarchical** &emsp; A hierarchical organization of intentions, allowing users to
    group related tasks and goals together in a tree-like structure for easier
    management and navigation.
- **Agents** &emsp; Autonomous or semi-autonomous entities that can perform tasks
  and make decisions on behalf of the user.
- **Humans** &emsp; Human users who can interact with the agent or other humans,
  providing input, feedback, and context to help the agent complete tasks
  effectively.
- **Organizations** &emsp; A collection of agents and humans that work together to
  achieve common goals, allowing users to manage and coordinate efforts across
  multiple agents and humans.
- **Visions** &emsp; High-level objectives that guide the work of the organization, agent or
  human, enabling users to align their efforts with broader organizational or
  personal objectives.
- **Goals** &emsp; High-level objectives that guide the work of the agent or human,
  enabling users to align their efforts with broader organizational or personal
  objectives.
- **Projects** &emsp; A collection of related tasks and goals, allowing users to
  organize their work and track progress.
- **Operations** &emsp; A set of tasks that can be executed in parallel or sequentially,
  allowing users to define workflows and automate repetitive tasks.
- **Tasks** &emsp; Individual units of work that can be defined within
  _projects_ or _opereations_ assigned to the agent or human, enabling users to
  break down larger projects into manageable pieces.  Project tasks are usually
  single-occurrence events and operations tasks are often recurring events.
- **Resources** &emsp; Contextual information and data that can be used by the
  agent or human, enabling users to provide the necessary information for the agent or
  human to complete their tasks effectively.
   - **Repositories** &emsp; A collection of files and directories that can be used by the
     agent or human, enabling users to provide the necessary code and resources for
     the agent or human to complete
   - **Channels** &emsp; A communication channel for the agent or human, allowing users
     to provide updates and feedback on the progress of tasks and goals.
   - **Programs** &emsp; A container of projects and operations, often associated together
     for long-running systems. Programs provide a higher-level organizational structure
     for managing complex, multi-project initiatives.
   - **Portfolios** &emsp; A set of programs, providing the highest level of organizational
     structure for managing multiple long-running systems and initiatives across
     different domains or business areas.
- **Prompts** &emsp; Templated messages and workflows that can be used to guide the
  agent or human, enabling users to provide structured guidance and instructions
  for the agent or human to follow. 
- **Tools** &emsp; Functions that can be executed by the agent or human, enabling users
  to extend the capabilities of the agent or human and provide additional
  functionality.  
- **Conversations** &emsp; A chat-like interface for interacting with the agent or
  human, allowing users to ask questions and receive responses in natural language.     

### Model Context Protocol

- https://modelcontextprotocol.io/specification/2025-06-18 (also in `mcp.md`)

### Interleaved Spaced Repetition Learning (ISRL)

ISRL is a learning technique that combines spaced repetition with interleaving
to enhance retention and understanding. It involves presenting information in a
non-linear fashion, allowing users to revisit concepts at spaced intervals
while interleaving different topics or tasks.  While there are widespread fears
that everyone using AI will become lazy and forgetful, ISRL is a way to ensure
that humans continue to learn and retain knowledge while using AI tools and
provides metrics for identifying expertise and knowledge gaps.  This may be
potentially useful for way to routing review requests for PRs to humans from
humans or agents for units of work.

### Ledgers & Work

You could say that the only score that matters in an ongoing organization is
the burn rate or when funding is exhausted.  There is a plain-text ledger
format that can be used for time and monetary tracking.  Time tracking
implemented by `hledger` is done in a "timedot" format which is great for
people. Each dot is often representive of a 15-minute block of time, such as
four dots `....` representing an hour. One of the nuisances of contracting is
filling out timecards, which should be as automated and transparent as
possible.

We might also consider a "tokencode" format for machines that can be used to
track the cost of running models and other resources.  In either case, there is
work (tasks from projects an operations) that is a cost that can be tracked in
the ledger.  A possible tokencode could be a tuple of floating point numbers
that represents the ln(tokens) used over a period of time for input, thinking,
and output by the agent of human.

```
8/3: work_identifier
     PersonA: ....  (2.0 40.0 11.06)
     Agent:         (3.4 79    7.8)
```

### Communications & Work

One of the basic nuisances of collaboration is communication--figuring out
where you find the people you need to talk to, and how to talk to them.
Paragonic provides a set of dynaic communication channels derived from the
tracked work that can be used to facilitate communication between agents and
humans.  This is meant to be an alternative to Slack and Discord, and JIRA
where channels are manually created and archived creating a lot of friction for
"where to look."

### Agent Guilds

The Agent Guilds are a collection of prompts and workflows that can be
used to guide the agent or human, enabling users to provide structured guidance
and instructions for the agent or human to follow.  The guilds are designed to
be extensible and customizable, allowing users to create their own prompts and
workflows to suit their needs.  The guilds are also designed to be collaborative,
allowing users to share their prompts and workflows with others and to
contribute to the development of new prompts and workflows.

### Standards and Practices

Standards and practices are the "how to do things" regardless of the human or
agent doing the work.


