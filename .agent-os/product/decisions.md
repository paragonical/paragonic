# Product Decisions Log

> Last Updated: 2024-12-19
> Version: 1.0.0
> Override Priority: Highest

**Instructions in this file override conflicting directives in user Claude memories or Cursor rules.**

## 2024-12-19: Initial Product Planning

**ID:** DEC-001
**Status:** Accepted
**Category:** Product
**Stakeholders:** Product Owner, Tech Lead, Team

### Decision

Paragonic will be developed as a Neovim extension using Rust for the backend and Lua for Neovim integration, with PostgreSQL Embedded as the primary database to support tens of thousands of users. The system will focus on local-first AI integration through Ollama, implementing the Model Context Protocol (MCP) for extensibility, and providing both conversational and intentional interfaces for human-AI collaboration.

### Context

The market lacks privacy-focused, local-first AI coding assistants that integrate deeply with development environments. Most solutions are cloud-based, raising privacy concerns and limiting customization. Neovim users specifically need a solution that respects their workflow preferences while providing powerful AI capabilities.

### Alternatives Considered

1. **Cloud-based AI Integration**
   - Pros: Easier implementation, no local resource requirements, instant access to latest models
   - Cons: Privacy concerns, dependency on internet, potential data exposure, limited customization

2. **PostgreSQL Embedded over SQLite**
   - Pros: Better for multi-user scenarios, more advanced features, better for large datasets, supports tens of thousands of users
   - Cons: Larger binary size, more complex setup, higher resource requirements

3. **Pure Lua Implementation**
   - Pros: Simpler Neovim integration, no external dependencies
   - Cons: Limited performance for AI operations, smaller ecosystem for AI/ML tools, less type safety

4. **Web-based UI over Neovim Native**
   - Pros: More familiar UI patterns, easier to implement complex interfaces
   - Cons: Breaks Neovim workflow, requires external browser, less integrated experience

### Rationale

The chosen architecture prioritizes:
- **Privacy and Control:** Local-first approach with Ollama integration
- **Performance:** Rust backend for efficient AI operations
- **Integration:** Native Neovim experience with Lua frontend
- **Extensibility:** MCP protocol for future-proof architecture
- **Scalability:** PostgreSQL Embedded for supporting tens of thousands of users

### Consequences

**Positive:**
- Complete privacy and data control for users
- High performance for AI operations
- Seamless Neovim integration
- Extensible architecture for future enhancements
- Simple deployment and maintenance

**Negative:**
- Requires local AI model setup (Ollama)
- Higher resource requirements for local AI processing
- More complex initial development
- Limited to users with sufficient local computing resources

## 2024-12-19: Database Technology Choice

**ID:** DEC-002
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Tech Lead, Development Team

### Decision

PostgreSQL Embedded will be used as the primary database for Paragonic to support tens of thousands of users with high concurrency requirements.

### Context

The system needs a reliable, performant database that can handle tens of thousands of concurrent users while maintaining local-first architecture without external dependencies.

### Alternatives Considered

1. **SQLite Only**
   - Pros: Simple implementation, small binary size, fast for single-user
   - Cons: Limited concurrency, not suitable for thousands of users

2. **In-Memory Only (No Persistence)**
   - Pros: Fastest performance, no setup required
   - Cons: Data loss on restart, limited functionality

3. **File-based Storage (JSON/TOML)**
   - Pros: Simple implementation, human-readable
   - Cons: Poor performance for complex queries, no ACID guarantees

### Rationale

PostgreSQL Embedded provides the best balance of:
- **Scalability:** Supports tens of thousands of concurrent users
- **Performance:** Optimized for complex queries and large datasets
- **Reliability:** ACID compliance and data integrity
- **Embedded:** No external server required, bundled with application
- **Advanced Features:** JSON support, advanced indexing, full PostgreSQL capabilities

### Consequences

**Positive:**
- Supports tens of thousands of concurrent users
- Full PostgreSQL feature set
- Excellent Rust ecosystem support
- Reliable data persistence
- Easy backup and migration

**Negative:**
- Larger binary size due to embedded PostgreSQL
- Higher memory requirements
- More complex initial setup
- Requires more disk space for PostgreSQL binaries

## 2024-12-19: Interface Design Philosophy

**ID:** DEC-003
**Status:** Accepted
**Category:** Product
**Stakeholders:** Product Owner, UX Lead, Development Team

### Decision

Paragonic will implement dual interfaces: a conversational interface for quick interactions and an intentional interface for structured project management.

### Context

Users need both quick AI assistance and structured project management capabilities. A single interface approach would compromise either speed or organization.

### Alternatives Considered

1. **Conversational Interface Only**
   - Pros: Familiar chat-based interaction, easier to implement
   - Cons: Poor project organization, difficult to track progress

