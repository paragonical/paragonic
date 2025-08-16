//! Local embedding generation using FastEmbed
//!
//! This module provides local vector embedding generation capabilities,
//! decoupling embedding generation from Ollama and enabling more efficient
//! IRAGL knowledge stream processing.

use crate::error::{ParagonicError, ParagonicResult};
use fastembed::{EmbeddingModel, InitOptions, TextEmbedding};
use std::path::PathBuf;
use tracing::{debug, info, warn};

/// Supported embedding models with different quality/speed trade-offs
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EmbeddingModelType {
    /// Default for general text - good balance of quality and speed
    BgeSmallEnV15,
    /// Fast, good quality for most use cases
    AllMiniLML6V2,
    /// High quality, larger model
    NomicEmbedTextV15,
    /// Best quality, slower processing
    BgeLargeEnV15,
}

impl Default for EmbeddingModelType {
    fn default() -> Self {
        Self::BgeSmallEnV15
    }
}

impl std::fmt::Display for EmbeddingModelType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::BgeSmallEnV15 => write!(f, "BgeSmallEnV15"),
            Self::AllMiniLML6V2 => write!(f, "AllMiniLML6V2"),
            Self::NomicEmbedTextV15 => write!(f, "NomicEmbedTextV15"),
            Self::BgeLargeEnV15 => write!(f, "BgeLargeEnV15"),
        }
    }
}

/// Configuration for local embedding generation
#[derive(Debug, Clone)]
pub struct LocalEmbeddingConfig {
    pub model_type: EmbeddingModelType,
    pub batch_size: usize,
    pub show_download_progress: bool,
    pub cache_dir: Option<PathBuf>,
}

impl Default for LocalEmbeddingConfig {
    fn default() -> Self {
        Self {
            model_type: EmbeddingModelType::BgeSmallEnV15,
            batch_size: 256,
            show_download_progress: false,
            cache_dir: None,
        }
    }
}

/// Local embedding generator using FastEmbed
pub struct LocalEmbeddingGenerator {
    model: TextEmbedding,
    config: LocalEmbeddingConfig,
}

impl LocalEmbeddingGenerator {
    /// Create a new local embedding generator with default configuration
    pub fn new() -> ParagonicResult<Self> {
        Self::with_config(LocalEmbeddingConfig::default())
    }

    /// Create a new local embedding generator with specific model
    pub fn with_model(model_type: EmbeddingModelType) -> ParagonicResult<Self> {
        let mut config = LocalEmbeddingConfig::default();
        config.model_type = model_type;
        Self::with_config(config)
    }

    /// Create a new local embedding generator with custom configuration
    pub fn with_config(config: LocalEmbeddingConfig) -> ParagonicResult<Self> {
        info!("Initializing FastEmbed with model: {}", config.model_type);

        let model = match config.model_type {
            EmbeddingModelType::BgeSmallEnV15 => EmbeddingModel::BGESmallENV15,
            EmbeddingModelType::AllMiniLML6V2 => EmbeddingModel::AllMiniLML6V2,
            EmbeddingModelType::NomicEmbedTextV15 => EmbeddingModel::NomicEmbedTextV15,
            EmbeddingModelType::BgeLargeEnV15 => EmbeddingModel::BGELargeENV15,
        };

        let mut init_options = InitOptions::new(model);
        
        if let Some(cache_dir) = &config.cache_dir {
            init_options = init_options.with_cache_dir(cache_dir.clone());
        }

        if config.show_download_progress {
            init_options = init_options.with_show_download_progress(true);
        }

        let model = TextEmbedding::try_new(init_options)
            .map_err(|e| {
                warn!("Failed to initialize FastEmbed: {}", e);
                ParagonicError::Internal(format!("Failed to initialize FastEmbed: {}", e))
            })?;

        info!("FastEmbed initialized successfully with model: {}", config.model_type);
        Ok(Self { model, config })
    }

    /// Generate a single embedding for the given text
    pub fn generate_embedding(&mut self, text: &str) -> ParagonicResult<Vec<f32>> {
        debug!("Generating embedding for text ({} chars)", text.len());

        if text.trim().is_empty() {
            return Err(ParagonicError::InvalidInput("Text cannot be empty".to_string()));
        }

        let embeddings = self.model.embed(vec![text], None)
            .map_err(|e| {
                warn!("Failed to generate embedding: {}", e);
                ParagonicError::Internal(format!("Failed to generate embedding: {}", e))
            })?;

        if embeddings.is_empty() {
            return Err(ParagonicError::Internal("No embedding generated".to_string()));
        }

        debug!("Generated embedding with {} dimensions", embeddings[0].len());
        Ok(embeddings[0].clone())
    }

