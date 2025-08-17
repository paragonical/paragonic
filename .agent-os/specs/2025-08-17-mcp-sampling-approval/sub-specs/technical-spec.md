# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-17-mcp-sampling-approval/spec.md

> Created: 2025-08-17
> Version: 1.0.0

## Technical Requirements

- Implement MCP sampling/request method handler that receives approval requests from AI agents
- Create user interface components for displaying approval requests and collecting user responses
- Build state management system for tracking pending approvals and their lifecycle
- Integrate approval workflow with existing tool execution system in mcp.lua
- Support both individual tool approvals and batch action approvals
- Implement timeout and cancellation mechanisms for pending approvals
- Provide clear audit trail of all approval decisions and their outcomes
- Integrate AI agent file modifications with Neovim's native undo system
- Provide granular undo/redo control for AI actions without requiring external version control
- Support selective reversion and reapplication of specific AI agent changes

## Approach Options

**Option A:** Extend existing MCP module with approval functionality (Selected)
- Pros: 
  - Leverages existing MCP infrastructure and patterns
  - Maintains consistency with current codebase architecture
  - Reuses existing UI components and notification system
  - Minimal disruption to existing functionality
- Cons:
  - May require refactoring some existing MCP handlers
  - Could increase complexity of the main MCP module

**Option B:** Create separate approval module with MCP integration
- Pros:
  - Clean separation of concerns
  - Independent development and testing
  - Easier to maintain and extend
- Cons:
  - Requires more integration work
  - Potential for code duplication
  - More complex state management across modules

**Rationale:** Option A is selected because it leverages the existing MCP infrastructure and maintains consistency with the current architecture. The approval functionality is inherently part of the MCP protocol handling, so extending the existing module provides better integration and reduces complexity.

## External Dependencies

- **No new external dependencies required** - All functionality will be implemented using existing Neovim APIs and Lua standard library
- **Existing dependencies leveraged:**
  - Neovim UI APIs for notifications and dialogs
  - JSON-RPC 2.0 protocol handling (already implemented)
  - MCP protocol specification compliance

## Architecture Overview

### Core Components

1. **Sampling Request Handler** (`mcp_sampling.lua`)
   - Handles MCP sampling/request method calls
   - Parses approval requests from AI agents
   - Manages approval request lifecycle

2. **Approval UI Manager** (`mcp_approval_ui.lua`)
   - Creates and manages approval notification dialogs
   - Handles user interaction with approval requests
   - Provides feedback to AI agents

3. **Approval State Manager** (`mcp_approval_state.lua`)
   - Tracks pending approval requests
   - Manages approval timeouts and cancellations
   - Maintains audit trail of decisions

4. **Tool Execution Integration** (extensions to `mcp.lua`)
   - Integrates approval workflow with existing tool execution
   - Provides hooks for approval-required tool calls
   - Handles approval bypass for auto-approved tools

5. **Neovim Undo Integration** (`mcp_undo_integration.lua`)
   - Integrates AI agent file modifications with Neovim's undo tree
   - Provides granular undo/redo control for AI actions
   - Supports selective reversion of specific AI changes
   - Maintains undo tree integrity and performance

### Data Flow

1. AI agent sends MCP sampling/request with approval details
2. Sampling handler receives request and creates approval UI
3. User reviews request and provides decision (approve/deny/modify)
4. Approval state manager updates request status
5. Tool execution proceeds or is cancelled based on user decision
6. File modifications are integrated with Neovim's undo tree
7. Users can selectively undo/redo AI actions using standard Neovim commands
8. Audit trail is updated with decision and outcome

### Integration Points

- **MCP Protocol Layer:** Extends existing MCP message handling
- **UI Layer:** Integrates with existing notification and dialog systems
- **Tool Execution Layer:** Hooks into existing tool call processing
- **State Management:** Extends existing MCP state tracking
- **Neovim Undo System:** Integrates with native undo tree and commands
- **File System Layer:** Hooks into file modification operations

## Security Considerations

- All approval requests must be validated for security implications
- User consent is explicitly required for all tool executions
- Approval requests have configurable timeouts to prevent hanging
- Audit trail maintains complete record of all decisions
- No automatic bypass of approval requirements without explicit user configuration
