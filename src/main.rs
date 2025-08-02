use paragonic::{initialize, start_rpc_server};
use std::process;
use std::env;

#[tokio::main]
async fn main() {
    // Parse command line arguments
    let args: Vec<String> = env::args().collect();
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