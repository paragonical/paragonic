--[[
Paragonic Search Module
Handles search functionality, search history, and saved searches
--]]

local M = {}

-- Search history and saved searches
local search_history = {}
local saved_searches = {}
local max_history_size = 50

-- AI-powered search enhancement
local search_insights = {}
local context_cache = {}
local suggestion_cache = {}

-- Enhanced search command with better UX
function M.quick_search()
	local query = vim.fn.input("🔍 Search: ")
	if query == "" then
		return
	end

	-- Perform search
	local results, err = M.search_embeddings(query, 10)
	if not results then
		vim.notify("Search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Add to search history
	M.add_to_search_history(query, "basic", results.results and #results.results or 0)

	-- Display results in a floating window
	M.display_search_results(results, "Quick Search: " .. query)
end

-- Enhanced filtered search with content type selection
function M.quick_filtered_search()
	local query = vim.fn.input("🔍 Search: ")
	if query == "" then
		return
	end

	-- Content type selection
	local content_types = { "project", "task", "note", "code", "document" }
	local content_type = vim.fn.input("📁 Content Type (project/task/note/code/document): ")

	-- Perform filtered search
	local results, err = M.find_similar_content(query, content_type ~= "" and content_type or nil, 10, 0.0)
	if not results then
		vim.notify("Filtered search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Add to search history
	M.add_to_search_history(query, "filtered", results.results and #results.results or 0)

	-- Display results in a floating window
	M.display_search_results(results, "Filtered Search: " .. query)
end

-- Enhanced hybrid search with options
function M.quick_hybrid_search()
	local query = vim.fn.input("🔍 Search: ")
	if query == "" then
		return
	end

	local content_type = vim.fn.input("📁 Content Type (optional): ")
	local include_text_filtering = vim.fn.input("🔤 Include text filtering? (y/n, default y): "):lower() ~= "n"

	-- Perform hybrid search
	local results, err =
		M.hybrid_search(query, content_type ~= "" and content_type or nil, 10, 0.0, include_text_filtering)
	if not results then
		vim.notify("Hybrid search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Add to search history
	M.add_to_search_history(query, "hybrid", results.results and #results.results or 0)

	-- Display results in a floating window
	M.display_search_results(results, "Hybrid Search: " .. query)
end

-- Add search to history
function M.add_to_search_history(query, search_type, result_count)
	local search_entry = {
		query = query,
		type = search_type or "basic",
		result_count = result_count or 0,
		timestamp = os.time(),
		date = os.date("%Y-%m-%d %H:%M:%S"),
	}

	-- Add to beginning of history
	table.insert(search_history, 1, search_entry)

	-- Limit history size
	if #search_history > max_history_size then
		table.remove(search_history, #search_history)
	end

	return true
end

-- Get search history
function M.get_search_history()
	return vim.tbl_deep_extend("force", {}, search_history)
end

-- Clear search history
function M.clear_search_history()
	search_history = {}
	return true
end

-- Save current search
function M.save_current_search(name, query, search_type)
	if not name or name == "" then
		return false, "Search name is required"
	end

	if not query or query == "" then
		return false, "Search query is required"
	end

	local saved_search = {
		name = name,
		query = query,
		type = search_type or "basic",
		timestamp = os.time(),
		date = os.date("%Y-%m-%d %H:%M:%S"),
	}

	saved_searches[name] = saved_search
	return true
end

-- Get saved searches
function M.get_saved_searches()
	return vim.tbl_deep_extend("force", {}, saved_searches)
end

-- Delete saved search
function M.delete_saved_search(name)
	if saved_searches[name] then
		saved_searches[name] = nil
		return true
	end
	return false, "Saved search not found"
end

-- Clear saved searches
function M.clear_saved_searches()
	saved_searches = {}
	return true
end

-- Search command handlers
function M.search_command(args)
	local query = table.concat(args, " ")
	if query == "" then
		query = vim.fn.input("Search query: ")
		if query == "" then
			vim.notify("Search query cannot be empty", vim.log.levels.WARN)
			return
		end
	end

	-- Perform search
	local results, err = M.search_embeddings(query, 10)
	if not results then
		vim.notify("Search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Add to search history
	M.add_to_search_history(query, "basic", results.results and #results.results or 0)

	-- Display results
	M.display_search_results(results, "Search: " .. query)
end

-- Filtered search command
function M.search_filtered_command(args)
	local query = table.concat(args, " ")
	if query == "" then
		query = vim.fn.input("Search query: ")
		if query == "" then
			vim.notify("Search query cannot be empty", vim.log.levels.WARN)
			return
		end
	end

	local content_type = vim.fn.input("Content type (optional): ")

	-- Perform filtered search
	local results, err = M.find_similar_content(query, content_type ~= "" and content_type or nil, 10, 0.0)
	if not results then
		vim.notify("Filtered search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Add to search history
	M.add_to_search_history(query, "filtered", results.results and #results.results or 0)

	-- Display results
	M.display_search_results(results, "Filtered Search: " .. query)
end

-- Hybrid search command
function M.search_hybrid_command(args)
	local query = table.concat(args, " ")
	if query == "" then
		query = vim.fn.input("Search query: ")
		if query == "" then
			vim.notify("Search query cannot be empty", vim.log.levels.WARN)
			return
		end
	end

	local content_type = vim.fn.input("Content type (optional): ")
	local include_text_filtering = vim.fn.input("Include text filtering? (y/n, default y): "):lower() ~= "n"

	-- Perform hybrid search
	local results, err =
		M.hybrid_search(query, content_type ~= "" and content_type or nil, 10, 0.0, include_text_filtering)
	if not results then
		vim.notify("Hybrid search failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Add to search history
	M.add_to_search_history(query, "hybrid", results.results and #results.results or 0)

	-- Display results
	M.display_search_results(results, "Hybrid Search: " .. query)
end

-- Execute saved search
function M.execute_saved_search(name)
	local saved = saved_searches[name]
	if not saved then
		vim.notify("Saved search not found: " .. name, vim.log.levels.ERROR)
		return
	end

	-- Execute the search based on type
	local results, err
	if saved.type == "basic" then
		results, err = M.search_embeddings(saved.query, 10)
	elseif saved.type == "filtered" then
		results, err = M.find_similar_content(saved.query, nil, 10, 0.0)
	elseif saved.type == "hybrid" then
		results, err = M.hybrid_search(saved.query, nil, 10, 0.0, true)
	else
		vim.notify("Unknown search type: " .. saved.type, vim.log.levels.ERROR)
		return
	end

	if not results then
		vim.notify("Failed to execute saved search: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end

	-- Add to history again
	M.add_to_search_history(saved.query, saved.type, results.results and #results.results or 0)

	-- Display results
	M.display_search_results(results, "Saved Search: " .. saved.name)
end

-- Show search history
function M.show_search_history()
	-- Create a new buffer for search history
	local history_buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(history_buf, "paragonic://search-history")

	-- Format history entries
	local lines = { "📚 Search History", string.rep("─", 20), "" }

	for i, entry in ipairs(search_history) do
		table.insert(lines, string.format("%d. %s (%s)", i, entry.query, entry.type))
		table.insert(lines, string.format("   Results: %d | %s", entry.result_count, entry.date))
		table.insert(lines, "")
	end

	if #search_history == 0 then
		table.insert(lines, "No search history available")
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(history_buf, 0, -1, false, lines)

	-- Set buffer options
	vim.api.nvim_buf_set_option(history_buf, "modifiable", false)
	vim.api.nvim_buf_set_option(history_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(history_buf, "swapfile", false)
	vim.api.nvim_buf_set_option(history_buf, "filetype", "markdown")

	-- Create window
	local width = math.min(80, vim.o.columns - 4)
	local height = math.min(20, vim.o.lines - 4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local history_win = vim.api.nvim_open_win(history_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Search History ",
		title_pos = "center",
	})

	-- Set up keymaps
	vim.api.nvim_buf_set_keymap(history_buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(history_buf, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(
		history_buf,
		"n",
		"<CR>",
		"<cmd>lua require('paragonic').repeat_search_from_history()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		history_buf,
		"n",
		"d",
		"<cmd>lua require('paragonic').delete_from_search_history()<CR>",
		{ noremap = true, silent = true }
	)

	-- Set cursor to first line
	vim.api.nvim_win_set_cursor(history_win, { 1, 0 })
end

-- Show saved searches
function M.show_saved_searches()
	-- Create a new buffer for saved searches
	local saved_buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(saved_buf, "paragonic://saved-searches")

	-- Format saved searches
	local lines = { "💾 Saved Searches", string.rep("─", 20), "" }

	local saved_list = {}
	for name, saved in pairs(saved_searches) do
		table.insert(saved_list, { name = name, saved = saved })
	end

	-- Sort by timestamp (newest first)
	table.sort(saved_list, function(a, b)
		return a.saved.timestamp > b.saved.timestamp
	end)

	for i, item in ipairs(saved_list) do
		local saved = item.saved
		table.insert(lines, string.format("%d. %s (%s)", i, saved.name, saved.type))
		table.insert(lines, string.format("   Query: %s", saved.query))
		table.insert(lines, string.format("   Created: %s", saved.date))
		table.insert(lines, "")
	end

	if #saved_list == 0 then
		table.insert(lines, "No saved searches available")
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(saved_buf, 0, -1, false, lines)

	-- Set buffer options
	vim.api.nvim_buf_set_option(saved_buf, "modifiable", false)
	vim.api.nvim_buf_set_option(saved_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(saved_buf, "swapfile", false)
	vim.api.nvim_buf_set_option(saved_buf, "filetype", "markdown")

	-- Create window
	local width = math.min(80, vim.o.columns - 4)
	local height = math.min(20, vim.o.lines - 4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local saved_win = vim.api.nvim_open_win(saved_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Saved Searches ",
		title_pos = "center",
	})

	-- Set up keymaps
	vim.api.nvim_buf_set_keymap(saved_buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(saved_buf, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(
		saved_buf,
		"n",
		"<CR>",
		"<cmd>lua require('paragonic').execute_saved_search_from_list()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		saved_buf,
		"n",
		"d",
		"<cmd>lua require('paragonic').delete_saved_search_from_list()<CR>",
		{ noremap = true, silent = true }
	)

	-- Set cursor to first line
	vim.api.nvim_win_set_cursor(saved_win, { 1, 0 })
end

-- Repeat search from history
function M.repeat_search_from_history(buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	-- Calculate which entry was selected (accounting for header lines)
	local entry_index = line_num - 4 -- Subtract header lines
	if entry_index >= 1 and entry_index <= #search_history then
		local entry = search_history[entry_index]

		-- Execute the search
		local results, err
		if entry.type == "basic" then
			results, err = M.search_embeddings(entry.query, 10)
		elseif entry.type == "filtered" then
			results, err = M.find_similar_content(entry.query, nil, 10, 0.0)
		elseif entry.type == "hybrid" then
			results, err = M.hybrid_search(entry.query, nil, 10, 0.0, true)
		end

		if results then
			-- Add to history again
			M.add_to_search_history(entry.query, entry.type, results.results and #results.results or 0)

			-- Display results
			M.display_search_results(results, "History Search: " .. entry.query)
		else
			vim.notify("Failed to repeat search: " .. (err or "unknown error"), vim.log.levels.ERROR)
		end
	else
		vim.notify("Invalid selection", vim.log.levels.WARN)
	end
end

-- Delete from search history
function M.delete_from_search_history(buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	-- Calculate which entry was selected (accounting for header lines)
	local entry_index = line_num - 4 -- Subtract header lines
	if entry_index >= 1 and entry_index <= #search_history then
		local entry = search_history[entry_index]
		table.remove(search_history, entry_index)

		-- Refresh the display
		vim.api.nvim_command("close")
		M.show_search_history()
	else
		vim.notify("Invalid selection", vim.log.levels.WARN)
	end
end

-- Execute saved search from list
function M.execute_saved_search_from_list(buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	-- Calculate which entry was selected (accounting for header lines)
	local entry_index = math.floor((line_num - 4) / 3) + 1 -- Each entry takes 3 lines
	if entry_index >= 1 and entry_index <= #saved_searches then
		local saved = saved_searches[entry_index]
		M.execute_saved_search(saved.name)
	else
		vim.notify("Invalid selection", vim.log.levels.WARN)
	end
end

-- Delete saved search from list
function M.delete_saved_search_from_list(buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	-- Calculate which entry was selected (accounting for header lines)
	local entry_index = math.floor((line_num - 4) / 3) + 1 -- Each entry takes 3 lines
	if entry_index >= 1 and entry_index <= #saved_searches then
		local saved = saved_searches[entry_index]
		M.delete_saved_search(saved.name)

		-- Refresh the display
		vim.api.nvim_command("close")
		M.show_saved_searches()
	else
		vim.notify("Invalid selection", vim.log.levels.WARN)
	end
end

-- Save current search
function M.save_current_search()
	local name = vim.fn.input("💾 Save search as: ")
	if name == "" then
		vim.notify("Search name is required", vim.log.levels.WARN)
		return
	end

	-- For now, save the last search from history
	if #search_history > 0 then
		local last_search = search_history[1]
		M.save_search(name, last_search.query, last_search.type, nil, 10, 0.0)
	else
		vim.notify("No recent searches to save", vim.log.levels.WARN)
	end
end

-- Save search with parameters
function M.save_search(name, query, search_type, content_type, limit, threshold)
	if not name or name == "" then
		return false, "Search name is required"
	end

	if not query or query == "" then
		return false, "Search query is required"
	end

	local saved_search = {
		name = name,
		query = query,
		type = search_type or "basic",
		content_type = content_type,
		limit = limit or 10,
		threshold = threshold or 0.0,
		timestamp = os.time(),
		date = os.date("%Y-%m-%d %H:%M:%S"),
	}

	saved_searches[name] = saved_search
	return true
end

-- Display search results
function M.display_search_results(results, title)
	if not results or not results.results then
		vim.notify("No search results to display", vim.log.levels.WARN)
		return
	end

	-- Create a new buffer for results
	local results_buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(results_buf, "paragonic://search-results")

	-- Store results data in buffer variable for interaction
	vim.api.nvim_buf_set_var(results_buf, "paragonic_search_results", results)

	-- Format results
	local lines = { title or "Search Results", string.rep("─", 30), "" }

	for i, result in ipairs(results.results) do
		table.insert(lines, string.format("%d. %s", i, result.embedding.content_type or "unknown"))
		table.insert(lines, string.format("   Score: %.3f", result.similarity_score or 0))
		table.insert(lines, string.format("   ID: %s", result.embedding.content_id or "unknown"))
		table.insert(lines, "")
	end

	if #results.results == 0 then
		table.insert(lines, "No results found")
	end

	-- Set buffer content
	vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, lines)

	-- Set buffer options
	vim.api.nvim_buf_set_option(results_buf, "modifiable", false)
	vim.api.nvim_buf_set_option(results_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(results_buf, "swapfile", false)
	vim.api.nvim_buf_set_option(results_buf, "filetype", "markdown")

	-- Create window
	local width = math.min(80, vim.o.columns - 4)
	local height = math.min(20, vim.o.lines - 4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local results_win = vim.api.nvim_open_win(results_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Search Results ",
		title_pos = "center",
	})

	-- Set up keymaps
	vim.api.nvim_buf_set_keymap(results_buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(results_buf, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(
		results_buf,
		"n",
		"<CR>",
		"<cmd>lua require('paragonic').select_search_result()<CR>",
		{ noremap = true, silent = true }
	)

	-- Set cursor to first line
	vim.api.nvim_win_set_cursor(results_win, { 1, 0 })
end

-- Handle search result selection
function M.select_search_result(buf)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]

	-- Get the results data
	local success, results = pcall(vim.api.nvim_buf_get_var, buf, "paragonic_search_results")
	if not success or not results or not results.results then
		vim.notify("No search results available", vim.log.levels.WARN)
		return
	end

	-- Calculate which result was selected (accounting for header lines)
	local result_index = line_num - 4 -- Subtract header lines
	if result_index >= 1 and result_index <= #results.results then
		local selected_result = results.results[result_index]

		-- Display detailed information about the selected result
		M.show_result_details(selected_result)
	else
		vim.notify("Invalid selection", vim.log.levels.WARN)
	end
end

-- Show detailed information about a search result
function M.show_result_details(result)
	if not result or not result.embedding then
		vim.notify("Invalid result data", vim.log.levels.ERROR)
		return
	end

	-- Create a new buffer for detailed view
	local detail_buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(detail_buf, "paragonic://result-details")

	-- Format detailed information
	local lines = {
		"📋 Search Result Details",
		string.rep("─", 25),
		"",
		"📄 Content Type: " .. (result.embedding.content_type or "unknown"),
		"🎯 Similarity Score: " .. string.format("%.3f", result.similarity_score or 0),
		"🆔 Content ID: " .. (result.embedding.content_id or "unknown"),
		"",
		"📝 Content:",
		string.rep("─", 10),
		result.embedding.content_text or "No content available",
		"",
		"📅 Created: " .. (result.embedding.created_at or "unknown"),
		"🔄 Updated: " .. (result.embedding.updated_at or "unknown"),
		"",
		string.rep("─", 50),
		"Press q to close",
	}

	-- Set buffer content
	vim.api.nvim_buf_set_lines(detail_buf, 0, -1, false, lines)

	-- Set buffer options
	vim.api.nvim_buf_set_option(detail_buf, "modifiable", false)
	vim.api.nvim_buf_set_option(detail_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(detail_buf, "swapfile", false)
	vim.api.nvim_buf_set_option(detail_buf, "filetype", "markdown")

	-- Create window
	local width = math.min(70, vim.o.columns - 4)
	local height = math.min(20, vim.o.lines - 4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local detail_win = vim.api.nvim_open_win(detail_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Result Details ",
		title_pos = "center",
	})

	-- Set up keymaps
	vim.api.nvim_buf_set_keymap(detail_buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(detail_buf, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })

	-- Set cursor to first line
	vim.api.nvim_win_set_cursor(detail_win, { 1, 0 })
end

-- Core search functions (these would need to be implemented based on your backend)
function M.search_embeddings(query, limit)
	-- This should call your backend's search function
	-- For now, return a mock result
	return {
		results = {
			{
				similarity_score = 0.95,
				embedding = {
					content_type = "document",
					content_id = "doc1",
					content_text = "Sample content for " .. query,
					created_at = "2024-01-01",
					updated_at = "2024-01-01",
				},
			},
		},
	}
end

function M.find_similar_content(query, content_type, limit, threshold)
	-- This should call your backend's filtered search function
	-- For now, return a mock result
	return {
		results = {
			{
				similarity_score = 0.90,
				embedding = {
					content_type = content_type or "document",
					content_id = "doc2",
					content_text = "Filtered content for " .. query,
					created_at = "2024-01-01",
					updated_at = "2024-01-01",
				},
			},
		},
	}
end

function M.hybrid_search(query, content_type, limit, threshold, include_text_filtering)
	-- This should call your backend's hybrid search function
	-- For now, return a mock result
	return {
		results = {
			{
				similarity_score = 0.85,
				embedding = {
					content_type = content_type or "document",
					content_id = "doc3",
					content_text = "Hybrid content for " .. query,
					created_at = "2024-01-01",
					updated_at = "2024-01-01",
				},
			},
		},
	}
end

return M