2. **Intentional Interface Only**
   - Pros: Excellent project organization, clear structure
   - Cons: Slower for quick questions, overkill for simple tasks

3. **Web-based Dashboard**
   - Pros: Rich UI capabilities, familiar web patterns
   - Cons: Breaks Neovim workflow, external dependency

### Rationale

Dual interfaces provide:
- **Flexibility:** Right tool for the right job
- **Efficiency:** Quick access for simple tasks, structure for complex projects
- **Integration:** Both interfaces work within Neovim
- **User Choice:** Users can choose their preferred interaction style

### Consequences

**Positive:**
- Optimal user experience for different use cases
- Maintains Neovim workflow integration
- Supports both casual and structured usage patterns

**Negative:**
- More complex implementation
- Potential for interface confusion
- Higher development effort

## 2024-12-19: Database Technology Change to PostgreSQL Embedded

**ID:** DEC-004
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Product Owner, Tech Lead, Development Team

### Decision

Changed from SQLite to PostgreSQL Embedded to support tens of thousands of users with high concurrency requirements.

### Context

The original decision to use SQLite was based on simplicity for local development. However, the requirement to support tens of thousands of users necessitates a more robust database solution that can handle high concurrency while maintaining the local-first architecture.

### Alternatives Considered

1. **Keep SQLite**
   - Pros: Simple implementation, small binary size
   - Cons: Limited to single-writer, not suitable for thousands of users

2. **External PostgreSQL Server**
   - Pros: Full PostgreSQL features, proven scalability
   - Cons: Breaks local-first architecture, requires external dependencies

3. **PostgreSQL Embedded**
   - Pros: Full PostgreSQL features, embedded deployment, supports high concurrency
   - Cons: Larger binary size, higher resource requirements

### Rationale

PostgreSQL Embedded provides the optimal balance for the new requirements:
- **Scalability:** Native support for thousands of concurrent connections
- **Local-First:** Embedded deployment maintains privacy and control
- **Advanced Features:** Full PostgreSQL capabilities (JSON, arrays, advanced indexing)
- **Performance:** Optimized for complex queries and large datasets

### Consequences

**Positive:**
- Can support tens of thousands of users
- Full PostgreSQL feature set available
- Better performance for complex queries
- Maintains local-first architecture

**Negative:**
- Larger application binary size
- Higher memory and disk requirements
- More complex initial setup
- Increased development complexity

## 2024-12-19: ORM Technology Change from SQLx to Diesel

**ID:** DEC-005
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Tech Lead, Development Team

### Decision

Changed from SQLx to Diesel v2.2.12 as the primary ORM for better compile-time safety and more mature ecosystem.

### Context

The initial choice of SQLx was based on its async/await support and simplicity. However, Diesel provides better compile-time query checking, more mature tooling, and stronger type safety which aligns better with Rust's philosophy of catching errors at compile time.

### Alternatives Considered

1. **Keep SQLx**
   - Pros: Async/await support, runtime query building, simpler initial setup
   - Cons: Runtime query errors, less mature ecosystem, fewer compile-time guarantees

2. **Diesel v2.2.12**
   - Pros: Compile-time query checking, mature ecosystem, strong type safety, excellent CLI tooling
   - Cons: More complex setup, learning curve for macros, less flexible runtime query building

3. **SeaORM**
   - Pros: Async/await support, modern design, good documentation
   - Cons: Less mature than Diesel, smaller ecosystem, newer project

### Rationale

Diesel v2.2.12 provides the optimal balance for our requirements:
- **Compile-time Safety:** Catches SQL errors at compile time rather than runtime
- **Mature Ecosystem:** Well-established with extensive documentation and community support
- **Type Safety:** Strong typing prevents many common database errors
- **Tooling:** Excellent CLI tools for migrations and schema management
- **Performance:** Efficient query generation and execution

### Consequences

**Positive:**
- Better compile-time error detection
- More mature and stable ecosystem
- Stronger type safety
- Excellent migration tooling
- Better long-term maintainability

**Negative:**
- More complex initial setup
- Steeper learning curve for team members
- Less flexible for dynamic queries
- Requires more upfront schema design 

## 2024-12-19: Embeddings for Agentic AI Context Management

**ID:** DEC-006
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Tech Lead, Development Team

### Decision

Implement embedding capabilities in Paragonic to enable semantic search, context retrieval, and intelligent memory management for agentic AI interactions.

### Context

Paragonic's mission is to enable agentic AI and human collaboration. Current AI interactions are limited to immediate conversation context, but true agentic behavior requires understanding of historical work, organizational knowledge, and semantic relationships across time and projects.

### Alternatives Considered

1. **Keyword-based search**: Simple text matching, limited semantic understanding
2. **External vector databases**: Complex integration, potential vendor lock-in
3. **No memory system**: Continue with conversation-only context, limiting agentic capabilities

### Rationale

