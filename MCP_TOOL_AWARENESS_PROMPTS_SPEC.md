# MCP Tool Awareness Prompts Specification

## Overview

This specification defines the implementation of MCP (Model Context Protocol) tool awareness prompts that will be automatically injected into model conversations to ensure AI models understand their capabilities to interact with the Neovim client through available MCP tools.

## Problem Statement

Currently, AI models in Paragonic chat sessions may not be aware of the MCP tools available to them for interacting with Neovim. This leads to:
- Models suggesting manual actions instead of using available tools
- Inconsistent tool usage patterns
- Reduced efficiency in Neovim integration
- Users having to manually instruct models to use specific tools

## Goals

1. **Automatic Tool Awareness**: Models should automatically understand available MCP tools without explicit user instruction
2. **Contextual Tool Recommendations**: Tool awareness should be contextual to the current conversation and user intent
3. **Seamless Integration**: Tool prompts should integrate naturally with existing chat flow
4. **Pattern-Aware Suggestions**: Tool recommendations should align with current pattern execution context
5. **Performance Optimization**: Tool awareness should not significantly impact response times

## Technical Requirements

### 1. Prompt Injection System

#### 1.1 Dynamic Prompt Construction
- **Location**: `lua/paragonic/mcp_tool_prompts.lua` (new module)
- **Function**: Automatically construct tool awareness prompts based on:
  - Available MCP tools
  - Current conversation context
  - Active patterns
  - User intent (derived from message content)

#### 1.2 Prompt Templates
Create structured prompt templates for different scenarios:

```lua
-- Base tool awareness template
local BASE_TOOL_PROMPT = [[
You have access to the following Neovim integration tools through MCP (Model Context Protocol):

{tool_list}

When appropriate, use these tools to interact directly with Neovim instead of suggesting manual actions.
]]

-- Contextual tool prompt template
local CONTEXTUAL_TOOL_PROMPT = [[
Based on your request, you can use these specific tools:

{relevant_tools}

{usage_guidance}
]]
```

### 2. Tool Discovery and Classification

#### 2.1 Tool Registry Integration
- **Source**: `lua/paragonic/mcp.lua` - existing tool definitions
- **Function**: Extract tool metadata including:
  - Tool name and description
  - Input schema and parameters
  - Pattern relationships
  - Usage guidance
  - Success metrics

#### 2.2 Tool Categorization
Classify tools into functional categories:
- **File Operations**: `agent_edit_file`, `agent_create_file`, `agent_save_file`
- **Session Management**: Session info, buffer management
- **Pattern Execution**: Pattern-aware operations
- **Search and Navigation**: File search, buffer navigation

### 3. Context Analysis System

#### 3.1 Intent Detection
- **Input**: User message content
- **Output**: Detected intent categories:
  - File editing/modification
  - File creation
  - File saving
  - Session management
  - Pattern execution
  - Search operations

#### 3.2 Context Extraction
Extract relevant context from:
- Current buffer information
- Active patterns
- Recent tool usage
- Session state

### 4. Prompt Integration Points

#### 4.1 Chat Module Integration
- **File**: `lua/paragonic/chat.lua`
- **Integration Point**: Before sending messages to models
- **Function**: Inject tool awareness prompts into message context

#### 4.2 Backend Integration
- **File**: `lua/paragonic/backend.lua`
- **Integration Point**: In `chat_completion` and `streaming_chat_completion` functions
- **Function**: Append tool awareness to system messages

#### 4.3 MCP Thinking Support Integration
- **File**: `lua/paragonic/mcp_thinking_support.lua`
- **Integration Point**: In completion and sampling functions
- **Function**: Include tool awareness in thinking model prompts

## Implementation Plan

### Phase 1: Core Infrastructure (Week 1)

#### 1.1 Create MCP Tool Prompts Module
```lua
-- lua/paragonic/mcp_tool_prompts.lua
local M = {}

-- Tool prompt templates
M.prompt_templates = {
    base_tool_awareness = [[
You are an AI assistant with direct access to Neovim through MCP tools.
Available tools: {tool_list}
Use these tools when appropriate instead of suggesting manual actions.
    ]],
    
    contextual_tools = [[
For this request, consider using: {relevant_tools}
{usage_guidance}
    ]],
    
    pattern_aware = [[
Current pattern context: {pattern_context}
Recommended tools for this pattern: {pattern_tools}
    ]]
}

-- Tool categorization
M.tool_categories = {
    file_operations = {"agent_edit_file", "agent_create_file", "agent_save_file"},
    session_management = {"agent_session_info"},
    pattern_execution = {"pattern_execute", "pattern_status"},
    search_navigation = {"file_search", "buffer_navigate"}
}

-- Intent detection patterns
M.intent_patterns = {
    file_editing = {"edit", "modify", "change", "update", "fix"},
    file_creation = {"create", "new", "add", "make"},
    file_saving = {"save", "persist", "write"},
    session_management = {"session", "buffer", "window"},
    pattern_execution = {"pattern", "execute", "run"}
}
```

