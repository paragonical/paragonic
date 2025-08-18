print("=== MCP Client Validation (Neovim) ===")

local function assert_true(cond, msg)
	if not cond then
		error(msg or "assert_true failed")
	end
end

local function assert_ok(success, err, step)
	if not success then
		error((step or "step") .. " failed: " .. tostring(err))
	end
end

-- Ensure package.path can find our modules
package.path = table.concat({
	"./?.lua",
	"./?/init.lua",
	"lua/?.lua",
	"lua/?/init.lua",
	package.path,
}, ";")

-- Load config and set backend base URL
local ok_cfg, config = pcall(require, "paragonic.config")
assert_true(ok_cfg, "Failed to load config module")
if config.set then
	config.set("backend_base_url", "http://127.0.0.1:3000")
end

-- Validate transport responds before full backend init (optional)
local ok_mcp, mcp = pcall(require, "paragonic.mcp_http_transport")
assert_true(ok_mcp, "Failed to load mcp_http_transport")

local init_ok, init_err = mcp.init({
	base_url = config.get and config.get("backend_base_url") or "http://127.0.0.1:3000",
	protocol_version = "2025-06-18",
	initialization_timeout = 10,
	request_timeout = 10,
})
assert_ok(init_ok, init_err, "mcp.init")

local session_ok, session_err = mcp.initialize_session({
	name = "paragonic.nvim-test",
	version = "0.0.1",
	capabilities = { tools = {}, resources = {}, notifications = {} },
})
assert_ok(session_ok, session_err, "mcp.initialize_session")

-- Quick ping using tools/list
local tools_resp, tools_err = mcp.send_request({ jsonrpc = "2.0", id = "1", method = "tools/list", params = {} })
assert_true(tools_resp ~= nil, "tools/list failed: " .. tostring(tools_err))
print("  ✓ MCP tools/list reachable")

-- Now validate backend shim
local ok_backend, backend = pcall(require, "paragonic.backend")
assert_true(ok_backend, "Failed to load backend module")

local init_backend = backend.initialize_backend()
assert_true(init_backend, "backend.initialize_backend() failed")

local client = backend._get_rpc_client()
assert_true(client ~= nil, "backend._get_rpc_client() returned nil")

-- Perform a basic chat completion (non-streaming)
local model = (config.get and config.get("ollama_model")) or "deepseek-r1:1.5b"
local resp, err = client:chat_completion(model, "ping")
assert_true(resp ~= nil, "chat_completion failed: " .. tostring(err))
print("  ✓ chat_completion returned a response")

print("✓ MCP client validation passed")
