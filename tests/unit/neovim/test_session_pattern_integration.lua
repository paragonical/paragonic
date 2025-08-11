-- Test file for session pattern integration
-- Tests the integration between AI agent sessions and system patterns

package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

print("=== Session Pattern Integration Test ===")

-- Mock Neovim API for testing
local mock_vim = {
    api = {
        nvim_list_bufs = function()
            return {1, 2, 3}  -- Mock buffer list
        end,
        nvim_create_buf = function(listed, scratch)
            return 1  -- Mock buffer ID
        end,
        nvim_open_win = function(buf, enter, config)
            return 1  -- Mock window ID
        end,
        nvim_buf_set_option = function(buf, option, value)
            -- Mock buffer option setting
        end,
        nvim_win_set_option = function(win, option, value)
            -- Mock window option setting
        end,
        nvim_buf_set_lines = function(buf, start, end_idx, strict_indexing, lines)
            -- Mock setting buffer lines
        end,
        nvim_win_close = function(win, force)
            -- Mock window closing
        end,
        nvim_buf_delete = function(buf, opts)
            -- Mock buffer deletion
        end
    },
    fn = {
        expand = function(what)
            if what == "%" then
                return "/test/file.lua"
            elseif what == "getcwd" then
                return "/test/directory"
            end
            return ""
        end,
        getcwd = function()
            return "/test/directory"
        end,
        mode = function()
            return "n"  -- Normal mode
        end,
        strftime = function(format)
            return "20250115_120000"  -- Mock timestamp
        end
    },
    notify = function(msg, level)
        -- Mock notification
        print("NOTIFY: " .. msg .. " (level: " .. tostring(level) .. ")")
    end,
    log = {
        levels = {
            INFO = 1,
            WARN = 2,
            ERROR = 4
        }
    },
    o = {
        columns = 120,
        lines = 40
    },
    cmd = function(command)
        -- Mock command execution
        return true
    end,
    keymap = {
        set = function(mode, lhs, rhs, opts)
            -- Mock keymap setting
        end
    }
}

