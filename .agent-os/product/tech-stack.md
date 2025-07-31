# Technical Stack

> Last Updated: 2024-12-19
> Version: 1.0.0

## Core Technologies

### Application Framework
- **Language:** Rust (latest stable)
- **Neovim Integration:** Lua (via Rust bindings)
- **Plugin Framework:** Neovim plugin architecture

### Database System
- **Primary:** SQLite (embedded, Rust-native)
- **Alternative:** PostgreSQL (for advanced deployments)
- **ORM:** SQLx with async/await support
- **Migrations:** SQLx migrations

### Neovim Integration
- **Plugin Language:** Lua
- **Rust Bindings:** Neovim Rust bindings (nvim-rs or similar)
- **UI Framework:** Neovim native UI with custom windows
- **Configuration:** Lua-based configuration system

### AI Integration
- **Local AI:** Ollama integration
- **Protocol:** Model Context Protocol (MCP)
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

### Why SQLite over PostgreSQL?
- **Embedded:** No external database server required
- **Rust Native:** Excellent SQLite support in Rust ecosystem
- **Performance:** Sufficient for local development use cases
- **Simplicity:** Easier deployment and maintenance

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