--[[
Paragonic - Text Processing Module
Handles text formatting, wrapping, and processing utilities
--]]

local M = {}

-- Word wrapping helper function
function M.wrap_text(text, max_width, indent)
	if not text or text == "" then
		return {}
	end

	indent = indent or ""
	local lines = {}

	-- Split text into lines and detect paragraph breaks
	local text_lines = {}
	for line in text:gmatch("[^\r\n]+") do
		table.insert(text_lines, line)
	end

	-- Process each line as a potential paragraph
	for i, line in ipairs(text_lines) do
		if line:match("%S") then -- Only process non-empty lines
			-- Strip leading spaces from the line
			local clean_line = line:match("^%s*(.+)$")
			local words = {}

			-- Split clean line into words
			for word in clean_line:gmatch("[^%s]+") do
				table.insert(words, word)
			end

			local current_line = indent
			local current_length = #indent

			for i, word in ipairs(words) do
				local word_length = #word

				-- If adding this word would exceed the line limit
				if current_length + word_length > max_width then
					-- Add current line to lines (if not empty)
					if current_line ~= indent then
						table.insert(lines, current_line)
					end
					-- Start new line with indent
					current_line = indent .. word
					current_length = #indent + word_length
				else
					-- Add word to current line (with space if not first word)
					if current_line ~= indent then
						current_line = current_line .. " " .. word
						current_length = current_length + 1 + word_length
					else
						current_line = current_line .. word
						current_length = current_length + word_length
					end
				end
			end

			-- Add the last line if it has content
			if current_line ~= indent then
				table.insert(lines, current_line)
			end

			-- Check if we should add a blank line after this paragraph
			local should_add_blank = false

			-- Add blank line if this is not the last line
			if i < #text_lines then
				local next_line = text_lines[i + 1]
				if next_line and next_line:match("%S") then
					-- Check if next line starts a new paragraph type
					local next_clean = next_line:match("^%s*(.+)$")

					-- Add blank line if next line is a numbered list item
					if next_clean and next_clean:match("^%d+%.") then
						should_add_blank = true
					-- Add blank line if next line starts with common paragraph starters
					elseif
						next_clean
						and (
							next_clean:match("^The ")
							or next_clean:match("^This ")
							or next_clean:match("^These ")
							or next_clean:match("^In ")
							or next_clean:match("^When ")
							or next_clean:match("^While ")
							or next_clean:match("^However ")
							or next_clean:match("^Additionally ")
							or next_clean:match("^Furthermore ")
							or next_clean:match("^Moreover ")
						)
					then
						should_add_blank = true
					end
				end
			end

			if should_add_blank then
				table.insert(lines, "")
			end
		end
	end

	return lines
end

-- Word wrapping helper function for first line with diamond
function M.wrap_text_with_diamond(text, max_width)
	if not text or text == "" then
		return { "◊" }
	end

	local lines = {}

	-- Split text into lines and detect paragraph breaks
	local text_lines = {}
	for line in text:gmatch("[^\r\n]+") do
		table.insert(text_lines, line)
	end

	-- Process each line as a potential paragraph
	for i, line in ipairs(text_lines) do
		if line:match("%S") then -- Only process non-empty lines
			-- Strip leading spaces from the line
			local clean_line = line:match("^%s*(.+)$")
			local words = {}

			-- Split clean line into words
			for word in clean_line:gmatch("[^%s]+") do
				table.insert(words, word)
			end

			local current_line = "◊  "
			local current_length = 3 -- Length of lozenge + two spaces

			for i, word in ipairs(words) do
				local word_length = #word

				-- If adding this word would exceed the line limit
				if current_length + word_length > max_width then
					-- Add current line to lines (if not empty)
					if current_line ~= "◊  " then
						table.insert(lines, current_line)
					end
					-- Start new line with three spaces (no diamond)
					current_line = "   " .. word
					current_length = 3 + word_length
				else
					-- Add word to current line (with space if not first word)
					if current_line ~= "◊  " then
						current_line = current_line .. " " .. word
						current_length = current_length + 1 + word_length
					else
						current_line = current_line .. word
						current_length = current_length + word_length
					end
				end
			end

			-- Add the last line if it has content
			if current_line ~= "◊  " then
				table.insert(lines, current_line)
			end

			-- Check if we should add a blank line after this paragraph
			local should_add_blank = false

			-- Add blank line if this is not the last line
			if i < #text_lines then
				local next_line = text_lines[i + 1]
				if next_line and next_line:match("%S") then
					-- Check if next line starts a new paragraph type
					local next_clean = next_line:match("^%s*(.+)$")

					-- Add blank line if next line is a numbered list item
					if next_clean and next_clean:match("^%d+%.") then
						should_add_blank = true
					-- Add blank line if next line starts with common paragraph starters
					elseif
						next_clean
						and (
							next_clean:match("^The ")
							or next_clean:match("^This ")
							or next_clean:match("^These ")
							or next_clean:match("^In ")
							or next_clean:match("^When ")
							or next_clean:match("^While ")
							or next_clean:match("^However ")
							or next_clean:match("^Additionally ")
							or next_clean:match("^Furthermore ")
							or next_clean:match("^Moreover ")
						)
					then
						should_add_blank = true
					end
				end
			end

			if should_add_blank then
				table.insert(lines, "")
			end
		end
	end

	return lines
end

return M