    /// Generate embeddings for multiple texts in batch
    pub fn generate_embeddings_batch(&mut self, texts: Vec<String>) -> ParagonicResult<Vec<Vec<f32>>> {
        if texts.is_empty() {
            return Ok(vec![]);
        }

        debug!("Generating batch embeddings for {} texts", texts.len());

        // Filter out empty texts
        let valid_texts: Vec<String> = texts.into_iter()
            .filter(|text| !text.trim().is_empty())
            .collect();

        if valid_texts.is_empty() {
            return Err(ParagonicError::InvalidInput("All texts are empty".to_string()));
        }

        let text_refs: Vec<&str> = valid_texts.iter().map(|s| s.as_str()).collect();
        
        let embeddings = self.model.embed(text_refs, None)
            .map_err(|e| {
                warn!("Failed to generate batch embeddings: {}", e);
                ParagonicError::Internal(format!("Failed to generate batch embeddings: {}", e))
            })?;

        debug!("Generated {} embeddings in batch", embeddings.len());
        Ok(embeddings)
    }

    /// Get the embedding dimensions for the current model
    pub fn embedding_dimensions(&self) -> usize {
        // FastEmbed models have different dimensions
        match self.config.model_type {
            EmbeddingModelType::BgeSmallEnV15 => 384,
            EmbeddingModelType::AllMiniLML6V2 => 384,
            EmbeddingModelType::NomicEmbedTextV15 => 768,
            EmbeddingModelType::BgeLargeEnV15 => 1024,
        }
    }

    /// Get the current configuration
    pub fn config(&self) -> &LocalEmbeddingConfig {
        &self.config
    }

    /// Get the model type
    pub fn model_type(&self) -> EmbeddingModelType {
        self.config.model_type
    }
}

/// Batch processor for efficient embedding generation
pub struct BatchEmbeddingProcessor {
    generator: LocalEmbeddingGenerator,
    batch_size: usize,
}

impl BatchEmbeddingProcessor {
    /// Create a new batch processor
    pub fn new(generator: LocalEmbeddingGenerator) -> Self {
        let batch_size = generator.config().batch_size;
        Self { generator, batch_size }
    }

    /// Create a new batch processor with custom batch size
    pub fn with_batch_size(generator: LocalEmbeddingGenerator, batch_size: usize) -> Self {
        Self { generator, batch_size }
    }