#### 1.2 Tool Discovery Functions
```lua
function M.get_available_tools()
    -- Extract tools from MCP module
end

function M.categorize_tools(tools)
    -- Categorize tools by function
end

function M.detect_user_intent(message)
    -- Analyze message for intent patterns
end
```

#### 1.3 Context Analysis Functions
```lua
function M.extract_conversation_context()
    -- Get current conversation state
end

function M.get_active_patterns()
    -- Get currently active patterns
end

function M.get_buffer_context()
    -- Get current buffer information
end
```

### Phase 2: Prompt Construction (Week 2)

#### 2.1 Dynamic Prompt Builder
```lua
function M.build_tool_awareness_prompt(user_message, context)
    local intent = M.detect_user_intent(user_message)
    local relevant_tools = M.get_relevant_tools(intent, context)
    local pattern_context = M.get_pattern_context(context)
    
    return M.construct_prompt(intent, relevant_tools, pattern_context)
end
```

#### 2.2 Contextual Tool Selection
```lua
function M.get_relevant_tools(intent, context)
    -- Select tools based on intent and context
end

function M.get_tool_usage_guidance(tools, intent)
    -- Generate usage guidance for selected tools
end
```

### Phase 3: Integration (Week 3)

#### 3.1 Chat Module Integration
```lua
-- In lua/paragonic/chat.lua
local mcp_tool_prompts = require("paragonic.mcp_tool_prompts")

-- Modify message sending to include tool awareness
function M.send_message_with_tool_awareness(message)
    local tool_prompt = mcp_tool_prompts.build_tool_awareness_prompt(message, context)
    local enhanced_message = tool_prompt .. "\n\n" .. message
    return backend.chat_completion(model, enhanced_message)
end
```

#### 3.2 Backend Integration
```lua
-- In lua/paragonic/backend.lua
function client:chat_completion_with_tool_awareness(model, message)
    local tool_prompt = mcp_tool_prompts.build_tool_awareness_prompt(message, context)
    local enhanced_message = tool_prompt .. "\n\n" .. message
    
    return self:chat_completion(model, enhanced_message)
end
```

### Phase 4: Testing and Optimization (Week 4)

#### 4.1 Unit Tests
```lua
-- tests/unit/mcp/test_mcp_tool_prompts.lua
function M.test_tool_discovery()
    -- Test tool discovery and categorization
end

function M.test_intent_detection()
    -- Test user intent detection
end

function M.test_prompt_construction()
    -- Test prompt building
end
```

#### 4.2 Integration Tests
```lua
-- tests/integration/mcp/test_tool_awareness_integration.lua
function M.test_chat_integration()
    -- Test chat module integration
end

function M.test_backend_integration()
    -- Test backend integration
end
```

## Tool-Specific Prompts

### File Operation Tools

#### agent_edit_file
```
You can directly edit files using the agent_edit_file tool:
- Specify file_path and line_number
- Provide content to insert/replace
- Use for code modifications, text changes, or file updates
```

#### agent_create_file
```
You can create new files using the agent_create_file tool:
- Specify file_name for the new file
- Provide initial content if needed
- Set open_in_window to true to open immediately
```

#### agent_save_file
```
You can save files using the agent_save_file tool:
- Save current buffer or specified file_path
- Use force=true for read-only files
- Essential for persisting changes
```

### Session Management Tools

#### agent_session_info
```
You can get session information using the agent_session_info tool:
- Current buffer and file information
- Session duration and activity
- Recent interactions and context
```

## Pattern-Aware Prompts

### Session Summary Generation Pattern
```
Current pattern: Session Summary Generation
Available tools: agent_edit_file, agent_create_file, agent_save_file
Use these tools to create and modify summary files during pattern execution.
```

### Activity Labeling Pattern
```
Current pattern: Activity Labeling
Available tools: agent_edit_file, agent_save_file
Use these tools to track and label file modifications and activities.
```

### Knowledge Extraction Pattern
```
Current pattern: Knowledge Extraction
Available tools: agent_create_file, agent_edit_file
Use these tools to create files for storing extracted knowledge and insights.
```