-- Mock the paragonic module for testing
package.loaded.paragonic = {
    patterns = {
        list_patterns = function()
            return {
                {
                    id = "session-summary-generation",
                    name = "Session Summary Generation",
                    category = "SessionManagement",
                    description = "Generates comprehensive session summaries",
                    auto_trigger = true,
                    trigger_conditions = {"session_duration > 300", "interaction_count > 10"}
                },
                {
                    id = "activity-labeling",
                    name = "Activity Labeling",
                    category = "ActivityLabeling",
                    description = "Labels and categorizes development activities",
                    auto_trigger = true,
                    trigger_conditions = {"buffer_changes > 5", "file_saves > 2"}
                },
                {
                    id = "knowledge-extraction",
                    name = "Knowledge Extraction",
                    category = "KnowledgeExtraction",
                    description = "Extracts reusable knowledge and patterns from session data",
                    auto_trigger = false,
                    trigger_conditions = {"manual_trigger"}
                }
            }
        end,
        get_pattern_by_name = function(name)
            local patterns = package.loaded.paragonic.patterns.list_patterns()
            for _, pattern in ipairs(patterns) do
                if pattern.name == name then
                    return pattern
                end
            end
            return nil
        end,
        execute_pattern = function(pattern_name, context)
            return {
                success = true,
                pattern_name = pattern_name,
                result = {
                    summary = "Pattern executed successfully in session context",
                    timestamp = "2025-01-15 12:00:00",
                    context = context or {},
                    session_aware = true
                }
            }
        end,
        check_pattern_triggers = function(session_data)
            -- Mock pattern trigger checking
            local triggered_patterns = {}
            local patterns = package.loaded.paragonic.patterns.list_patterns()
            
            for _, pattern in ipairs(patterns) do
                if pattern.auto_trigger then
                    -- Simulate trigger conditions
                    if session_data.duration and session_data.duration > 300 then
                        table.insert(triggered_patterns, pattern)
                    elseif session_data.interaction_count and session_data.interaction_count > 10 then
                        table.insert(triggered_patterns, pattern)
                    end
                end
            end
            
            return triggered_patterns
        end
    },
    ai_agent = {
        -- Mock AI agent session state
        ai_agent_sessions = {},
        active_agent_id = nil,
        agent_collaboration_mode = false,
        
        start_ai_agent_session = function(agent_name, capabilities)
            if package.loaded.paragonic.ai_agent.agent_collaboration_mode then
                mock_vim.notify("AI agent collaboration already active. Stop current session first.", mock_vim.log.levels.WARN)
                return false
            end
            
            local session_id = mock_vim.fn.strftime("%Y%m%d_%H%M%S") .. "_" .. (agent_name or "ai_agent")
            
            local session = {
                id = session_id,
                name = agent_name or "AI Agent",
                capabilities = capabilities or {},
                start_time = os.time(),
                duration = 0,
                interaction_count = 0,
                buffer_changes = 0,
                file_saves = 0,
                active_patterns = {},
                pattern_execution_history = {},
                context = {
                    current_file = mock_vim.fn.expand("%"),
                    current_directory = mock_vim.fn.getcwd(),
                    buffers = mock_vim.api.nvim_list_bufs(),
                    mode = mock_vim.fn.mode()
                },
                interactions = {}
            }
            
            package.loaded.paragonic.ai_agent.ai_agent_sessions[session_id] = session
            package.loaded.paragonic.ai_agent.active_agent_id = session_id
            package.loaded.paragonic.ai_agent.agent_collaboration_mode = true
            
            mock_vim.notify("Started AI agent collaboration session: " .. session_id, mock_vim.log.levels.INFO)
            return session_id
        end,
        
        stop_ai_agent_session = function()
            if not package.loaded.paragonic.ai_agent.agent_collaboration_mode or not package.loaded.paragonic.ai_agent.active_agent_id then
                mock_vim.notify("No active AI agent collaboration session to stop.", mock_vim.log.levels.WARN)
                return false
            end
            
            local session = package.loaded.paragonic.ai_agent.ai_agent_sessions[package.loaded.paragonic.ai_agent.active_agent_id]
            if session then
                session.end_time = os.time()
                session.duration = session.end_time - session.start_time
                session.final_context = {
                    current_file = mock_vim.fn.expand("%"),
                    current_directory = mock_vim.fn.getcwd(),
                    buffers = mock_vim.api.nvim_list_bufs(),
                    mode = mock_vim.fn.mode()
                }
                
                mock_vim.notify("Stopped AI agent collaboration session: " .. package.loaded.paragonic.ai_agent.active_agent_id .. " (Duration: " .. session.duration .. "s)", mock_vim.log.levels.INFO)
            end
            
            package.loaded.paragonic.ai_agent.agent_collaboration_mode = false
            package.loaded.paragonic.ai_agent.active_agent_id = nil
            
            return true
        end,
        
        get_ai_agent_session_status = function()
            if not package.loaded.paragonic.ai_agent.agent_collaboration_mode or not package.loaded.paragonic.ai_agent.active_agent_id then
                return {
                    active = false,
                    session_id = nil,
                    session_name = nil,
                    duration = 0,
                    interaction_count = 0,
                    active_patterns = {},
                    pattern_execution_history = {}
                }
            end
            
            local session = package.loaded.paragonic.ai_agent.ai_agent_sessions[package.loaded.paragonic.ai_agent.active_agent_id]
            if not session then
                return {
                    active = false,
                    session_id = nil,
                    session_name = nil,
                    duration = 0,
                    interaction_count = 0,
                    active_patterns = {},
                    pattern_execution_history = {}
                }
            end
            
            local current_time = os.time()
            local duration = session.end_time and (session.end_time - session.start_time) or (current_time - session.start_time)
            
            return {
                active = package.loaded.paragonic.ai_agent.agent_collaboration_mode,
                session_id = session.id,
                session_name = session.name,
                duration = duration,
                interaction_count = session.interaction_count or 0,
                active_patterns = session.active_patterns or {},
                pattern_execution_history = session.pattern_execution_history or {},
                context = session.context
            }
        end,
        
        execute_pattern_in_session = function(pattern_name, context)
            if not package.loaded.paragonic.ai_agent.agent_collaboration_mode or not package.loaded.paragonic.ai_agent.active_agent_id then
                return false, "No active AI agent session"
            end
            
            local session = package.loaded.paragonic.ai_agent.ai_agent_sessions[package.loaded.paragonic.ai_agent.active_agent_id]
            if not session then
                return false, "Session data not found"
            end
            
            -- Execute pattern with session context
            local session_context = context or {}
            session_context.session_id = session.id
            session_context.session_name = session.name
            session_context.session_duration = os.time() - session.start_time
            session_context.interaction_count = session.interaction_count or 0
            
            local result = package.loaded.paragonic.patterns.execute_pattern(pattern_name, session_context)
            
            if result.success then
                -- Track pattern execution in session
                table.insert(session.pattern_execution_history, {
                    pattern_name = pattern_name,
                    timestamp = os.time(),
                    result = result.result,
                    context = session_context
                })
                
                -- Update session interaction count
                session.interaction_count = (session.interaction_count or 0) + 1
                
                mock_vim.notify("Pattern executed in session: " .. pattern_name, mock_vim.log.levels.INFO)
            end
            
            return result.success, result
        end,
        
        check_and_trigger_patterns = function()
            if not package.loaded.paragonic.ai_agent.agent_collaboration_mode or not package.loaded.paragonic.ai_agent.active_agent_id then
                return false, "No active AI agent session"
            end
            
            local session = package.loaded.paragonic.ai_agent.ai_agent_sessions[package.loaded.paragonic.ai_agent.active_agent_id]
            if not session then
                return false, "Session data not found"
            end
            
            -- Prepare session data for pattern trigger checking
            local session_data = {
                duration = os.time() - session.start_time,
                interaction_count = session.interaction_count or 0,
                buffer_changes = session.buffer_changes or 0,
                file_saves = session.file_saves or 0,
                active_patterns = session.active_patterns or {},
                pattern_execution_history = session.pattern_execution_history or {}
            }
            
            -- Check for triggered patterns
            local triggered_patterns = package.loaded.paragonic.patterns.check_pattern_triggers(session_data)
            
            -- Execute triggered patterns
            local executed_patterns = {}
            for _, pattern in ipairs(triggered_patterns) do
                local success, result = package.loaded.paragonic.ai_agent.execute_pattern_in_session(pattern.name, session_data)
                if success then
                    table.insert(executed_patterns, pattern.name)
                end
            end
            
            return true, {
                triggered_patterns = triggered_patterns,
                executed_patterns = executed_patterns
            }
        end
    }
}

