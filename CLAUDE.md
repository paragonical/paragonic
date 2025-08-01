# Paragonic - Agentic Neovim Extension

## Agent OS Documentation

### Product Context
- **Mission & Vision:** @.agent-os/product/mission.md
- **Technical Architecture:** @.agent-os/product/tech-stack.md
- **Development Roadmap:** @.agent-os/product/roadmap.md
- **Decision History:** @.agent-os/product/decisions.md

### Development Standards
- **Code Style:** @~/.agent-os/standards/code-style.md
- **Best Practices:** @~/.agent-os/standards/best-practices.md

### Project Management
- **Active Specs:** @.agent-os/specs/
- **Spec Planning:** Use `@~/.agent-os/instructions/create-spec.md`
- **Tasks Execution:** Use `@~/.agent-os/instructions/execute-tasks.md`

## Workflow Instructions

When asked to work on this codebase:

1. **First**, check @.agent-os/product/roadmap.md for current priorities
2. **Then**, follow the appropriate instruction file:
   - For new features: @.agent-os/instructions/create-spec.md
   - For tasks execution: @.agent-os/instructions/execute-tasks.md
3. **Always**, adhere to the standards in the files listed above

## Important Notes

- Product-specific files in `.agent-os/product/` override any global standards
- User's specific instructions override (or amend) instructions found in `.agent-os/specs/...`
- Always adhere to established patterns, code style, and best practices documented above.

## Project Overview

Paragonic is a Neovim extension that provides an agentic system for AI-powered agents and human collaborations. It integrates with Ollama for local AI processing and implements the Model Context Protocol (MCP) for extensibility.

### Key Technologies
- **Backend:** Rust with PostgreSQL Embedded database
- **Frontend:** Lua for Neovim integration
- **AI Integration:** Ollama with MCP protocol
- **Architecture:** Local-first, privacy-focused, scalable to tens of thousands of users

### Current Status
- **Phase:** Planning (Phase 1: Core Foundation)
- **Next Priority:** Basic Neovim plugin structure with Rust backend
- **Success Criteria:** Plugin loads in Neovim, connects to Ollama, basic chat interface works

## Development Guidelines

### Rust Development
- Follow TDD cycle: Write tests first, implement, run clippy
- Use documentation tests and inline unit tests
- Ensure all tests pass before committing
- Use `cargo audit` for security scanning

### Neovim Integration
- Maintain native Neovim workflow
- Use Lua for plugin interface
- Rust for heavy computation and AI operations
- Follow Neovim plugin conventions

### Database Design
- Use PostgreSQL Embedded for scalable local development
- Implement proper migrations with SQLx
- Design schema for projects, goals, tasks, and agents
- Ensure data integrity and backup capabilities
- Configure connection pooling for high concurrency 