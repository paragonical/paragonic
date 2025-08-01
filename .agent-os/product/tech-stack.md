# Technical Stack

> Last Updated: 2024-12-19
> Version: 1.0.0

## Core Technologies

### Application Framework
- **Language:** Rust (latest stable)
- **Neovim Integration:** Lua (via Rust bindings)
- **Plugin Framework:** Neovim plugin architecture

### Database System
- **Primary:** PostgreSQL Embedded (via [postgresql_embedded crate](https://docs.rs/postgresql_embedded/latest/postgresql_embedded/))
- **ORM:** Diesel v2.2.12 with compile-time query checking
- **Migrations:** Diesel migrations with CLI tooling
- **Connection Pooling:** Diesel connection pool for high concurrency
- **Features:** Bundled PostgreSQL binaries, automatic setup and management, type-safe queries

### Neovim Integration
- **Plugin Language:** Lua
- **Rust Bindings:** Neovim Rust bindings (nvim-rs or similar)
- **UI Framework:** Neovim native UI with custom windows
- **Configuration:** Lua-based configuration system

### AI Integration
- **Local AI:** Ollama integration via @references/ollama-api.md
- **Protocol:** Model Context Protocol (MCP) via @references/mcp.md
- **Communication:** HTTP/WebSocket for Ollama, MCP for external tools

### Development Tools
- **Build System:** Cargo (Rust)
- **Testing:** Cargo test + Neovim plugin testing
- **Linting:** Clippy (Rust), LuaCheck (Lua)
- **Documentation:** Rust doc, LuaDoc

### Data Management
- **Serialization:** Serde (Rust)
- **Configuration:** TOML/YAML for user configs
- **State Management:** In-memory with SQLite persistence

### Security & Privacy
- **Encryption:** Local-only, no cloud dependencies
- **Authentication:** Local user management
- **Data Storage:** Local filesystem only

### Deployment & Distribution
- **Package Manager:** Neovim package managers (packer, lazy.nvim, etc.)
- **Distribution:** GitHub releases with pre-built binaries
- **Installation:** Standard Neovim plugin installation

### Monitoring & Logging
- **Logging:** Tracing (Rust) + Neovim logging
- **Error Handling:** Anyhow + custom error types
- **Performance:** Built-in profiling tools

## Architecture Decisions

### Why PostgreSQL Embedded over SQLite?
- **Scalability:** Supports tens of thousands of concurrent users
- **Advanced Features:** Full PostgreSQL features (JSON, arrays, advanced indexing)
- **Concurrency:** Better handling of multiple simultaneous connections
- **Performance:** Optimized for complex queries and large datasets
- **Embedded:** No external server setup required, bundled with application
- **Automatic Management:** Built-in setup, start, stop, and database management

### Why Rust + Lua?
- **Performance:** Rust for heavy computation and AI integration
- **Neovim Native:** Lua for Neovim plugin integration
- **Safety:** Rust's memory safety and error handling
- **Ecosystem:** Rich Rust ecosystem for AI/ML tools

### Why MCP Protocol?
- **Interoperability:** Works with various AI models and tools
- **Future-Proof:** Open standard for AI tool integration
- **Extensibility:** Easy to add new AI capabilities
- **Community:** Growing ecosystem of MCP-compatible tools 