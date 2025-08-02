--[[
Test for open_projects() function - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test that open_projects() creates a projects buffer
local function test_open_projects_creates_buffer()
    print("Testing open_projects() creates projects buffer...")
    
    -- Load the module
    local paragonic = require("paragonic")
    
    -- Count projects buffers before
    local buffers_before = vim.api.nvim_list_bufs()
    local projects_buffers_before = 0
    for _, buf in ipairs(buffers_before) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://projects" then
            projects_buffers_before = projects_buffers_before + 1
        end
    end
    
    -- Call open_projects
    paragonic.open_projects()
    
    -- Count projects buffers after
    local buffers_after = vim.api.nvim_list_bufs()
    local projects_buffers_after = 0
    for _, buf in ipairs(buffers_after) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "paragonic://projects" then
            projects_buffers_after = projects_buffers_after + 1
        end
    end
    
    -- Should have created a projects buffer
    assert(projects_buffers_after > projects_buffers_before, "Should create a projects buffer")
    
    print("✓ open_projects() creates projects buffer test passed!")
end

-- Run the test
test_open_projects_creates_buffer() 