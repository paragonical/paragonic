# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2025-08-07

### Added
- **🔌 Real Backend Integration**: Plugin now connects directly to Rust backend using vim.uv TCP sockets
- **⚡ Direct TCP Communication**: Eliminated dependency on external tools (nc, curl) for backend communication
- **🎯 Real AI Responses**: Plugin now returns actual AI responses from Ollama models instead of mock data
- **🔄 Async-to-Sync Wrapper**: Proper handling of vim.uv async operations with synchronous RPC interface

### Changed
- **Default Backend Mode**: Plugin now uses real backend by default (no more mock responses)
- **RPC Architecture**: Migrated from mock RPC client to real vim.uv TCP socket communication
- **Connection Logic**: Updated to use vim.uv.new_tcp() for direct backend communication
- **Error Handling**: Enhanced error handling for TCP connection failures and timeouts

### Removed
- **Toggle Commands**: Removed `:ParagonicUseRealBackend` and `:ParagonicUseMockBackend` commands
- **Mock RPC Client**: Eliminated dependency on mock responses for testing
- **External Tool Dependencies**: No longer requires nc, curl, or other external tools for communication

### Technical Details
- Implemented vim.uv.new_tcp() for direct TCP socket creation
- Added synchronous wrapper using vim.wait() for async socket operations
- Enhanced connection detection using self.connected flag instead of is_active()
- Updated RPC client to use real backend by default (vim.g.paragonic_use_real_backend ~= false)
- Improved timeout handling with vim.uv.now() for accurate timing

### Testing
- **Lua Unit Tests**: Updated to work with real backend integration
- **Integration Tests**: Modified to handle real TCP connections instead of mock responses
- **Test Suite Reorganization**: Completed major test cleanup with unit/integration/e2e structure
- **Backend Integration**: All tests now pass with real backend communication

## [0.5.0] - 2025-12-06

### Added
- **🎉 AI Agent Session Integration**: Complete session-aware event system for AI agent collaboration
- **⚡ Real-Time Event Notification System**: Buffer changes, cursor movements, and window events
- **🔧 Enhanced AI Action Functions**: Comprehensive set of actions for editor control
- **🧪 Test-Driven Development**: Systematic TDD implementation with red-green-refactor cycles
- **📊 Session Event History**: Track and retrieve event history from active sessions
- **🔄 Neovim Autocommand Integration**: Automatic event triggering via Neovim events
- **🎯 Session-Aware Handlers**: Event handlers that only execute with active sessions
- **📝 User Commands**: New commands for AI agent actions and event management
- **✅ Comprehensive Test Suite**: Full test coverage for all new features

### Changed
- **Event System Architecture**: Events now require active AI agent sessions
- **Session Management**: Enhanced session context with event tracking
- **Handler Registration**: Updated with session awareness and validation
- **AI Actions**: Enhanced with new parameters and capabilities

### Technical Details
- Added `register_session_aware_handler()` for session-aware event handling
- Implemented `track_event_in_session()` for event history tracking
- Added `get_session_event_history()` for retrieving event history
- Enhanced event triggers with session context and validation
- Implemented autocommand setup for automatic event triggering
- Added comprehensive error handling and validation

## [0.4.0] - 2025-01-XX

### Added
- **🎉 IRAGL Knowledge Management System**: Complete Interleaved Retrieval-Augmented Generation Learning system
- **🗄️ PostgreSQL Integration**: Full database integration with pgvector extension for vector embeddings
- **🔧 KnowledgeStreamProcessor**: Configurable processor with batch processing, validation, and statistics
- **📊 Content Validation**: Robust validation for content types, entity types, and text content
- **⚡ Batch Processing**: Efficient handling of multiple knowledge streams with error recovery
- **📈 Statistics Tracking**: Real-time monitoring of processing metrics and success rates
- **🛡️ Error Handling**: Comprehensive error recovery and reporting with retry mechanisms
- **🔄 Shutdown Management**: Proper resource cleanup and lifecycle management
- **🧠 Enhanced Embedding System**: FastEmbed integration with multiple model support
- **✅ Comprehensive Test Suite**: 10/10 IRAGL tests passing with TDD implementation
- **🔄 Fallback Mode**: Graceful operation without database for testing and development

### Changed
- **Database Architecture**: Migrated to PostgreSQL with pgvector for vector operations
- **Embedding Models**: Updated to latest FastEmbed models (BGESmallENV15, BGELargeENV15, etc.)
- **Testing Strategy**: Implemented test-driven development with red-green-refactor cycles
- **Error Handling**: Enhanced error handling with database fallback capabilities

### Technical Details
- Added `KnowledgeStreamProcessor` with configurable batch sizes and retry logic
- Implemented `ingest_knowledge_stream()` with PostgreSQL and fallback support
- Enhanced database initialization with test configuration support
- Added comprehensive validation for content types and entity types
- Implemented atomic counters for thread-safe statistics tracking
- Added shutdown state management to prevent post-shutdown operations

## [0.3.0] - 2025-01-XX

### Added
- **Enhanced Tool Calling System**: Multi-step tool execution with context awareness
- **Agent Collaboration Engine**: AI agents can now execute complex workflows autonomously
- **File System Tools**: `read_file`, `write_file`, `list_files` operations
- **Iteration Tracking**: Prevents infinite loops with configurable limits (MAX_ITERATIONS: 5)
- **Enhanced Response Format**: Rich JSON responses with tool execution summaries
- **Conversation Context Preservation**: Maintains conversation history across tool calls
- **Tool Result Integration**: Tool outputs are fed back to AI for continued decision-making

### Changed
- **Agent Chat Completion**: Now supports multi-step tool sequences instead of single tool calls
- **Response Format**: Enhanced JSON responses include `tool_calls_executed`, `tool_results`, and `iterations` fields
- **Error Handling**: Improved error reporting with detailed tool failure information

### Technical Details
- Added `execute_enhanced_tool_calling()` method for multi-step sequences
- Enhanced `handle_agent_chat_completion()` to use new tool calling system
- Improved tool call parsing with better regex patterns for multi-line JSON
- Added comprehensive test coverage for enhanced tool calling functionality

## [0.2.0] - 2025-01-XX

### Added
- **Basic Tool Calling**: Initial implementation of agent tool execution
- **File System Integration**: Basic file operations for agent collaboration
- **JSON-RPC Protocol**: Communication between Lua interface and Rust backend
- **Ollama Integration**: AI model interaction for chat completion and embeddings
- **Database Operations**: Full CRUD operations for projects, goals, tasks, and agents
- **Organization Support**: Multi-tenant support with organization_id fields

### Changed
- **Architecture**: Moved from direct Lua-Ollama communication to JSON-RPC backend
- **Database Schema**: Added organization support and improved data models
- **Error Handling**: Comprehensive error handling with detailed RPC error responses

## [0.1.0] - 2025-01-XX

### Added
- **Initial Release**: Basic Neovim plugin structure
- **Lua Interface**: Initial Lua-based communication with Ollama
- **Basic Chat**: Simple chat completion functionality
- **Project Foundation**: Core project structure and documentation

---

## Version History

- **0.5.0**: AI Agent Session Integration & Real-Time Events
- **0.4.0**: IRAGL Knowledge Management & PostgreSQL Integration
- **0.3.0**: Enhanced Tool Calling & Agent Collaboration
- **0.2.0**: JSON-RPC Backend & File System Tools  
- **0.1.0**: Initial Release & Basic Chat 