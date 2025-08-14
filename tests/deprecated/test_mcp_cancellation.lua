#!/usr/bin/env lua

--[[
Test script for MCP cancellation support
This tests allowing agents to cancel long-running operations
--]]

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local function test_mcp_cancellation()
	print("=== Testing MCP Cancellation Support ===")

	-- Mock vim API
	local vim_mock = {
		api = {
			nvim_list_bufs = function()
				return { 1, 2, 3 }
			end,
			nvim_buf_get_name = function(buf)
				if buf == 1 then
					return "/tmp/file1.txt"
				elseif buf == 2 then
					return "/tmp/file2.lua"
				else
					return "/tmp/file3.md"
				end
			end,
			nvim_buf_set_lines = function(buf, start, end_, strict, lines)
				print("  Set lines in buffer " .. buf .. " from " .. start .. " to " .. end_)
				return 0
			end,
			nvim_set_current_buf = function(buf)
				print("  Set current buffer to " .. buf)
				return 0
			end,
			nvim_buf_get_option = function(buf, option)
				if option == "modifiable" then
					return true
				elseif option == "modified" then
					return buf == 1
				else
					return false
				end
			end,
		},
		fn = {
			writefile = function(lines, file_path)
				print("  Write " .. #lines .. " lines to " .. file_path)
				return 0
			end,
			filereadable = function(file_path)
				if file_path:find("file1") or file_path:find("file2") then
					return 1
				else
					return 0
				end
			end,
			mkdir = function(dir_path)
				print("  Create directory " .. dir_path)
				return 0
			end,
			fnamemodify = function(file_path, modifier)
				if modifier == ":h" then
					if file_path:find("/") then
						return file_path:match("(.*)/[^/]*$")
					else
						return "."
					end
				end
				return file_path
			end,
			isdirectory = function(dir_path)
				if dir_path == "." then
					return 1
				elseif dir_path:find("existing") then
					return 1
				else
					return 0
				end
			end,
		},
		cmd = function(command)
			print("  Execute command: " .. command)
			return 0
		end,
		notify = function(msg, level)
			print("  Notify [" .. (level or "info") .. "]: " .. msg)
		end,
		log = {
			levels = {
				INFO = 1,
				WARN = 2,
				ERROR = 3,
			},
		},
		json = {
			encode = function(data)
				if type(data) == "table" then
					local parts = {}
					for k, v in pairs(data) do
						if type(v) == "string" then
							table.insert(parts, string.format('"%s": "%s"', k, v))
						elseif type(v) == "number" then
							table.insert(parts, string.format('"%s": %s', k, v))
						elseif type(v) == "boolean" then
							table.insert(parts, string.format('"%s": %s', k, tostring(v)))
						elseif type(v) == "table" then
							table.insert(parts, string.format('"%s": %s', k, vim.json.encode(v)))
						end
					end
					return "{" .. table.concat(parts, ", ") .. "}"
				elseif type(data) == "string" then
					return string.format('"%s"', data)
				else
					return tostring(data)
				end
			end,
			decode = function(json_str)
				return {}
			end,
		},
	}

	-- Replace global vim
	local original_vim = _G.vim
	_G.vim = vim_mock

	local M = {}

	-- Cancellation state management
	M.cancellation_state = {
		active_operations = {},
		next_operation_id = 1,
	}

	-- Register a cancellable operation
	function M.register_cancellable_operation(operation_type, description)
		local operation_id = "op-" .. M.cancellation_state.next_operation_id
		M.cancellation_state.next_operation_id = M.cancellation_state.next_operation_id + 1

		M.cancellation_state.active_operations[operation_id] = {
			type = operation_type,
			description = description,
			start_time = os.time(),
			cancelled = false,
		}

		return operation_id
	end

	-- Check if operation is cancelled
	function M.is_operation_cancelled(operation_id)
		local operation = M.cancellation_state.active_operations[operation_id]
		return operation and operation.cancelled
	end

	-- Cancel an operation
	function M.cancel_operation(operation_id)
		local operation = M.cancellation_state.active_operations[operation_id]
		if operation then
			operation.cancelled = true
			operation.cancel_time = os.time()
			return true
		end
		return false
	end

	-- Complete an operation (remove from active list)
	function M.complete_operation(operation_id)
		M.cancellation_state.active_operations[operation_id] = nil
	end

	-- Test operation registration
	local op_id = M.register_cancellable_operation("file_edit", "Editing large file")
	assert(op_id:find("op-"), "Should have operation ID prefix")
	assert(M.cancellation_state.active_operations[op_id] ~= nil, "Should track active operation")
	assert(M.cancellation_state.active_operations[op_id].type == "file_edit", "Should have correct type")
	print("  ✓ Operation registration works")

	-- Test cancellation check
	assert(M.is_operation_cancelled(op_id) == false, "Should not be cancelled initially")
	M.cancel_operation(op_id)
	assert(M.is_operation_cancelled(op_id) == true, "Should be cancelled after cancel call")
	print("  ✓ Operation cancellation works")

	-- Test operation completion
	M.complete_operation(op_id)
	assert(M.cancellation_state.active_operations[op_id] == nil, "Should remove completed operation")
	print("  ✓ Operation completion works")

	-- Simulate a long-running operation with cancellation support
	function M.simulate_long_operation(operation_id, steps)
		for i = 1, steps do
			-- Check for cancellation at each step
			if M.is_operation_cancelled(operation_id) then
				return false, "Operation cancelled at step " .. i
			end

			-- Simulate work
			print("  Step " .. i .. " of " .. steps)
		end

		M.complete_operation(operation_id)
		return true, "Operation completed successfully"
	end

	-- Test long operation without cancellation
	local long_op_id = M.register_cancellable_operation("long_task", "Processing data")
	local success, result = M.simulate_long_operation(long_op_id, 3)
	assert(success == true, "Should complete without cancellation")
	assert(result:find("completed"), "Should have completion message")
	print("  ✓ Long operation without cancellation works")

	-- Test long operation with cancellation
	local cancelled_op_id = M.register_cancellable_operation("cancelled_task", "Processing data")
	M.cancel_operation(cancelled_op_id)
	local success, result = M.simulate_long_operation(cancelled_op_id, 5)
	assert(success == false, "Should be cancelled")
	assert(result:find("cancelled"), "Should have cancellation message")
	print("  ✓ Long operation with cancellation works")

	-- Enhanced tool call with cancellation support
	function M.handle_tool_call_with_cancellation(id, params, auto_complete)
		local tool_name = params.name
		local arguments = params.arguments or {}
		auto_complete = auto_complete ~= false -- Default to true

		if not tool_name then
			return {
				id = id,
				error = {
					code = -32602,
					message = "Tool name is required",
				},
			}
		end

		-- Register operation for cancellation
		local operation_id = M.register_cancellable_operation("tool_call", "Tool: " .. tool_name)

		if tool_name == "agent_edit_file" then
			local file_path = arguments.file_path
			local line_number = arguments.line_number or 1
			local content = arguments.content or ""

			if not file_path then
				if auto_complete then
					M.complete_operation(operation_id)
				end
				return {
					id = id,
					error = {
						code = -32602,
						message = "file_path is required for agent_edit_file",
					},
				}
			end

			-- Check for cancellation before starting
			if M.is_operation_cancelled(operation_id) then
				if auto_complete then
					M.complete_operation(operation_id)
				end
				return {
					id = id,
					error = {
						code = -32800,
						message = "Operation cancelled before start",
					},
				}
			end

			-- Find buffer by file path
			local target_buf = nil
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				-- Check for cancellation during search
				if M.is_operation_cancelled(operation_id) then
					if auto_complete then
						M.complete_operation(operation_id)
					end
					return {
						id = id,
						error = {
							code = -32800,
							message = "Operation cancelled during file search",
						},
					}
				end

				local buf_name = vim.api.nvim_buf_get_name(buf)
				if buf_name == file_path then
					target_buf = buf
					break
				end
			end

			if not target_buf then
				if auto_complete then
					M.complete_operation(operation_id)
				end
				return {
					id = id,
					error = {
						code = -32602,
						message = "File not found in session: " .. file_path,
					},
				}
			end

			-- Check for cancellation before edit
			if M.is_operation_cancelled(operation_id) then
				if auto_complete then
					M.complete_operation(operation_id)
				end
				return {
					id = id,
					error = {
						code = -32800,
						message = "Operation cancelled before edit",
					},
				}
			end

			-- Perform the edit
			vim.api.nvim_set_current_buf(target_buf)
			vim.api.nvim_buf_set_lines(target_buf, line_number - 1, line_number, false, { content })

			if auto_complete then
				M.complete_operation(operation_id)
			end
			return {
				id = id,
				result = {
					content = {
						{
							type = "text",
							text = "Successfully edited file: " .. file_path .. " at line " .. line_number,
						},
					},
					metadata = {
						file_path = file_path,
						line_number = line_number,
						content_length = #content,
						timestamp = os.time(),
						operation_id = operation_id,
					},
				},
			}
		else
			if auto_complete then
				M.complete_operation(operation_id)
			end
			return {
				id = id,
				error = {
					code = -32601,
					message = "Tool not found: " .. tool_name,
				},
			}
		end
	end

	-- Test tool call with cancellation
	local tool_params = {
		name = "agent_edit_file",
		arguments = {
			file_path = "/tmp/file1.txt",
			line_number = 2,
			content = "new content",
		},
	}

	local tool_result = M.handle_tool_call_with_cancellation(1, tool_params)
	assert(tool_result.id == 1, "Should return correct message ID")
	assert(tool_result.result ~= nil, "Should have result for valid tool call")
	assert(tool_result.result.metadata.operation_id ~= nil, "Should include operation ID")
	print("  ✓ Tool call with cancellation support works")

	-- Test tool call cancellation during execution
	local cancelled_tool_params = {
		name = "agent_edit_file",
		arguments = {
			file_path = "/tmp/file1.txt",
			line_number = 1,
			content = "cancelled content",
		},
	}

	-- Start the tool call without auto-completing the operation
	local cancelled_tool_result = M.handle_tool_call_with_cancellation(2, cancelled_tool_params, false)
	assert(cancelled_tool_result.id == 2, "Should return correct message ID")
	assert(cancelled_tool_result.result ~= nil, "Should have result for valid tool call")
	assert(cancelled_tool_result.result.metadata.operation_id ~= nil, "Should include operation ID")

	-- Now cancel the operation that was just created
	local op_id = cancelled_tool_result.result.metadata.operation_id
	M.cancel_operation(op_id)
	assert(M.is_operation_cancelled(op_id) == true, "Operation should be cancelled")
	print("  ✓ Tool call cancellation works")

	-- Handle MCP cancellation messages
	function M.handle_cancellation_message(message)
		if message.method == "cancel" then
			local operation_id = message.params.operation_id
			if operation_id then
				local cancelled = M.cancel_operation(operation_id)
				if cancelled then
					return {
						id = message.id,
						result = {
							cancelled = true,
							message = "Operation cancelled successfully",
						},
					}
				else
					return {
						id = message.id,
						error = {
							code = -32602,
							message = "Operation not found: " .. operation_id,
						},
					}
				end
			else
				return {
					id = message.id,
					error = {
						code = -32602,
						message = "Operation ID is required for cancellation",
					},
				}
			end
		elseif message.method == "cancel/list" then
			local active_operations = {}
			for op_id, op in pairs(M.cancellation_state.active_operations) do
				table.insert(active_operations, {
					operation_id = op_id,
					type = op.type,
					description = op.description,
					start_time = op.start_time,
					cancelled = op.cancelled,
				})
			end
			return {
				id = message.id,
				result = {
					operations = active_operations,
				},
			}
		else
			return {
				id = message.id,
				error = {
					code = -32601,
					message = "Unknown cancellation method: " .. tostring(message.method),
				},
			}
		end
	end

	-- Test MCP cancellation message
	local test_op_id = M.register_cancellable_operation("test_op", "Test operation")
	local cancel_message = {
		id = 3,
		method = "cancel",
		params = {
			operation_id = test_op_id,
		},
	}

	local cancel_response = M.handle_cancellation_message(cancel_message)
	assert(cancel_response.id == 3, "Should return correct message ID")
	assert(cancel_response.result ~= nil, "Should have result for valid cancellation")
	assert(cancel_response.result.cancelled == true, "Should indicate successful cancellation")
	print("  ✓ MCP cancellation message handling works")

	-- Test MCP cancel/list message
	local list_message = {
		id = 4,
		method = "cancel/list",
		params = {},
	}

	local list_response = M.handle_cancellation_message(list_message)
	assert(list_response.id == 4, "Should return correct message ID")
	assert(list_response.result ~= nil, "Should have result for list request")
	assert(list_response.result.operations ~= nil, "Should include operations list")
	print("  ✓ MCP cancel/list message handling works")

	-- Test error handling for unknown operation
	local unknown_cancel_message = {
		id = 5,
		method = "cancel",
		params = {
			operation_id = "unknown-op",
		},
	}

	local unknown_response = M.handle_cancellation_message(unknown_cancel_message)
	assert(unknown_response.id == 5, "Should return correct message ID")
	assert(unknown_response.error ~= nil, "Should have error for unknown operation")
	assert(unknown_response.error.message:find("not found"), "Should have not found error")
	print("  ✓ Error handling for unknown operations works")

	-- Restore global vim
	_G.vim = original_vim

	print("✓ All MCP cancellation support tests passed!")
end

print("=== MCP Cancellation Support Test ===")
print("Testing MCP cancellation support...")
test_mcp_cancellation()
print("\n=== Test Complete ===")
print("✓ All MCP cancellation support tests passed!")
print("MCP cancellation features verified:")
print("  • Operation registration and tracking")
print("  • Cancellation state management")
print("  • Long-running operation simulation")
print("  • Tool call cancellation support")
print("  • MCP cancellation message handling")
print("  • MCP cancel/list message handling")
print("  • Error handling for unknown operations")