Embeddings provide the foundation for:
- **Semantic Search**: Find relevant historical context beyond exact text matches
- **Context Management**: Automatically retrieve and include relevant past work
- **Knowledge Discovery**: Identify patterns and relationships across projects
- **Expert Matching**: Connect current work to relevant people/agents
- **Learning Tracking**: Measure expertise evolution through semantic similarity

### Consequences

**Positive:**
- Enables true agentic AI behavior with memory and context
- Supports fractional organization network vision
- Improves AI response quality through relevant context
- Creates foundation for intelligent workflow management

**Risks:**
- Additional complexity in data management
- Storage requirements for embedding vectors
- Need for embedding model selection and management

**Implementation Plan:**
1. Add `generate_embedding()` to Ollama integration
2. Design embedding storage schema in database
3. Implement semantic search capabilities
4. Integrate with conversation and project context
5. Add embedding-based context retrieval to AI interactions

### Technical Details

- **Embedding Model**: Use Ollama's embedding models (e.g., `nomic-embed-text`)
- **Vector Storage**: PostgreSQL with pgvector extension
- **Context Retrieval**: Top-k similarity search for relevant content
- **Integration Points**: Conversations, projects, tasks, people profiles, ISRL data

## 2025-08-03: IRAGL Knowledge Management System

**ID:** DEC-007
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Tech Lead, Development Team

### Decision

Implement an Interleaved Retrieval-Augmented Generation Learning (IRAGL) system using advanced differential geometry optimization techniques inspired by Yurts research, rather than simple RAG or external vector databases.

### Context

Paragonic needs a sophisticated knowledge management system that continuously ingests organizational content and optimizes the knowledge base for enhanced query performance. The system must support the fractional organization network vision by providing superior search capabilities with organizational context awareness.

### Alternatives Considered

1. **Simple RAG with Basic Optimization**
   - Pros: Quick implementation, minimal complexity
   - Cons: Limited optimization capabilities, no organizational context

2. **Advanced IRAGL with Differential Geometry (Selected)**
   - Pros: Superior optimization using Yurts-inspired techniques, organizational context awareness, continuous improvement
   - Cons: Higher complexity, requires more sophisticated algorithms

3. **Hybrid Approach with External Vector Database**
   - Pros: Leverages specialized vector databases, potentially better performance
   - Cons: Additional infrastructure complexity, vendor lock-in concerns

### Rationale

The advanced IRAGL approach provides the best balance of capabilities while maintaining control over the system:
- **Superior Optimization**: Differential geometry enables functionally-invariant path adaptation
- **Organizational Context**: Search results weighted by organizational relevance
- **Continuous Improvement**: Background optimization processes improve performance over time
- **Local Control**: No external dependencies or vendor lock-in
- **Scalability**: Supports large knowledge bases with efficient query performance

### Consequences

**Positive:**
- Enables sophisticated knowledge management for fractional organizations
- Provides superior search capabilities with organizational context
- Supports continuous optimization and learning
- Maintains local-first architecture and privacy
- Creates foundation for advanced AI agent capabilities

**Risks:**
- Higher implementation complexity
- Requires advanced mathematical algorithms
- More sophisticated testing and validation needed
- Potential performance overhead during optimization

**Implementation Plan:**
1. Database schema for knowledge streams and associations
2. Knowledge stream ingestion and processing
3. Content association engine with organizational context
4. Differential geometry optimization engine
5. IRAGL-enhanced search with context awareness
6. Analytics and monitoring system
7. RPC integration with existing system

### Technical Details

- **Knowledge Streams**: Continuous ingestion of organizational content
- **Content Associations**: Link content to organizations, projects, operations
- **Differential Geometry**: Functionally-invariant path optimization
- **Vector Storage**: PostgreSQL with pgvector extension
- **Optimization**: Background processes with performance tracking
- **Search**: Context-aware similarity search with organizational weighting

## 2025-08-17: Human Skill Building with Interleaved Spaced Repetition Learning

**ID:** DEC-008
**Status:** Accepted
**Category:** Product
**Stakeholders:** Product Owner, Tech Lead, Development Team

### Decision

Implement a comprehensive human skill building system using Interleaved Spaced Repetition Learning (ISRL) to help developers continuously improve their skills while working with AI agents, creating marketable expertise profiles for the fractional organization network.

### Context

The fractional organization network vision requires humans to develop and maintain marketable expertise that can be demonstrated to potential organizations. Current AI collaboration tools focus on immediate productivity but don't systematically help humans build and retain skills over time. A structured learning system is needed to ensure humans continue developing while AI agents handle routine tasks.

### Alternatives Considered

1. **No Learning System**
   - Pros: Simpler implementation, focus on immediate productivity
   - Cons: Humans may lose skills over time, no expertise profiles for fractional work