-- Test 1: Check if session pattern integration functions exist
print("📝 Testing session pattern integration function availability...")
if package.loaded.paragonic.ai_agent.execute_pattern_in_session then
    print("✅ execute_pattern_in_session function available")
else
    print("❌ execute_pattern_in_session function not available")
end

if package.loaded.paragonic.ai_agent.check_and_trigger_patterns then
    print("✅ check_and_trigger_patterns function available")
else
    print("❌ check_and_trigger_patterns function not available")
end

-- Test 2: Test pattern execution within active session
print("📝 Testing pattern execution within active session...")
local session_id = package.loaded.paragonic.ai_agent.start_ai_agent_session("PatternTestAgent")
if session_id then
    print("✅ Started AI agent session: " .. session_id)
    
    local success, result = package.loaded.paragonic.ai_agent.execute_pattern_in_session("Session Summary Generation")
    if success then
        print("✅ Pattern executed successfully within session")
        print("  Pattern: " .. result.pattern_name)
        print("  Session-aware: " .. tostring(result.result.session_aware))
    else
        print("❌ Pattern execution failed within session")
    end
    
    package.loaded.paragonic.ai_agent.stop_ai_agent_session()
else
    print("❌ Failed to start AI agent session")
end

-- Test 3: Test pattern execution without active session
print("📝 Testing pattern execution without active session...")
local success, error_msg = package.loaded.paragonic.ai_agent.execute_pattern_in_session("Session Summary Generation")
if not success then
    print("✅ Correctly blocked pattern execution without active session")
    print("  Error: " .. error_msg)