    /// Process a large number of texts in batches
    pub fn process_batches(&mut self, texts: Vec<String>) -> ParagonicResult<Vec<Vec<f32>>> {
        if texts.is_empty() {
            return Ok(vec![]);
        }

        info!("Processing {} texts in batches of {}", texts.len(), self.batch_size);

        let mut all_embeddings = Vec::new();
        let mut current_batch = Vec::new();

        let texts_len = texts.len();
        for text in texts {
            current_batch.push(text);

            if current_batch.len() >= self.batch_size {
                let batch_embeddings = self.generator.generate_embeddings_batch(current_batch)?;
                all_embeddings.extend(batch_embeddings);
                current_batch = Vec::new();
            }
        }

        // Process remaining texts
        if !current_batch.is_empty() {
            let batch_embeddings = self.generator.generate_embeddings_batch(current_batch)?;
            all_embeddings.extend(batch_embeddings);
        }

        info!("Successfully processed {} texts into {} embeddings", texts_len, all_embeddings.len());
        Ok(all_embeddings)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_embedding_model_type_display() {
        assert_eq!(EmbeddingModelType::BgeSmallEnV15.to_string(), "BgeSmallEnV15");
        assert_eq!(EmbeddingModelType::AllMiniLML6V2.to_string(), "AllMiniLML6V2");
        assert_eq!(EmbeddingModelType::NomicEmbedTextV15.to_string(), "NomicEmbedTextV15");
        assert_eq!(EmbeddingModelType::BgeLargeEnV15.to_string(), "BgeLargeEnV15");
    }

    #[test]
    fn test_embedding_model_type_default() {
        assert_eq!(EmbeddingModelType::default(), EmbeddingModelType::BgeSmallEnV15);
    }

    #[test]
    fn test_local_embedding_config_default() {
        let config = LocalEmbeddingConfig::default();
        assert_eq!(config.model_type, EmbeddingModelType::BgeSmallEnV15);
        assert_eq!(config.batch_size, 256);
        assert_eq!(config.show_download_progress, false);
        assert_eq!(config.cache_dir, None);
    }

    #[test]
    fn test_embedding_dimensions() {
        let config = LocalEmbeddingConfig {
            model_type: EmbeddingModelType::BgeSmallEnV15,
            ..Default::default()
        };
        let generator = LocalEmbeddingGenerator::with_config(config).unwrap();
        assert_eq!(generator.embedding_dimensions(), 384);

        let config = LocalEmbeddingConfig {
            model_type: EmbeddingModelType::NomicEmbedTextV15,
            ..Default::default()
        };
        let generator = LocalEmbeddingGenerator::with_config(config).unwrap();
        assert_eq!(generator.embedding_dimensions(), 768);
    }

    #[tokio::test]
    async fn test_generate_embedding() {
        let mut generator = LocalEmbeddingGenerator::new().unwrap();
        
        let text = "This is a test text for embedding generation.";
        let embedding = generator.generate_embedding(text).unwrap();
        
        assert_eq!(embedding.len(), generator.embedding_dimensions());
        assert!(!embedding.iter().all(|&x| x == 0.0)); // Should not be all zeros
    }

    #[tokio::test]
    async fn test_generate_embeddings_batch() {
        let mut generator = LocalEmbeddingGenerator::new().unwrap();
        
        let texts = vec![
            "First test text.".to_string(),
            "Second test text.".to_string(),
            "Third test text.".to_string(),
        ];
        
        let embeddings = generator.generate_embeddings_batch(texts).unwrap();
        
        assert_eq!(embeddings.len(), 3);
        for embedding in &embeddings {
            assert_eq!(embedding.len(), generator.embedding_dimensions());
            assert!(!embedding.iter().all(|&x| x == 0.0));
        }
    }

    #[tokio::test]
    async fn test_empty_text_handling() {
        let mut generator = LocalEmbeddingGenerator::new().unwrap();
        
        // Empty text should return error
        let result = generator.generate_embedding("");
        assert!(result.is_err());
        
        // Empty batch should return empty result
        let result = generator.generate_embeddings_batch(vec![]);
        assert!(result.is_ok());
        assert_eq!(result.unwrap().len(), 0);
    }

    #[tokio::test]
    async fn test_batch_processor() {
        let generator = LocalEmbeddingGenerator::new().unwrap();
        let mut processor = BatchEmbeddingProcessor::with_batch_size(generator, 2);
        
        let texts = vec![
            "Text 1".to_string(),
            "Text 2".to_string(),
            "Text 3".to_string(),
            "Text 4".to_string(),
            "Text 5".to_string(),
        ];
        
        let embeddings = processor.process_batches(texts).unwrap();
        assert_eq!(embeddings.len(), 5);
    }

    /// Integration test to verify FastEmbed works end-to-end
    #[tokio::test]
    async fn test_fastembed_integration() {
        // Test that we can create a generator and generate embeddings
        let mut generator = LocalEmbeddingGenerator::new().unwrap();
        
        // Test single embedding
        let text = "This is a test sentence for FastEmbed integration.";
        let embedding = generator.generate_embedding(text).unwrap();
        
        // Verify embedding properties
        assert_eq!(embedding.len(), generator.embedding_dimensions());
        assert!(!embedding.iter().all(|&x| x == 0.0)); // Should not be all zeros
        assert!(embedding.iter().all(|&x| x.is_finite())); // All values should be finite
        
        // Test batch embeddings
        let texts = vec![
            "First test sentence.".to_string(),
            "Second test sentence.".to_string(),
            "Third test sentence.".to_string(),
        ];
        
        let batch_embeddings = generator.generate_embeddings_batch(texts).unwrap();
        assert_eq!(batch_embeddings.len(), 3);
        
        // Verify all embeddings have correct dimensions
        for embedding in &batch_embeddings {
            assert_eq!(embedding.len(), generator.embedding_dimensions());
            assert!(!embedding.iter().all(|&x| x == 0.0));
            assert!(embedding.iter().all(|&x| x.is_finite()));
        }
        
        // Test that embeddings are different (not identical)
        assert_ne!(batch_embeddings[0], batch_embeddings[1]);
        assert_ne!(batch_embeddings[1], batch_embeddings[2]);
        assert_ne!(batch_embeddings[0], batch_embeddings[2]);
    }
}
