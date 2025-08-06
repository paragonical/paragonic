# _Paragonic_: Agency-Alliance for Neovim with Ollama

[![Version](https://img.shields.io/badge/version-0.5.0-blue.svg)](https://github.com/paragonic/paragonic/releases/tag/v0.5.0)
[![Rust](https://img.shields.io/badge/rust-1.70+-orange.svg)](https://www.rust-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

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

### Enhanced Tool Calling (v0.3.0)

Paragonic now features advanced tool calling capabilities that enable AI agents to execute complex multi-step workflows:

#### **Multi-Step Tool Sequences**
Agents can execute multiple tools in sequence, building upon previous results:
- **Context Awareness**: Tool results are fed back to the AI for continued decision-making
- **Iteration Tracking**: Prevents infinite loops with configurable limits
- **Enhanced Responses**: Rich JSON responses with detailed execution summaries
- **Conversation Context**: Maintains conversation history across tool calls

#### **Available Tools**
- **File System Operations**: `read_file`, `write_file`, `list_files`
- **Project Management**: `create_project`, `create_goal`, `create_task`
- **Database Operations**: Full CRUD operations for all entities
- **AI Integration**: Chat completion, embedding generation, model management

#### **Example Workflows**
```json
{
  "message": {
    "role": "assistant", 
    "content": "I've analyzed your codebase and created a new project..."
  },
  "tool_calls_executed": 3,
  "tool_results": [
    "Tool 'list_files' executed successfully: Found 15 source files",
    "Tool 'read_file' executed successfully: Analyzed Cargo.toml dependencies", 
    "Tool 'create_project' executed successfully: Created 'Code Analysis Project'"
  ],
  "iterations": 2
}
```

#### **Agent Collaboration Features**
- **Autonomous Execution**: Agents can plan and execute complex workflows
- **Error Handling**: Graceful handling of tool failures with detailed reporting
- **Progress Tracking**: Real-time updates on multi-step operations
- **Context Preservation**: Maintains conversation state across tool executions

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

### Interleaved Retrieval-Augmented Generation Learning (IRAGL) 🎉

**NEW IN v0.4.0**: Complete IRAGL Knowledge Management System with PostgreSQL Integration

IRAGL is the machine-equivalent of ISRL, where the system continually refreshes and optimizes the vector knowledge base to ensure that the agent has access to the most relevant and up-to-date information and for the human, the best possible search support for "ad-hoc" questions.

#### 🚀 Key Features
- **🗄️ PostgreSQL Integration**: Full database integration with pgvector extension for vector embeddings
- **🔧 KnowledgeStreamProcessor**: Configurable processor with batch processing, validation, and statistics
- **📊 Content Validation**: Robust validation for content types, entity types, and text content
- **⚡ Batch Processing**: Efficient handling of multiple knowledge streams with error recovery
- **📈 Statistics Tracking**: Real-time monitoring of processing metrics and success rates
- **🛡️ Error Handling**: Comprehensive error recovery and reporting with retry mechanisms
- **🧠 Enhanced Embedding System**: FastEmbed integration with multiple model support
- **✅ Comprehensive Test Suite**: 10/10 IRAGL tests passing with TDD implementation

#### 🔧 Usage Example
```rust
use paragonic::iragl_processor_tests::{KnowledgeStreamProcessor, KnowledgeStreamProcessorConfig};
use paragonic::iragl::{IngestKnowledgeStreamRequest, KnowledgeStreamResponse};
use uuid::Uuid;

// Create processor with custom configuration
let config = KnowledgeStreamProcessorConfig {
    batch_size: 20,
    max_retries: 5,
    retry_delay_ms: 2000,
    enable_validation: true,
    enable_auto_association: true,
    embedding_model: "nomic-embed-text".to_string(),
};

let processor = KnowledgeStreamProcessor::with_config(config)?;

// Process knowledge streams
let request = IngestKnowledgeStreamRequest {
    content_type: "document".to_string(),
    content_text: "This is a test document for IRAGL processing.".to_string(),
    source_entity_type: "project".to_string(),
    source_entity_id: Uuid::new_v4(),
    metadata: Some(serde_json::json!({"author": "test_user"})),
    embedding_model: "nomic-embed-text".to_string(),
};

let response = processor.process_content(request).await?;
println!("Processed content with ID: {}", response.id);
```

#### 📋 System Requirements
- **Rust**: 1.70+ (stable)
- **PostgreSQL**: 13+ with pgvector extension
- **Memory**: 2GB+ RAM (4GB+ recommended for production)
- **Storage**: 10GB+ available space

For detailed installation and usage instructions, see [RELEASE_GUIDE_0.4.0.md](RELEASE_GUIDE_0.4.0.md).

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
agent doing the work. Standards would be things like the OWASP Top 20 that
provide guidance for security.  Practices would be for checklists or runbooks.
We see practices like this in the form of "agentic guides" like AgentOS or the
Three Documents (e.g. generate-prd, generate-tasks, process-tasks). 


