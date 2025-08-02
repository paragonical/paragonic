# Design Notes

## Database and ORM Design Decisions

### pgvector Type Handling with Diesel

**Issue**: Diesel's schema generation doesn't natively support PostgreSQL's pgvector extension types.

**Problem**: When using `diesel print-schema`, the `vector(384)` column type is incorrectly mapped to `Bytea` instead of the proper vector type.

**Current State**:
- Database column: `embedding_vector vector(384)`
- Generated schema: `embedding_vector -> Nullable<Bytea>`
- Expected schema: `embedding_vector -> Nullable<Vector>` (custom type)

**Impact**:
- Embedding creation works (Ollama integration ✅)
- Database storage fails with type mismatch error
- Test passes by handling the expected database error

**Solutions Considered**:

1. **Custom Diesel Type** (Recommended)
   - Create a custom `Vector` type with proper Diesel traits
   - Implement `FromSql` and `ToSql` for vector serialization
   - Update schema.rs manually to use the custom type

2. **Raw SQL for Vector Operations**
   - Use `diesel::sql_query` for vector-specific operations
   - Keep embeddings as `Bytea` for storage
   - Convert to/from vector format in application layer

3. **Alternative ORM**
   - Consider using SQLx which has better pgvector support
   - Would require significant refactoring

**Next Steps**:
- Implement custom `Vector` type with proper Diesel integration
- Update schema.rs to use the custom type
- Add vector similarity search functions

**References**:
- [pgvector documentation](https://github.com/pgvector/pgvector)
- [Diesel custom types](https://diesel.rs/guides/custom_types)
- [Diesel pgvector example](https://github.com/diesel-rs/diesel/issues/3558)

## Lua-Rust Integration Design Decisions

### JSON-RPC for Lua-Rust Communication

**Decision**: Use JSON-RPC for communication between Lua Neovim plugin and Rust backend, aligning with Model Context Protocol (MCP) standards.

**Rationale**:
- **MCP Alignment**: JSON-RPC is the standard protocol used by MCP, ensuring compatibility with the broader AI ecosystem
- **Simplicity**: JSON-RPC is lightweight and easy to implement in both Lua and Rust
- **Extensibility**: Easy to add new methods and parameters without breaking changes
- **Debugging**: Human-readable JSON messages for easier debugging and development
- **Standards Compliance**: Follows established RPC standards used by many AI tools

**Implementation Plan**:
1. **Rust JSON-RPC Server**: Use `tokio_jsonrpc` for async JSON-RPC server implementation
2. **Lua JSON-RPC Client**: Implement JSON-RPC client in Lua to call Rust methods
3. **Method Definitions**: Define RPC methods for chat completion, model management, etc.
4. **Error Handling**: Implement proper error handling for network and RPC failures
5. **Configuration**: Allow configuration of RPC server address and timeouts
6. **MCP Integration**: Enable Rust to initiate calls to external MCP servers

**RPC Methods to Implement**:
- `chat_completion(message: string, model: string) -> string`
- `list_models() -> array`
- `model_info(model: string) -> object`
- `generate_embedding(text: string, model: string) -> array`

**Server Implementation**:
```rust
struct ParagonicServer {
    ollama_client: Arc<OllamaClient>,
}

impl Server for ParagonicServer {
    type Success = String;
    type RpcCallResult = Result<String, RpcError>;
    type NotificationResult = Result<(), ()>;
    
    fn rpc(&self, ctl: &ServerCtl, method: &str, params: &Option<Value>) 
        -> Option<Self::RpcCallResult> {
        match method {
            "chat_completion" => Some(self.handle_chat_completion(params)),
            "list_models" => Some(self.handle_list_models()),
            "model_info" => Some(self.handle_model_info(params)),
            "generate_embedding" => Some(self.handle_generate_embedding(params)),
            _ => None
        }
    }
}
```

**References**:
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [tokio_jsonrpc crate](https://crates.io/crates/tokio_jsonrpc) 

## Resource Types

- **Repositories**: Code and file collections
- **Channels**: Communication channels for updates and feedback
- **Programs**: Container of projects and operations for long-running systems
- **Portfolios**: Set of programs for highest-level organizational structure 