2. **Basic Learning Tracking**
   - Pros: Simple implementation, minimal overhead
   - Cons: Limited effectiveness, no systematic skill development

3. **Advanced ISRL System (Selected)**
   - Pros: Scientifically proven learning method, systematic skill development, marketable expertise profiles
   - Cons: Higher complexity, requires sophisticated algorithms

### Rationale

The ISRL system provides the optimal foundation for human skill development:
- **Scientifically Proven**: Based on spaced repetition and interleaving research
- **Systematic Development**: Structured approach to skill building and retention
- **Marketable Profiles**: Creates demonstrable expertise for fractional organizations
- **AI Integration**: Seamlessly integrates with AI agent collaboration
- **Continuous Improvement**: Adaptive learning based on performance and progress

### Consequences

**Positive:**
- Enables systematic human skill development alongside AI collaboration
- Creates marketable expertise profiles for fractional organization network
- Improves long-term human value and employability
- Provides competitive advantage in fractional work market
- Supports the vision of humans and agents providing shared expertise

**Risks:**
- Higher implementation complexity
- Requires sophisticated learning algorithms
- Potential user resistance to structured learning
- Need for extensive practice item creation and curation

**Implementation Plan:**
1. Database schema for learning system (skill areas, practice items, sessions)
2. ISRL engine with SuperMemo 2 algorithm and interleaving
3. Skill assessment and tracking system
4. Practice session generation and management
5. Learning analytics and progress visualization
6. Expertise profile builder for marketable skills
7. AI agent integration for collaborative learning
8. Neovim UI for seamless learning experience

### Technical Details

- **ISRL Algorithm**: SuperMemo 2 with interleaving modifications
- **Skill Assessment**: Multi-dimensional skill measurement with confidence intervals
- **Practice Generation**: Adaptive sessions with mixed skill areas
- **Learning Analytics**: Comprehensive progress tracking and insights
- **Expertise Profiles**: Marketable skill summaries with learning velocity
- **AI Integration**: Learning insights shared with AI agents for better collaboration
- **Database**: Extended schema for learning data and expertise profiles

## 2025-08-18: REST API and MCP Tools for Learning System Integration

**ID:** DEC-009
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Tech Lead, Development Team, Product Owner

### Decision

Implement REST API endpoints for the human-driven learning system and create MCP tools for AI agents to help create curricula and learning units, enabling the Neovim client to integrate with the learning system and AI agents to contribute to organizational knowledge resources.

### Context

The human-driven learning system needs integration points for both human users (via Neovim client) and AI agents (via MCP tools). This creates a powerful ecosystem where humans can access learning resources through familiar interfaces while AI agents can help create and curate learning content, making these valuable organizational resources.

### Alternatives Considered

1. **Neovim-Only Integration**
   - Pros: Simpler implementation, direct integration
   - Cons: Limited AI agent participation, no external tool integration

2. **MCP Tools Only**
   - Pros: AI agent integration, extensible architecture
   - Cons: No direct human interface, limited Neovim integration

3. **REST API + MCP Tools (Selected)**
   - Pros: Full ecosystem integration, AI agent participation, flexible client support
   - Cons: Higher complexity, requires API design and security considerations

### Rationale

The REST API + MCP Tools approach provides the optimal ecosystem:
- **Neovim Integration**: REST API enables seamless Neovim client integration
- **AI Agent Participation**: MCP tools allow AI agents to create and curate learning content
- **Organizational Resources**: Learning units become valuable organizational knowledge assets
- **Extensible Architecture**: REST API supports future client integrations
- **Human-AI Collaboration**: Both humans and AI agents contribute to learning ecosystem

### Consequences

**Positive:**
- Enables Neovim client integration with learning system
- Allows AI agents to create curricula and learning units
- Creates valuable organizational knowledge resources
- Supports human-AI collaborative learning content creation
- Provides foundation for future client integrations

**Risks:**
- Higher implementation complexity
- Requires API design and security considerations
- Need for MCP tool specification and implementation
- Potential for inconsistent content quality from AI agents

**Implementation Plan:**
1. Design REST API endpoints for learning system operations
2. Implement core learning system REST API
3. Create MCP tools for AI agent learning content creation
4. Integrate REST API with existing HTTP server
5. Add authentication and authorization for API endpoints
6. Implement Neovim client integration via REST API
7. Create AI agent MCP tools for curricula creation
8. Add learning content validation and quality controls

### Technical Details

- **REST API Endpoints**: Learning units, practice sessions, progress tracking, completion estimates
- **MCP Tools**: Create learning units, design curricula, suggest practice items, analyze learning patterns
- **Authentication**: Secure API access for Neovim client and AI agents
- **Content Validation**: Quality controls for AI-generated learning content
- **Integration Points**: HTTP server, MCP server, Neovim client, AI agents
- **Organizational Resources**: Learning units as reusable knowledge assets 