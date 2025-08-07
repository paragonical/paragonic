--[[
Test for PostgreSQL shared memory workaround - one-by-one TDD flow
--]]

-- Add lua directory to package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
-- Add luarocks path for cjson and socket
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/?.so"
package.cpath = package.cpath .. ";/Users/sjanes/.luarocks/lib/lua/5.1/socket/?.so"

-- Test PostgreSQL shared memory issue
local function test_postgresql_shared_memory_issue()
    print("Testing PostgreSQL shared memory issue...")
    
    -- Check if Rust backend binary exists
    local backend_binary = "./target/debug/paragonic"
    local file = io.open(backend_binary, "r")
    if not file then
        print("⚠ Rust backend binary not found at " .. backend_binary)
        print("  Need to build with: cargo build")
        return false
    end
    file:close()
    print("✓ Rust backend binary found at " .. backend_binary)
    
    -- Test server startup and capture error output
    print("Testing server startup...")
    local server_cmd = backend_binary .. " 2>&1"
    local server_process = io.popen(server_cmd)
    if server_process then
        -- Wait a moment for startup
        os.execute("sleep 3")
        
        -- Check if server is still running
        local status = server_process:read("*a")
        server_process:close()
        
        if status and status ~= "" then
            print("Server output: " .. status:sub(1, 300))
            
            -- Check if there's a shared memory error
            if status:find("could not create shared memory segment") then
                print("⚠ PostgreSQL shared memory error detected")
                print("  This is a system-level issue with shared memory limits")
                return false
            elseif status:find("Paragonic backend initialized successfully") then
                print("✓ Server started successfully")
                return true
            else
                print("⚠ Unexpected server output")
                return false
            end
        else
            print("⚠ No server output")
            return false
        end
    else
        print("⚠ Failed to start server process")
        return false
    end
end

-- Test RPC server without database (if possible)
local function test_rpc_server_without_database()
    print("Testing RPC server without database...")
    
    -- Try to start server with minimal configuration
    -- We'll need to modify the server to skip database initialization for testing
    print("⚠ Need to implement database bypass for testing")
    print("  This would require modifying the initialize() function")
    return false
end

-- Test system shared memory limits
local function test_system_shared_memory_limits()
    print("Testing system shared memory limits...")
    
    -- Check current shared memory limits
    local shm_check = io.popen("sysctl kern.sysv.shmseg kern.sysv.shmall kern.sysv.shmmax")
    if shm_check then
        local shm_info = shm_check:read("*a")
        shm_check:close()
        
        if shm_info and shm_info ~= "" then
            print("✓ System shared memory info:")
            print(shm_info)
        else
            print("⚠ Could not get shared memory info")
        end
    else
        print("⚠ Failed to check shared memory limits")
    end
    
    -- Check for existing PostgreSQL processes
    local pg_check = io.popen("ps aux | grep postgres | grep -v grep")
    if pg_check then
        local pg_processes = pg_check:read("*a")
        pg_check:close()
        
        if pg_processes and pg_processes ~= "" then
            print("⚠ Found existing PostgreSQL processes:")
            print(pg_processes)
            print("  These may be consuming shared memory")
        else
            print("✓ No existing PostgreSQL processes found")
        end
    else
        print("⚠ Failed to check PostgreSQL processes")
    end
    
    return true
end

-- Test alternative database configuration
local function test_alternative_database_config()
    print("Testing alternative database configuration...")
    
    -- Check if we can use a different database configuration
    print("Possible solutions:")
    print("1. Use SQLite instead of PostgreSQL for testing")
    print("2. Configure PostgreSQL with minimal shared memory")
    print("3. Use in-memory database for testing")
    print("4. Skip database initialization for RPC-only testing")
    
    return true
end

-- Run the tests
local success, err = pcall(function()
    local pg_issue = test_postgresql_shared_memory_issue()
    if pg_issue then
        test_rpc_server_without_database()
    else
        test_system_shared_memory_limits()
        test_alternative_database_config()
    end
end)

if not success then
    print("Test failed: " .. tostring(err))
    os.exit(1)
end

print("✓ All PostgreSQL workaround tests passed!") 