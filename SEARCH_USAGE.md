# Paragonic Search Usage Guide

This guide explains how to use the search functionality in the Paragonic Neovim plugin.

## Overview

Paragonic provides three types of search functionality:

1. **Basic Search** - Vector similarity search across all content
2. **Filtered Search** - Search with content type filtering
3. **Hybrid Search** - Combines vector similarity with text-based filtering

## Commands

### Basic Search
```vim
:ParagonicSearch <query>
```

Searches for content similar to the query using vector embeddings.

**Examples:**
```vim
:ParagonicSearch machine learning project
:ParagonicSearch artificial intelligence
:ParagonicSearch "neural network implementation"
```

### Filtered Search
```vim
:ParagonicSearchFiltered <query>
```

Searches for content similar to the query, filtered by content type.

**Examples:**
```vim
:ParagonicSearchFiltered AI project
:ParagonicSearchFiltered "task implementation"
```

### Hybrid Search
```vim
:ParagonicSearchHybrid <query>
```

Performs hybrid search combining vector similarity with text-based filtering and boosting.

**Examples:**
```vim
:ParagonicSearchHybrid "machine learning development"
:ParagonicSearchHybrid "project planning"
```

## Interactive Mode

If you don't provide arguments to the commands, they will prompt you for:

- **Search Query**: The text to search for
- **Limit**: Maximum number of results (default: 10)
- **Content Type**: Filter by content type (optional)
- **Threshold**: Similarity threshold (default: 0.0)
- **Text Filtering**: Whether to include text-based filtering (hybrid search only)

## Search Results

Search results are displayed in a floating window showing:

- **Content Type**: The type of content (project, task, etc.)
- **Similarity Score**: How similar the content is to your query (0.0-1.0)
- **Content Preview**: A preview of the content text

**Example Output:**
```
Basic Search: machine learning project
=====================================

Found 2 results

1. [project] (0.850) Test project content about machine learning implementation
2. [task] (0.720) Task for implementing neural network components

Press q to close
```

## Configuration

The search functionality uses the same backend configuration as other Paragonic features:

- **Server**: Defaults to `127.0.0.1:3000`
- **Timeout**: 15 seconds
- **Retries**: 2 attempts
- **Logging**: Disabled by default

## Keyboard Shortcuts

In the search results window:
- `q` or `<Esc>` - Close the results window
- Arrow keys - Navigate through results

## Troubleshooting

### No Results Found
- Check that the Rust backend is running: `cargo run -- --no-database`
- Verify that you have content in your database
- Try a different search query
- Lower the similarity threshold

### Connection Errors
- Ensure the backend server is running on the correct port
- Check firewall settings
- Verify network connectivity

### Invalid Parameters
- Search query cannot be empty
- Limit must be a positive number
- Threshold must be between 0.0 and 1.0

## Advanced Usage

### Programmatic Access

You can also use the search functions programmatically in Lua:

```lua
-- Load the paragonic module
local paragonic = require("paragonic")

-- Basic search
local results = paragonic.search_embeddings("query", 10)

-- Filtered search
local results = paragonic.find_similar_content("query", "project", 10, 0.3)

-- Hybrid search
local results = paragonic.hybrid_search("query", "project", 10, 0.3, true)
```

### Custom Result Display

You can create custom result displays using the `display_search_results` function:

```lua
local paragonic = require("paragonic")
paragonic.display_search_results(results, "Custom Search Results")
```

## Integration with Other Features

The search functionality integrates with other Paragonic features:

- **Projects**: Search through project descriptions and content
- **Tasks**: Find tasks related to specific topics
- **Chat**: Use search results in conversations with the AI
- **Configuration**: Search through configuration settings

## Performance Tips

- Use specific queries for better results
- Set appropriate limits to avoid overwhelming results
- Use content type filtering to narrow down results
- Consider using hybrid search for the best balance of relevance and speed 