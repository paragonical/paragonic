//! Local embedding generation using FastEmbed
//!
//! This module provides local vector embedding generation capabilities,
//! decoupling embedding generation from Ollama and enabling more efficient
//! IRAGL knowledge stream processing.

use crate::error::{ParagonicError, ParagonicResult};
use fastembed::{EmbeddingModel, InitOptions, TextEmbedding};

/// Supported embedding model types for different use cases
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum EmbeddingModelType {
    /// Default for general text - good balance of quality and speed
    BgeSmallEnV15,
    /// Fast, good quality for real-time applications
    AllMiniLML6V2,
    /// High quality, larger model for critical applications
    NomicEmbedTextV15,
    /// Best quality, slower for high-precision tasks
    BgeLargeEnV15,
}

impl Default for EmbeddingModelType {
    fn default() -> Self {
        Self::BgeSmallEnV15
    }
}

/// Local embedding generator using FastEmbed
pub struct LocalEmbeddingGenerator {
    model: TextEmbedding,
    model_type: EmbeddingModelType,
}

impl LocalEmbeddingGenerator {
    /// Create a new embedding generator with default model
    pub fn new() -> ParagonicResult<Self> {
        Self::with_model(EmbeddingModelType::default())
    }

    /// Create a new embedding generator with specified model
    pub fn with_model(model_type: EmbeddingModelType) -> ParagonicResult<Self> {
        let model = match model_type {
            EmbeddingModelType::BgeSmallEnV15 => EmbeddingModel::BGESmallENV15,
            EmbeddingModelType::AllMiniLML6V2 => EmbeddingModel::AllMiniLML6V2,
            EmbeddingModelType::NomicEmbedTextV15 => EmbeddingModel::NomicEmbedTextV15,
            EmbeddingModelType::BgeLargeEnV15 => EmbeddingModel::BGELargeENV15,
        };

        let init_options = InitOptions::new(model);
        let model = TextEmbedding::try_new(init_options).map_err(|e| {
            ParagonicError::Internal(format!("Failed to initialize FastEmbed: {}", e))
        })?;

        Ok(Self { model, model_type })
    }

    /// Generate embedding for a single text
    pub fn generate_embedding(&mut self, text: &str) -> ParagonicResult<Vec<f32>> {
        let embeddings = self.model.embed(vec![text], None).map_err(|e| {
            ParagonicError::Internal(format!("Failed to generate embedding: {}", e))
        })?;

        Ok(embeddings[0].clone())
    }

    /// Generate embeddings for multiple texts in batch
    pub fn generate_embeddings_batch(
        &mut self,
        texts: Vec<String>,
    ) -> ParagonicResult<Vec<Vec<f32>>> {
        let text_refs: Vec<&str> = texts.iter().map(|s| s.as_str()).collect();
        let embeddings = self.model.embed(text_refs, None).map_err(|e| {
            ParagonicError::Internal(format!("Failed to generate batch embeddings: {}", e))
        })?;

        Ok(embeddings)
    }

    /// Get the dimensionality of the embedding model
    pub fn embedding_dimensions(&self) -> usize {
        // FastEmbed models have fixed dimensions based on the model type
        // BGESmallENV15: 384, AllMiniLML6V2: 384, NomicEmbedTextV15: 768, BGELargeENV15: 1024
        match self.model_type {
            EmbeddingModelType::BgeSmallEnV15 => 384,
            EmbeddingModelType::AllMiniLML6V2 => 384,
            EmbeddingModelType::NomicEmbedTextV15 => 768,
            EmbeddingModelType::BgeLargeEnV15 => 1024,
        }
    }

    /// Get the model name
    pub fn model_name(&self) -> &'static str {
        match self.model_type {
            EmbeddingModelType::BgeSmallEnV15 => "BgeSmallEnV15",
            EmbeddingModelType::AllMiniLML6V2 => "AllMiniLML6V2",
            EmbeddingModelType::NomicEmbedTextV15 => "NomicEmbedTextV15",
            EmbeddingModelType::BgeLargeEnV15 => "BgeLargeEnV15",
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Test creating a LocalEmbeddingGenerator with default model
    #[test]
    fn test_create_default_generator() {
        let result = LocalEmbeddingGenerator::new();
        assert!(result.is_ok(), "Should create generator with default model");

        let generator = result.unwrap();
        assert_eq!(generator.model_name(), "BgeSmallEnV15");
        assert!(generator.embedding_dimensions() > 0);
    }

    /// Test generating a single embedding
    #[test]
    fn test_generate_single_embedding() {
        let mut generator = LocalEmbeddingGenerator::new().unwrap();
        let text = "Hello, world! This is a test sentence.";

        let result = generator.generate_embedding(text);
        assert!(result.is_ok(), "Should generate embedding successfully");

        let embedding = result.unwrap();
        assert_eq!(embedding.len(), generator.embedding_dimensions());
        assert!(
            embedding.iter().all(|&x| x.is_finite()),
            "All values should be finite"
        );
    }
}