## Configuration Options

### Prompt Customization
```lua
-- In config.lua
M.tool_awareness_config = {
    enabled = true,
    prompt_style = "contextual", -- "base", "contextual", "minimal"
    include_pattern_context = true,
    include_usage_guidance = true,
    max_tools_per_prompt = 5,
    intent_detection_threshold = 0.7
}
```

### Tool Filtering
```lua
M.tool_filtering = {
    exclude_tools = {}, -- Tools to exclude from prompts
    include_only = {}, -- Only include specific tools
    category_filters = { -- Filter by category
        file_operations = true,
        session_management = true,
        pattern_execution = true,
        search_navigation = false
    }
}
```

## Performance Considerations

### 1. Prompt Caching
- Cache constructed prompts for similar contexts
- Implement LRU cache with configurable size
- Invalidate cache when tools or patterns change

### 2. Lazy Loading
- Load tool information only when needed
- Defer pattern context extraction until required
- Minimize prompt construction overhead

### 3. Prompt Length Optimization
- Limit prompt length to prevent token waste
- Use concise tool descriptions
- Prioritize most relevant tools

## Success Metrics

### 1. Tool Usage Tracking
- Track tool usage frequency before/after implementation
- Measure tool suggestion accuracy
- Monitor user satisfaction with tool suggestions

### 2. Response Quality
- Measure response relevance with tool awareness
- Track reduction in manual action suggestions
- Monitor pattern execution efficiency

### 3. Performance Metrics
- Measure prompt construction time
- Track memory usage impact
- Monitor response generation time

## Testing Strategy

### 1. Unit Tests
- Tool discovery and categorization
- Intent detection accuracy
- Prompt construction logic
- Context extraction functions

### 2. Integration Tests
- Chat module integration
- Backend integration
- MCP thinking support integration
- Pattern-aware prompt generation

### 3. End-to-End Tests
- Complete chat flow with tool awareness
- Tool usage in real conversations
- Pattern execution with tool prompts
- Performance under load

## Migration Plan

### 1. Gradual Rollout
- Implement behind feature flag
- Enable for specific user groups first
- Monitor performance and usage patterns

### 2. Backward Compatibility
- Maintain existing chat functionality
- Allow disabling tool awareness
- Provide fallback to current behavior

### 3. User Feedback Integration
- Collect feedback on tool suggestions
- Adjust prompt styles based on usage
- Refine intent detection patterns

## Future Enhancements

### 1. Machine Learning Integration
- Learn from user tool usage patterns
- Improve intent detection accuracy
- Personalized tool recommendations

### 2. Advanced Context Analysis
- Semantic analysis of user messages
- Cross-session context awareness
- Predictive tool suggestions

### 3. Tool Usage Optimization
- Suggest tool combinations
- Optimize tool parameter selection
- Learn from successful tool usage patterns

## Dependencies

### Internal Dependencies
- `lua/paragonic/mcp.lua` - Tool definitions and metadata
- `lua/paragonic/chat.lua` - Chat module integration
- `lua/paragonic/backend.lua` - Backend integration
- `lua/paragonic/mcp_thinking_support.lua` - Thinking model support

### External Dependencies
- No new external dependencies required
- Uses existing Neovim APIs
- Leverages current MCP infrastructure

## Risk Assessment

### 1. Performance Impact
- **Risk**: Increased response time due to prompt construction
- **Mitigation**: Implement caching and lazy loading
- **Monitoring**: Track response time metrics

### 2. Tool Suggestion Accuracy
- **Risk**: Incorrect tool suggestions leading to confusion
- **Mitigation**: Implement intent detection validation
- **Monitoring**: Track tool usage success rates

### 3. User Experience
- **Risk**: Overwhelming users with too many tool suggestions
- **Mitigation**: Limit suggestions and provide configuration options
- **Monitoring**: Collect user feedback and adjust accordingly

## Conclusion

This specification provides a comprehensive plan for implementing MCP tool awareness prompts in Paragonic. The implementation will enhance the AI model's understanding of available Neovim integration capabilities, leading to more efficient and contextually appropriate tool usage.

The phased approach ensures gradual integration with existing systems while maintaining backward compatibility and performance. The pattern-aware design aligns with Paragonic's existing pattern execution system, providing a cohesive user experience.

Success will be measured through improved tool usage rates, enhanced response quality, and positive user feedback. The modular design allows for future enhancements and optimizations based on real-world usage patterns.
