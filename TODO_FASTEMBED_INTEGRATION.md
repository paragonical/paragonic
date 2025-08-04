# TODO: FastEmbed Integration for Local Vector Embeddings

## Overview
Integrate [fastembed](https://lib.rs/crates/fastembed) to enable local vector embedding generation, decoupling this functionality from Ollama and enabling more efficient IRAGL knowledge stream processing.

## Rationale
- **Decoupling**: Separate embedding generation from chat completion, allowing independent scaling
- **Performance**: Local embedding generation reduces latency and network dependencies
- **IRAGL Optimization**: Enables continuous background processing of knowledge streams
- **Cost Efficiency**: Avoids API costs for embedding generation
- **Offline Capability**: Works without external services for embedding generation

## Implementation Plan

### 1. Add FastEmbed Dependency
```toml
[dependencies]
fastembed = "4"
```

### 2. Create New Embedding Module
Create `src/embeddings_local.rs` to handle local embedding generation:

```rust
use fastembed::{TextEmbedding, InitOptions, EmbeddingModel};
use crate::error::{ParagonicError, ParagonicResult};

pub struct LocalEmbeddingGenerator {
    model: TextEmbedding,
}

impl LocalEmbeddingGenerator {
    pub fn new() -> ParagonicResult<Self> {
        let model = TextEmbedding::try_new(Default::default())
            .map_err(|e| ParagonicError::Internal(format!("Failed to initialize FastEmbed: {}", e)))?;
        
        Ok(Self { model })
    }
    
    pub fn generate_embedding(&mut self, text: &str) -> ParagonicResult<Vec<f32>> {
        let embeddings = self.model.embed(vec![text], None)
            .map_err(|e| ParagonicError::Internal(format!("Failed to generate embedding: {}", e)))?;
        
        Ok(embeddings[0].clone())
    }
    
    pub fn generate_embeddings_batch(&mut self, texts: Vec<String>) -> ParagonicResult<Vec<Vec<f32>>> {
        let text_refs: Vec<&str> = texts.iter().map(|s| s.as_str()).collect();
        let embeddings = self.model.embed(text_refs, None)
            .map_err(|e| ParagonicError::Internal(format!("Failed to generate batch embeddings: {}", e)))?;
        
        Ok(embeddings)
    }
}
```

### 3. Update IRAGL Knowledge Stream Processing
Modify knowledge stream ingestion to use local embeddings:

```rust
// In src/operations.rs or new IRAGL module
pub async fn ingest_knowledge_stream(
    content_type: &str,
    content_text: &str,
    source_entity_type: &str,
    source_entity_id: Uuid,
    metadata: Option<Value>,
) -> ParagonicResult<Uuid> {
    // Generate embedding locally
    let mut embedding_generator = LocalEmbeddingGenerator::new()?;
    let embedding_vector = embedding_generator.generate_embedding(content_text)?;
    
    // Store in knowledge_streams table
    // ... implementation
}
```

### 4. Model Selection Strategy
Support multiple embedding models for different use cases:

```rust
pub enum EmbeddingModelType {
    BgeSmallEnV15,      // Default for general text
    AllMiniLML6V2,      // Fast, good quality
    NomicEmbedTextV15,  // High quality, larger
    BgeLargeEnV15,      // Best quality, slower
}

impl LocalEmbeddingGenerator {
    pub fn with_model(model_type: EmbeddingModelType) -> ParagonicResult<Self> {
        let model = match model_type {
            EmbeddingModelType::BgeSmallEnV15 => EmbeddingModel::BgeSmallEnV15,
            EmbeddingModelType::AllMiniLML6V2 => EmbeddingModel::AllMiniLML6V2,
            EmbeddingModelType::NomicEmbedTextV15 => EmbeddingModel::NomicEmbedTextV15,
            EmbeddingModelType::BgeLargeEnV15 => EmbeddingModel::BgeLargeEnV15,
        };
        
        let init_options = InitOptions::new(model);
        let model = TextEmbedding::try_new(init_options)
            .map_err(|e| ParagonicError::Internal(format!("Failed to initialize FastEmbed: {}", e)))?;
        
        Ok(Self { model })
    }
}
```

### 5. Batch Processing for IRAGL
Implement efficient batch processing for knowledge stream optimization:

```rust
pub async fn optimize_knowledge_streams_batch(
    knowledge_streams: Vec<KnowledgeStream>,
) -> ParagonicResult<Vec<OptimizedKnowledgeStream>> {
    let mut embedding_generator = LocalEmbeddingGenerator::new()?;
    
    // Extract texts for batch processing
    let texts: Vec<String> = knowledge_streams.iter()
        .map(|ks| ks.content_text.clone())
        .collect();
    
    // Generate embeddings in batch
    let embeddings = embedding_generator.generate_embeddings_batch(texts)?;
    
    // Process and optimize
    // ... implementation
}
```

### 6. Configuration Integration
Add FastEmbed configuration to the config system:

```rust
// In src/config.rs
pub struct EmbeddingConfig {
    pub model_type: EmbeddingModelType,
    pub batch_size: usize,
    pub show_download_progress: bool,
    pub cache_dir: Option<PathBuf>,
}

impl Default for EmbeddingConfig {
    fn default() -> Self {
        Self {
            model_type: EmbeddingModelType::BgeSmallEnV15,
            batch_size: 256,
            show_download_progress: false,
            cache_dir: None,
        }
    }
}
```

### 7. Migration Strategy
- Keep Ollama integration for chat completion
- Gradually migrate embedding generation to FastEmbed
- Add feature flag to switch between Ollama and FastEmbed embeddings
- Update existing embeddings table to support both sources

### 8. Testing Strategy
- Unit tests for LocalEmbeddingGenerator
- Integration tests for batch processing
- Performance benchmarks comparing Ollama vs FastEmbed
- Test different embedding models for quality/performance trade-offs

## Benefits for IRAGL System

### 1. Continuous Optimization
- Background processes can generate embeddings without external dependencies
- Real-time knowledge stream processing
- Efficient batch optimization of existing content

### 2. Differential Geometry Optimization
- Local embedding generation enables the Yurts-inspired optimization techniques
- Functionally-invariant path adaptation can work with local vectors
- Geometry-based knowledge optimization becomes feasible

### 3. Resilience and Recovery
- System continues working even if Ollama is unavailable
- Self-healing mechanisms can regenerate embeddings locally
- Experience replay can refresh embeddings without external calls

### 4. Performance Improvements
- Reduced latency for embedding generation
- No network overhead for vector computation
- Parallel processing capabilities for large knowledge bases

## Implementation Priority

1. **Phase 1**: Add FastEmbed dependency and basic LocalEmbeddingGenerator
2. **Phase 2**: Integrate with knowledge stream ingestion
3. **Phase 3**: Implement batch processing for optimization
4. **Phase 4**: Add configuration and model selection
5. **Phase 5**: Performance optimization and testing

## Dependencies
- [fastembed = "4"](https://lib.rs/crates/fastembed)
- May need additional dependencies for model caching and management

## Notes
- FastEmbed supports multiple embedding models with different quality/speed trade-offs
- Models are downloaded automatically on first use
- Consider implementing model caching to avoid repeated downloads
- Test memory usage with different model sizes
- Evaluate embedding quality compared to Ollama's embeddings 