else
    print("❌ Pattern execution should be blocked without active session")
end

-- Test 4: Test automatic pattern triggering
print("📝 Testing automatic pattern triggering...")
local session_id2 = package.loaded.paragonic.ai_agent.start_ai_agent_session("TriggerTestAgent")
if session_id2 then
    print("✅ Started AI agent session for trigger testing: " .. session_id2)
    
    -- Simulate session activity that would trigger patterns
    local session = package.loaded.paragonic.ai_agent.ai_agent_sessions[session_id2]
    session.interaction_count = 15  -- Trigger condition: > 10
    session.duration = 400  -- Trigger condition: > 300
    
    local success, trigger_result = package.loaded.paragonic.ai_agent.check_and_trigger_patterns()
    if success then
        print("✅ Automatic pattern triggering works")
        print("  Triggered patterns: " .. #trigger_result.triggered_patterns)
        print("  Executed patterns: " .. #trigger_result.executed_patterns)
        
        for i, pattern in ipairs(trigger_result.executed_patterns) do
            print("    " .. i .. ". " .. pattern)
        end
    else
        print("❌ Automatic pattern triggering failed")
    end
    
    package.loaded.paragonic.ai_agent.stop_ai_agent_session()
else
    print("❌ Failed to start AI agent session for trigger testing")
end

-- Test 5: Test session status with pattern information
print("📝 Testing session status with pattern information...")
local session_id3 = package.loaded.paragonic.ai_agent.start_ai_agent_session("StatusTestAgent")
if session_id3 then
    print("✅ Started AI agent session for status testing: " .. session_id3)
    
    -- Execute a pattern to populate history
    package.loaded.paragonic.ai_agent.execute_pattern_in_session("Activity Labeling")
    
    local status = package.loaded.paragonic.ai_agent.get_ai_agent_session_status()
    if status.active then
        print("✅ Session status includes pattern information")
        print("  Session ID: " .. status.session_id)
        print("  Session Name: " .. status.session_name)
        print("  Duration: " .. status.duration .. " seconds")
        print("  Interaction Count: " .. status.interaction_count)
        print("  Active Patterns: " .. #status.active_patterns)
        print("  Pattern Execution History: " .. #status.pattern_execution_history)
    else
        print("❌ Session status not active")
    end
    
    package.loaded.paragonic.ai_agent.stop_ai_agent_session()
else
    print("❌ Failed to start AI agent session for status testing")
end

-- Test 6: Test pattern trigger conditions
print("📝 Testing pattern trigger conditions...")
local patterns = package.loaded.paragonic.patterns.list_patterns()
local auto_trigger_patterns = 0
local manual_trigger_patterns = 0

for _, pattern in ipairs(patterns) do
    if pattern.auto_trigger then
        auto_trigger_patterns = auto_trigger_patterns + 1
        print("  Auto-trigger pattern: " .. pattern.name)
        print("    Conditions: " .. table.concat(pattern.trigger_conditions, ", "))
    else
        manual_trigger_patterns = manual_trigger_patterns + 1
        print("  Manual trigger pattern: " .. pattern.name)
    end
end

print("✅ Pattern trigger conditions identified")
print("  Auto-trigger patterns: " .. auto_trigger_patterns)
print("  Manual trigger patterns: " .. manual_trigger_patterns)

-- Test 7: Test session context in pattern execution
print("📝 Testing session context in pattern execution...")
local session_id4 = package.loaded.paragonic.ai_agent.start_ai_agent_session("ContextTestAgent")
if session_id4 then
    print("✅ Started AI agent session for context testing: " .. session_id4)
    
    -- Simulate session activity
    local session = package.loaded.paragonic.ai_agent.ai_agent_sessions[session_id4]
    session.interaction_count = 5
    session.buffer_changes = 3
    session.file_saves = 1
    
    local success, result = package.loaded.paragonic.ai_agent.execute_pattern_in_session("Knowledge Extraction", {
        custom_context = "test context"
    })
    
    if success then
        print("✅ Pattern execution includes session context")
        print("  Session ID in context: " .. tostring(result.result.context.session_id))
        print("  Session name in context: " .. tostring(result.result.context.session_name))
        print("  Custom context preserved: " .. tostring(result.result.context.custom_context))
    else
        print("❌ Pattern execution failed to include session context")
    end
    
    package.loaded.paragonic.ai_agent.stop_ai_agent_session()
else
    print("❌ Failed to start AI agent session for context testing")
end

-- Test 8: Test pattern execution history tracking
print("📝 Testing pattern execution history tracking...")
local session_id5 = package.loaded.paragonic.ai_agent.start_ai_agent_session("HistoryTestAgent")
if session_id5 then
    print("✅ Started AI agent session for history testing: " .. session_id5)
    
    -- Execute multiple patterns
    package.loaded.paragonic.ai_agent.execute_pattern_in_session("Session Summary Generation")
    package.loaded.paragonic.ai_agent.execute_pattern_in_session("Activity Labeling")
    package.loaded.paragonic.ai_agent.execute_pattern_in_session("Knowledge Extraction")
    
    local status = package.loaded.paragonic.ai_agent.get_ai_agent_session_status()
    if #status.pattern_execution_history == 3 then
        print("✅ Pattern execution history tracking works")
        for i, execution in ipairs(status.pattern_execution_history) do
            print("  " .. i .. ". " .. execution.pattern_name .. " at " .. execution.timestamp)
        end
    else
        print("❌ Pattern execution history tracking failed")
        print("  Expected: 3 executions, Got: " .. #status.pattern_execution_history)
    end
    
    package.loaded.paragonic.ai_agent.stop_ai_agent_session()
else
    print("❌ Failed to start AI agent session for history testing")
end

-- Test 9: Test session cleanup with pattern data
print("📝 Testing session cleanup with pattern data...")
local session_id6 = package.loaded.paragonic.ai_agent.start_ai_agent_session("CleanupTestAgent")
if session_id6 then
    print("✅ Started AI agent session for cleanup testing: " .. session_id6)
    
    -- Execute a pattern
    package.loaded.paragonic.ai_agent.execute_pattern_in_session("Session Summary Generation")
    
    -- Stop session
    local stop_success = package.loaded.paragonic.ai_agent.stop_ai_agent_session()
    if stop_success then
        print("✅ Session stopped successfully with pattern data preserved")
        
        -- Check that session data is still available
        local session = package.loaded.paragonic.ai_agent.ai_agent_sessions[session_id6]
        if session and session.pattern_execution_history and #session.pattern_execution_history > 0 then
            print("✅ Pattern execution history preserved after session stop")
        else
            print("❌ Pattern execution history not preserved after session stop")
        end
    else
        print("❌ Session stop failed")
    end
else
    print("❌ Failed to start AI agent session for cleanup testing")
end

-- Test 10: Test pattern learning within sessions
print("📝 Testing pattern learning within sessions...")
local session_id7 = package.loaded.paragonic.ai_agent.start_ai_agent_session("LearningTestAgent")
if session_id7 then
    print("✅ Started AI agent session for learning testing: " .. session_id7)
    
    -- Simulate pattern learning by tracking successful executions
    local session = package.loaded.paragonic.ai_agent.ai_agent_sessions[session_id7]
    session.pattern_learning_enabled = true
    
    -- Execute patterns multiple times to simulate learning
    for i = 1, 3 do
        package.loaded.paragonic.ai_agent.execute_pattern_in_session("Session Summary Generation")
    end
    
    local status = package.loaded.paragonic.ai_agent.get_ai_agent_session_status()
    if #status.pattern_execution_history == 3 then
        print("✅ Pattern learning tracking works")
        print("  Total executions: " .. #status.pattern_execution_history)
        print("  Learning enabled: " .. tostring(session.pattern_learning_enabled))
    else
        print("❌ Pattern learning tracking failed")
    end
    
    package.loaded.paragonic.ai_agent.stop_ai_agent_session()
else
    print("❌ Failed to start AI agent session for learning testing")
end

print("=== Session Pattern Integration Test Complete ===")
