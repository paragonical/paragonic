vim.fn.printf("=== Simple vim.uv test ===\n")

-- Check basic availability
vim.fn.printf("vim.uv exists: %s\n", vim.uv ~= nil)

if vim.uv then
    vim.fn.printf("vim.uv type: %s\n", type(vim.uv))
    
    -- Check for common methods
    local methods = {"new_tcp", "now", "new_timer"}
    for _, method in ipairs(methods) do
        vim.fn.printf("vim.uv.%s exists: %s\n", method, vim.uv[method] ~= nil)
    end
    
    -- Try to get current time
    if vim.uv.now then
        vim.fn.printf("vim.uv.now() result: %s\n", vim.uv.now())
    end
else
    vim.fn.printf("vim.uv is not available\n")
end

vim.fn.printf("=== Test complete ===\n") 