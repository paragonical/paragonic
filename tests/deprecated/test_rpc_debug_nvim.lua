-- Debug script for Neovim to test RPC client
print("=== RPC Client Debug Test ===")

-- Load the paragonic module
local paragonic = require("paragonic")

print("1. Testing RPC client initialization...")
local rpc_client = paragonic._get_rpc_client()

if rpc_client then
    print("✓ RPC client created")
    print("   Server address:", rpc_client.server_address)
    print("   Connected:", rpc_client:is_connected())
    
    print("\n2. Testing hello method...")
    local hello_response = rpc_client:hello()
    print("   Hello response:", hello_response)
    
    print("\n3. Testing chat completion...")
    local chat_response = rpc_client:chat_completion("llama2", "Hello, this is a test message")
    print("   Chat response:", chat_response)
    
    print("\n4. Testing list models...")
    local models_response = rpc_client:list_models()
    print("   Models response:", models_response)
else
    print("❌ RPC client creation failed")
end

print("\n=== Debug Test Complete ===") 