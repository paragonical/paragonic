//! Simple test file for FastEmbed integration
//! This file tests the FastEmbed functionality independently

use crate::embeddings_local::{LocalEmbeddingGenerator, EmbeddingModelType, LocalEmbeddingConfig};

#[tokio::test]
async fn test_fastembed_basic_functionality() {
    // Test that we can create a generator
    let mut generator = LocalEmbeddingGenerator::new().unwrap();
    
    // Test single embedding generation
    let text = "This is a test sentence for FastEmbed.";
    let embedding = generator.generate_embedding(text).unwrap();
    
    // Verify embedding properties
    assert_eq!(embedding.len(), generator.embedding_dimensions());
    assert!(!embedding.iter().all(|&x| x == 0.0)); // Should not be all zeros
    assert!(embedding.iter().all(|&x| x.is_finite())); // All values should be finite
    
    println!("✅ FastEmbed basic functionality test passed");
    println!("   - Generated embedding with {} dimensions", embedding.len());
    println!("   - Model type: {}", generator.model_type());
}

#[tokio::test]
async fn test_fastembed_batch_processing() {
    // Test batch embedding generation
    let mut generator = LocalEmbeddingGenerator::new().unwrap();
    
    let texts = vec![
        "First test sentence.".to_string(),
        "Second test sentence.".to_string(),
        "Third test sentence.".to_string(),
    ];
    
    let batch_embeddings = generator.generate_embeddings_batch(texts).unwrap();
    assert_eq!(batch_embeddings.len(), 3);
    
    // Verify all embeddings have correct dimensions
    for (i, embedding) in batch_embeddings.iter().enumerate() {
        assert_eq!(embedding.len(), generator.embedding_dimensions());
        assert!(!embedding.iter().all(|&x| x == 0.0));
        assert!(embedding.iter().all(|&x| x.is_finite()));
        println!("   - Embedding {}: {} dimensions", i + 1, embedding.len());
    }
    
    // Test that embeddings are different (not identical)
    assert_ne!(batch_embeddings[0], batch_embeddings[1]);
    assert_ne!(batch_embeddings[1], batch_embeddings[2]);
    assert_ne!(batch_embeddings[0], batch_embeddings[2]);
    
    println!("✅ FastEmbed batch processing test passed");
}

#[tokio::test]
async fn test_fastembed_model_types() {
    // Test different model types
    let model_types = [
        EmbeddingModelType::BgeSmallEnV15,
        EmbeddingModelType::AllMiniLML6V2,
    ];
    
    for model_type in model_types {
        let mut generator = LocalEmbeddingGenerator::with_model(model_type).unwrap();
        let text = "Test sentence for model type.";
        let embedding = generator.generate_embedding(text).unwrap();
        
        assert_eq!(embedding.len(), generator.embedding_dimensions());
        assert!(!embedding.iter().all(|&x| x == 0.0));
        
        println!("   - Model {}: {} dimensions", model_type, embedding.len());
    }
    
    println!("✅ FastEmbed model types test passed");
}

#[tokio::test]
async fn test_fastembed_configuration() {
    // Test custom configuration
    let config = LocalEmbeddingConfig {
        model_type: EmbeddingModelType::BgeSmallEnV15,
        batch_size: 128,
        show_download_progress: false,
        cache_dir: None,
    };
    
    let mut generator = LocalEmbeddingGenerator::with_config(config).unwrap();
    let text = "Test sentence with custom config.";
    let embedding = generator.generate_embedding(text).unwrap();
    
    assert_eq!(embedding.len(), generator.embedding_dimensions());
    assert_eq!(generator.config().batch_size, 128);
    
    println!("✅ FastEmbed configuration test passed");
}
