use paragonic::{initialize, start_rpc_server, iragl::{demonstrate_iragl_capabilities, index_file_for_iragl, IndexFileRequest, search_iragl_index, IraglSearchQuery, SearchType, SearchFilters}};
use std::process;
use std::env;
use uuid::Uuid;

#[tokio::main]
async fn main() {
    // Parse command line arguments
    let args: Vec<String> = env::args().collect();
    
    // Check for special commands
    if args.len() > 1 {
        match args[1].as_str() {
            "demonstrate-iragl" => {
                println!("Running IRAGL capability demonstration...");
                match demonstrate_iragl_capabilities().await {
                    Ok(_) => {
                        println!("✅ IRAGL demonstration completed successfully!");
                        process::exit(0);
                    }
                    Err(e) => {
                        eprintln!("❌ IRAGL demonstration failed: {e}");
                        eprintln!("Note: This requires a PostgreSQL database with pgvector extension");
                        process::exit(1);
                    }
                }
            }
            "index-file" => {
                if args.len() < 3 {
                    eprintln!("Usage: paragonic index-file <file_path>");
                    eprintln!("Example: paragonic index-file README.md");
                    process::exit(1);
                }
                
                // Set demo mode for file indexing (no database required)
                std::env::set_var("PARAGONIC_DEMO_MODE", "1");
                
                let file_path = &args[2];
                println!("Indexing file: {}", file_path);
                
                let request = IndexFileRequest {
                    file_path: file_path.to_string(),
                    content_type: None, // Auto-detect
                    source_entity_type: "file".to_string(),
                    source_entity_id: Uuid::new_v4(),
                    metadata: Some(serde_json::json!({
                        "indexed_via_cli": true,
                        "timestamp": chrono::Utc::now().to_rfc3339()
                    })),
                    embedding_model: "nomic-embed-text".to_string(),
                    chunk_size: None, // Use default
                    include_metadata: true,
                };
                
                match index_file_for_iragl(request).await {
                    Ok(response) => {
                        println!("✅ File indexed successfully!");
                        println!("   File ID: {}", response.file_id);
                        println!("   Content type: {}", response.content_type);
                        println!("   Chunks created: {}", response.chunks_created);
                        println!("   File size: {} bytes", response.total_size_bytes);
                        println!("   Processing time: {}ms", response.processing_duration_ms);
                        process::exit(0);
                    }
                    Err(e) => {
                        eprintln!("❌ Failed to index file: {e}");
                        process::exit(1);
                    }
                }
            }
            "search" => {
                if args.len() < 3 {
                    eprintln!("Usage: paragonic search <query> [options]");
                    eprintln!("Example: paragonic search 'IRAGL knowledge management'");
                    eprintln!("Example: paragonic search 'neovim ollama' --type keyword");
                    eprintln!("Example: paragonic search 'agent collaboration' --type hybrid --limit 5");
                    process::exit(1);
                }
                
                let query_text = &args[2];
                let mut search_type = SearchType::Semantic;
                let mut limit = Some(10);
                let mut filters = None;
                
                // Parse optional arguments
                let mut i = 3;
                while i < args.len() {
                    match args[i].as_str() {
                        "--type" | "-t" => {
                            if i + 1 < args.len() {
                                search_type = match args[i + 1].as_str() {
                                    "semantic" => SearchType::Semantic,
                                    "keyword" => SearchType::Keyword,
                                    "hybrid" => SearchType::Hybrid,
                                    "metadata" => SearchType::Metadata,
                                    _ => {
                                        eprintln!("Invalid search type. Use: semantic, keyword, hybrid, metadata");
                                        process::exit(1);
                                    }
                                };
                                i += 2;
                            } else {
                                eprintln!("--type requires a value");
                                process::exit(1);
                            }
                        }
                        "--limit" | "-l" => {
                            if i + 1 < args.len() {
                                limit = args[i + 1].parse::<usize>().ok();
                                i += 2;
                            } else {
                                eprintln!("--limit requires a number");
                                process::exit(1);
                            }
                        }
                        "--file" | "-f" => {
                            if i + 1 < args.len() {
                                filters = Some(SearchFilters {
                                    file_paths: Some(vec![args[i + 1].clone()]),
                                    content_types: None,
                                    date_range: None,
                                    sections: None,
                                    source_entities: None,
                                });
                                i += 2;
                            } else {
                                eprintln!("--file requires a file path");
                                process::exit(1);
                            }
                        }
                        _ => {
                            eprintln!("Unknown option: {}", args[i]);
                            process::exit(1);
                        }
                    }
                }
                
                println!("🔍 Searching IRAGL index for: '{}'", query_text);
                println!("   Search type: {:?}", search_type);
                println!("   Limit: {:?}", limit);
                
                let search_query = IraglSearchQuery {
                    query: query_text.to_string(),
                    search_type,
                    limit,
                    filters,
                    include_metadata: true,
                };
                
                match search_iragl_index(search_query).await {
                    Ok(results) => {
                        println!("✅ Found {} results:", results.len());
                        println!();
                        
                        for (i, result) in results.iter().enumerate() {
                            println!("Result {} (Score: {:.2}):", i + 1, result.similarity_score);
                            println!("  File: {}", result.source_info.file_path.as_ref().unwrap_or(&"Unknown".to_string()));
                            println!("  Section: {}", result.source_info.section.as_ref().unwrap_or(&"Unknown".to_string()));
                            println!("  Content: {}", result.content_text.chars().take(120).collect::<String>());
                            
                            if let Some(ref context) = result.context.related_concepts {
                                println!("  Related: {}", context.join(", "));
                            }
                            println!();
                        }
                        process::exit(0);
                    }
                    Err(e) => {
                        eprintln!("❌ Search failed: {e}");
                        process::exit(1);
                    }
                }
            }
            "--help" | "-h" => {
                println!("Paragonic - Advanced Knowledge Management System");
                println!();
                println!("Usage:");
                println!("  paragonic                    - Start the RPC server");
                println!("  paragonic --no-database      - Start without database initialization");
                println!("  paragonic demonstrate-iragl  - Demonstrate IRAGL capabilities");
                println!("  paragonic index-file <path>  - Index a file for IRAGL");
                println!("  paragonic search <query>     - Search the IRAGL index");
                println!("  paragonic --help             - Show this help message");
                println!();
                println!("Commands:");
                println!("  demonstrate-iragl            - Run comprehensive IRAGL demonstration");
                println!("                                (requires PostgreSQL with pgvector)");
                println!("  index-file <path>            - Index a file into IRAGL knowledge base");
                println!("                                Supports: .md, .txt, .py, .rs, .js, .json, etc.");
                println!("  search <query>               - Search indexed content");
                println!("                                Options: --type (semantic|keyword|hybrid|metadata)");
                println!("                                         --limit <number> --file <path>");
                process::exit(0);
            }
            _ => {
                // Continue with normal server startup
            }
        }
    }
    
    let skip_database = args.iter().any(|arg| arg == "--no-database");
    
    if skip_database {
        println!("Starting Paragonic backend without database initialization...");
    } else {
        // Initialize the backend
        if let Err(e) = initialize().await {
            eprintln!("Failed to initialize Paragonic backend: {e}");
            process::exit(1);
        }
        println!("Paragonic backend initialized successfully");
    }
    
    println!("Starting RPC server on 127.0.0.1:3000...");

    // Start the RPC server (this is not async, it just sets up the server)
    if let Err(e) = start_rpc_server("127.0.0.1:3000") {
        eprintln!("Failed to start RPC server: {e}");
        process::exit(1);
    }

    println!("RPC server started successfully");
    println!("Press Ctrl+C to stop the server");

    // Keep the server running
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
    }
} 