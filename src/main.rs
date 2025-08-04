use paragonic::{initialize, start_rpc_server, iragl::demonstrate_iragl_capabilities};
use std::process;
use std::env;

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
            "--help" | "-h" => {
                println!("Paragonic - Advanced Knowledge Management System");
                println!();
                println!("Usage:");
                println!("  paragonic                    - Start the RPC server");
                println!("  paragonic --no-database      - Start without database initialization");
                println!("  paragonic demonstrate-iragl  - Demonstrate IRAGL capabilities");
                println!("  paragonic --help             - Show this help message");
                println!();
                println!("Commands:");
                println!("  demonstrate-iragl            - Run comprehensive IRAGL demonstration");
                println!("                                (requires PostgreSQL with pgvector)");
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