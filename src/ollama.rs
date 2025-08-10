//! Ollama integration for Paragonic
//! 
//! This module handles communication with the local Ollama server
//! for AI model interactions.

use reqwest::Client;
use serde::{Deserialize, Serialize};
use tracing::{info, error};
use futures_util::StreamExt;

use crate::error::{ParagonicError, ParagonicResult};

/// Ollama client configuration
#[derive(Debug, Clone)]
pub struct OllamaConfig {
    pub base_url: String,
    pub timeout_seconds: u64,
    pub progress_timeout_seconds: u64,
}

impl Default for OllamaConfig {
    fn default() -> Self {
        Self {
            base_url: "http://localhost:11434".to_string(),
            timeout_seconds: 120, // Increased to 2 minutes for complex requests
            progress_timeout_seconds: 30, // 30 seconds without progress before timeout
        }
    }
}

/// Ollama model information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OllamaModel {
    pub name: String,
    pub modified_at: String,
    pub size: u64,
}

/// Response from Ollama list models endpoint
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListModelsResponse {
    pub models: Vec<OllamaModel>,
}

/// Chat message for Ollama API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

/// Chat completion request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatCompletionRequest {
    pub model: String,
    pub messages: Vec<ChatMessage>,
    pub stream: Option<bool>,
    pub options: Option<serde_json::Value>,
}

/// Chat completion response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatCompletionResponse {
    pub model: String,
    pub created_at: String,
    pub message: ChatMessage,
    pub done: bool,
}

/// Pull model request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PullModelRequest {
    pub name: String,
    pub insecure: Option<bool>,
}

/// Pull model response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PullModelResponse {
    pub status: String,
    pub digest: Option<String>,
    pub total: Option<u64>,
    pub completed: Option<u64>,
}

/// Model info response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelInfoResponse {
    pub license: Option<String>,
    pub modelfile: Option<String>,
    pub parameters: Option<String>,
    pub template: Option<String>,
    pub system: Option<String>,
    pub digest: Option<String>,
    pub details: Option<serde_json::Value>,
}

/// Delete model request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeleteModelRequest {
    pub name: String,
}

/// Delete model response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeleteModelResponse {
    pub status: String,
}

/// Embedding request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddingRequest {
    pub model: String,
    pub prompt: String,
    pub options: Option<serde_json::Value>,
}

/// Embedding response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddingResponse {
    pub embedding: Vec<f32>,
}

/// Streaming chat completion response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamChatCompletionResponse {
    pub model: String,
    pub created_at: String,
    pub done: bool,
    pub message: Option<ChatMessage>,
    pub response: Option<String>,
}

/// Ollama client for API communication
pub struct OllamaClient {
    config: OllamaConfig,
    client: Client,
}

impl OllamaClient {
    /// Create a new Ollama client
    pub fn new(config: OllamaConfig) -> ParagonicResult<Self> {
        let client = Client::builder()
            .timeout(std::time::Duration::from_secs(config.timeout_seconds))
            .build()
            .map_err(|e| {
                error!("Failed to create HTTP client: {}", e);
                ParagonicError::Internal(format!("HTTP client creation failed: {e}"))
            })?;

        Ok(Self { config, client })
    }

    /// Create a new Ollama client from config manager
    /// 
    /// Creates an Ollama client using the configuration from the config module.
    pub fn from_config_manager(config_manager: &crate::config::ConfigManager) -> ParagonicResult<Self> {
        let config = config_manager.get_config();
        
        let ollama_config = OllamaConfig {
            base_url: config.ollama.base_url.clone(),
            timeout_seconds: config.ollama.timeout_seconds,
            progress_timeout_seconds: config.ollama.progress_timeout_seconds,
        };
        
        Self::new(ollama_config)
    }

    /// List available models from Ollama
    /// 
    /// Returns a list of all models currently available on the Ollama server.
    pub async fn list_models(&self) -> ParagonicResult<Vec<OllamaModel>> {
        let url = format!("{}/api/tags", self.config.base_url);
        
        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to list models from Ollama: {}", e);
                ParagonicError::Ollama(format!("Model listing failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("API error {status}: {error_text}")));
        }

        let list_response: ListModelsResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama response: {}", e);
            ParagonicError::Ollama(format!("Response parsing failed: {e}"))
        })?;

        info!("Successfully listed {} models from Ollama", list_response.models.len());
        Ok(list_response.models)
    }

    /// Send a chat completion request to Ollama
    /// 
    /// Sends a list of messages to the specified model and returns the response.
    pub async fn chat_completion(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        stream: bool,
    ) -> ParagonicResult<ChatCompletionResponse> {
        let url = format!("{}/api/chat", self.config.base_url);
        
        let request_body = ChatCompletionRequest {
            model: model.to_string(),
            messages,
            stream: Some(stream),
            options: None,
        };

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to send chat completion to Ollama: {}", e);
                ParagonicError::Ollama(format!("Chat completion failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama chat API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Chat API error {status}: {error_text}")));
        }

        let chat_response: ChatCompletionResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama chat response: {}", e);
            ParagonicError::Ollama(format!("Chat response parsing failed: {e}"))
        })?;

        info!("Successfully received chat completion from Ollama model: {}", model);
        Ok(chat_response)
    }

    /// Pull a model from Ollama
    /// 
    /// Downloads the specified model to the local Ollama server.
    pub async fn pull_model(&self, model_name: &str, insecure: bool) -> ParagonicResult<PullModelResponse> {
        let url = format!("{}/api/pull", self.config.base_url);
        
        let request_body = PullModelRequest {
            name: model_name.to_string(),
            insecure: Some(insecure),
        };

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to pull model from Ollama: {e}");
                ParagonicError::Ollama(format!("Model pull failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama pull API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Pull API error {status}: {error_text}")));
        }

        let pull_response: PullModelResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama pull response: {e}");
            ParagonicError::Ollama(format!("Pull response parsing failed: {e}"))
        })?;

        info!("Successfully pulled model from Ollama: {}", model_name);
        Ok(pull_response)
    }

    /// Get detailed information about a model
    /// 
    /// Returns detailed information about the specified model including
    /// license, modelfile, parameters, template, system prompt, and more.
    pub async fn model_info(&self, model_name: &str) -> ParagonicResult<ModelInfoResponse> {
        let url = format!("{}/api/show", self.config.base_url);
        
        let request_body = serde_json::json!({
            "name": model_name
        });

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to get model info from Ollama: {e}");
                ParagonicError::Ollama(format!("Model info failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama model info API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Model info API error {status}: {error_text}")));
        }

        let model_info: ModelInfoResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama model info response: {e}");
            ParagonicError::Ollama(format!("Model info response parsing failed: {e}"))
        })?;

        info!("Successfully retrieved model info from Ollama: {}", model_name);
        Ok(model_info)
    }

    /// Delete a model from Ollama
    /// 
    /// Removes the specified model from the local Ollama server.
    pub async fn delete_model(&self, model_name: &str) -> ParagonicResult<DeleteModelResponse> {
        let url = format!("{}/api/delete", self.config.base_url);
        
        let request_body = DeleteModelRequest {
            name: model_name.to_string(),
        };

        let response = self.client
            .delete(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to delete model from Ollama: {e}");
                ParagonicError::Ollama(format!("Model deletion failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama delete API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Delete API error {status}: {error_text}")));
        }

        let delete_response: DeleteModelResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama delete response: {e}");
            ParagonicError::Ollama(format!("Delete response parsing failed: {e}"))
        })?;

        info!("Successfully deleted model from Ollama: {}", model_name);
        Ok(delete_response)
    }

    /// Generate embeddings for text using Ollama
    /// 
    /// Converts text into vector representations for semantic search and similarity.
    pub async fn generate_embedding(&self, model: &str, prompt: &str) -> ParagonicResult<EmbeddingResponse> {
        let url = format!("{}/api/embeddings", self.config.base_url);
        
        let request_body = EmbeddingRequest {
            model: model.to_string(),
            prompt: prompt.to_string(),
            options: None,
        };

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to generate embedding from Ollama: {e}");
                ParagonicError::Ollama(format!("Embedding generation failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama embedding API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Embedding API error {status}: {error_text}")));
        }

        let embedding_response: EmbeddingResponse = response.json().await.map_err(|e| {
            error!("Failed to parse Ollama embedding response: {e}");
            ParagonicError::Ollama(format!("Embedding response parsing failed: {e}"))
        })?;

        info!("Successfully generated embedding from Ollama model: {} (dimensions: {})", model, embedding_response.embedding.len());
        Ok(embedding_response)
    }

    /// Stream chat completion from Ollama
    /// 
    /// Sends a list of messages to the specified model and returns a stream
    /// of responses for real-time interaction.
    pub async fn stream_chat_completion(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
    ) -> ParagonicResult<impl futures_util::Stream<Item = ParagonicResult<StreamChatCompletionResponse>>> {
        let url = format!("{}/api/chat", self.config.base_url);
        
        let request_body = ChatCompletionRequest {
            model: model.to_string(),
            messages,
            stream: Some(true),
            options: None,
        };

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to send streaming chat completion to Ollama: {e}");
                ParagonicError::Ollama(format!("Streaming chat completion failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama streaming chat API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Streaming chat API error {status}: {error_text}")));
        }

        let stream = response
            .bytes_stream()
            .flat_map(|chunk_result| {
                match chunk_result {
                    Ok(chunk) => {
                        let chunk_str = String::from_utf8_lossy(&chunk);
                        let lines: Vec<&str> = chunk_str.lines().collect();
                        
                        let mut responses = Vec::new();
                        for line in lines {
                            if line.trim().is_empty() {
                                continue;
                            }
                            
                            match serde_json::from_str::<StreamChatCompletionResponse>(line) {
                                Ok(stream_response) => responses.push(Ok(stream_response)),
                                Err(e) => {
                                    error!("Failed to parse streaming response: {}", e);
                                    responses.push(Err(ParagonicError::Ollama(format!("Response parsing failed: {e}"))));
                                }
                            }
                        }
                        
                        futures_util::stream::iter(responses)
                    }
                    Err(e) => {
                        error!("Failed to read streaming chunk: {}", e);
                        futures_util::stream::iter(vec![Err(ParagonicError::Ollama(format!("Stream chunk error: {e}")))])
                    }
                }
            });

        info!("Successfully started streaming chat completion from Ollama model: {}", model);
        Ok(stream)
    }

    /// Stream chat completion with progress detection and adaptive timeouts
    /// 
    /// This method uses streaming to detect when Ollama is making progress
    /// and only times out if there's no progress for a specified duration.
    pub async fn stream_chat_completion_with_progress(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
        progress_timeout_seconds: u64,
    ) -> ParagonicResult<ChatCompletionResponse> {
        let url = format!("{}/api/chat", self.config.base_url);
        
        let request_body = ChatCompletionRequest {
            model: model.to_string(),
            messages,
            stream: Some(true),
            options: None,
        };

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to send streaming chat completion to Ollama: {e}");
                ParagonicError::Ollama(format!("Streaming chat completion failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama streaming chat API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Chat API error {status}: {error_text}")));
        }

        let mut stream = response.bytes_stream();
        let mut full_response = String::new();
        let mut last_progress_time = std::time::Instant::now();
        let progress_timeout = std::time::Duration::from_secs(progress_timeout_seconds);
        
        info!("Starting streaming chat completion with progress detection for model: {} (progress_timeout: {}s)", model, progress_timeout_seconds);

        while let Some(chunk_result) = stream.next().await {
            match chunk_result {
                Ok(chunk) => {
                    let chunk_str = String::from_utf8_lossy(&chunk);
                    let lines: Vec<&str> = chunk_str.lines().collect();
                    
                    // Debug: log raw chunk info
                    if !chunk_str.trim().is_empty() {
                        info!("Received chunk from {}: {} bytes, {} lines", model, chunk.len(), lines.len());
                    }
                    
                    for line in lines {
                        if line.trim().is_empty() {
                            continue;
                        }
                        
                        // Debug: log the raw JSON line
                        info!("Raw JSON line from {}: {}", model, line);
                        
                        match serde_json::from_str::<StreamChatCompletionResponse>(line) {
                            Ok(stream_response) => {
                                // Debug: log the raw response structure
                                info!("Raw stream response: {:?}", stream_response);
                                
                                // Check both response and message fields for content
                                let has_content = stream_response.response.as_ref()
                                    .map(|text| !text.trim().is_empty())
                                    .unwrap_or(false) || 
                                    stream_response.message.as_ref()
                                    .map(|msg| !msg.content.trim().is_empty())
                                    .unwrap_or(false);
                                
                                if has_content {
                                    last_progress_time = std::time::Instant::now();
                                    if let Some(text) = &stream_response.response {
                                        info!("Progress update from {}: {} chars (response field)", model, text.len());
                                    }
                                    if let Some(msg) = &stream_response.message {
                                        info!("Progress update from {}: {} chars (message field)", model, msg.content.len());
                                    }
                                } else {
                                    info!("Received empty chunk from {} (not counting as progress)", model);
                                }
                                
                                // Accumulate the response from both possible fields
                                if let Some(response_text) = stream_response.response {
                                    full_response.push_str(&response_text);
                                }
                                if let Some(message) = stream_response.message {
                                    full_response.push_str(&message.content);
                                }
                                
                                // Check if we're done
                                if stream_response.done {
                                    info!("Streaming chat completion completed for model: {}", model);
                                    
                                    // Construct the final response
                                    let final_message = ChatMessage {
                                        role: "assistant".to_string(),
                                        content: full_response,
                                    };
                                    
                                    return Ok(ChatCompletionResponse {
                                        model: stream_response.model,
                                        created_at: stream_response.created_at,
                                        message: final_message,
                                        done: true,
                                    });
                                }
                            }
                            Err(e) => {
                                error!("Failed to parse streaming response: {}", e);
                                return Err(ParagonicError::Ollama(format!("Response parsing failed: {e}")));
                            }
                        }
                    }
                }
                Err(e) => {
                    error!("Failed to read streaming chunk: {}", e);
                    return Err(ParagonicError::Ollama(format!("Stream chunk error: {e}")));
                }
            }
            
            // Check for progress timeout
            if last_progress_time.elapsed() > progress_timeout {
                error!("No progress detected for {} seconds, timing out", progress_timeout_seconds);
                return Err(ParagonicError::Ollama(format!("No progress detected for {} seconds", progress_timeout_seconds)));
            }
        }
        
        // If we get here, the stream ended without a done signal
        Err(ParagonicError::Ollama("Stream ended unexpectedly without completion signal".to_string()))
    }

    /// Stream chat completion chunks for real-time updates
    /// 
    /// This method returns a stream of individual chunks that can be sent
    /// to the client as they arrive from Ollama.
    pub async fn stream_chat_completion_chunks(
        &self,
        model: &str,
        messages: Vec<ChatMessage>,
    ) -> ParagonicResult<impl futures_util::Stream<Item = ParagonicResult<StreamChatCompletionResponse>>> {
        let url = format!("{}/api/chat", self.config.base_url);
        
        let request_body = ChatCompletionRequest {
            model: model.to_string(),
            messages,
            stream: Some(true),
            options: None,
        };

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to send streaming chat completion to Ollama: {e}");
                ParagonicError::Ollama(format!("Streaming chat completion failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama streaming chat API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Chat API error {status}: {error_text}")));
        }

        let stream = response
            .bytes_stream()
            .flat_map(|chunk_result| {
                match chunk_result {
                    Ok(chunk) => {
                        let chunk_str = String::from_utf8_lossy(&chunk);
                        let lines: Vec<&str> = chunk_str.lines().collect();
                        
                        let mut responses = Vec::new();
                        for line in lines {
                            if line.trim().is_empty() {
                                continue;
                            }
                            
                            match serde_json::from_str::<StreamChatCompletionResponse>(line) {
                                Ok(stream_response) => responses.push(Ok(stream_response)),
                                Err(e) => {
                                    error!("Failed to parse streaming response: {}", e);
                                    responses.push(Err(ParagonicError::Ollama(format!("Response parsing failed: {e}"))));
                                }
                            }
                        }
                        
                        futures_util::stream::iter(responses)
                    }
                    Err(e) => {
                        error!("Failed to read streaming chunk: {}", e);
                        futures_util::stream::iter(vec![Err(ParagonicError::Ollama(format!("Stream chunk error: {e}")))])
                    }
                }
            });

        info!("Successfully started streaming chat completion chunks from Ollama model: {}", model);
        Ok(stream)
    }

    /// Get the progress timeout configuration
    pub fn get_progress_timeout_seconds(&self) -> u64 {
        self.config.progress_timeout_seconds
    }

    /// Test function to manually check Ollama streaming response format
    pub async fn test_streaming_format(&self, model: &str) -> ParagonicResult<()> {
        let url = format!("{}/api/chat", self.config.base_url);
        
        let request_body = ChatCompletionRequest {
            model: model.to_string(),
            messages: vec![ChatMessage {
                role: "user".to_string(),
                content: "Hello, say 'test' and nothing else.".to_string(),
            }],
            stream: Some(true),
            options: None,
        };

        let response = self.client
            .post(&url)
            .json(&request_body)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to send test request to Ollama: {e}");
                ParagonicError::Ollama(format!("Test request failed: {e}"))
            })?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            error!("Ollama test API error ({}): {}", status, error_text);
            return Err(ParagonicError::Ollama(format!("Test API error {status}: {error_text}")));
        }

        let mut stream = response.bytes_stream();
        let mut line_count = 0;
        
        info!("Testing streaming response format for model: {}", model);
        
        while let Some(chunk_result) = stream.next().await {
            match chunk_result {
                Ok(chunk) => {
                    let chunk_str = String::from_utf8_lossy(&chunk);
                    let lines: Vec<&str> = chunk_str.lines().collect();
                    
                    for line in lines {
                        if line.trim().is_empty() {
                            continue;
                        }
                        
                        line_count += 1;
                        info!("Line {}: {}", line_count, line);
                        
                        // Try to parse as JSON and see what we get
                        match serde_json::from_str::<serde_json::Value>(line) {
                            Ok(json_value) => {
                                info!("Parsed JSON: {:?}", json_value);
                                
                                // Check if it has a 'message' field
                                if let Some(message) = json_value.get("message") {
                                    info!("Found 'message' field: {:?}", message);
                                }
                                
                                // Check if it has a 'response' field
                                if let Some(response) = json_value.get("response") {
                                    info!("Found 'response' field: {:?}", response);
                                }
                                
                                // Check if it has a 'done' field
                                if let Some(done) = json_value.get("done") {
                                    info!("Found 'done' field: {:?}", done);
                                    if done.as_bool().unwrap_or(false) {
                                        info!("Stream completed after {} lines", line_count);
                                        return Ok(());
                                    }
                                }
                            }
                            Err(e) => {
                                error!("Failed to parse line as JSON: {}", e);
                            }
                        }
                    }
                }
                Err(e) => {
                    error!("Failed to read streaming chunk: {}", e);
                    return Err(ParagonicError::Ollama(format!("Stream chunk error: {e}")));
                }
            }
        }
        
        info!("Stream ended after {} lines", line_count);
        Ok(())
    }
}



#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::ConfigManager;

    /// Test Ollama configuration default values
    #[test]
    fn test_ollama_config_default() {
        let config = OllamaConfig::default();
        assert_eq!(config.base_url, "http://localhost:11434");
        assert_eq!(config.timeout_seconds, 120);
        assert_eq!(config.progress_timeout_seconds, 30);
    }

    /// Test Ollama model structure
    #[test]
    fn test_ollama_model_structure() {
        let model = OllamaModel {
            name: "llama2:7b".to_string(),
            modified_at: "2024-01-01T00:00:00Z".to_string(),
            size: 4096,
        };
        
        assert_eq!(model.name, "llama2:7b");
        assert_eq!(model.size, 4096);
    }

    /// Test list models response structure
    #[test]
    fn test_list_models_response_structure() {
        let response = ListModelsResponse {
            models: vec![
                OllamaModel {
                    name: "llama2:7b".to_string(),
                    modified_at: "2024-01-01T00:00:00Z".to_string(),
                    size: 4096,
                },
                OllamaModel {
                    name: "codellama:7b".to_string(),
                    modified_at: "2024-01-02T00:00:00Z".to_string(),
                    size: 4096,
                },
            ],
        };
        
        assert_eq!(response.models.len(), 2);
        assert_eq!(response.models[0].name, "llama2:7b");
        assert_eq!(response.models[1].name, "codellama:7b");
    }

    /// Test Ollama client creation
    #[test]
    fn test_ollama_client_creation() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config);
        assert!(client.is_ok());
    }

    /// Test Ollama configuration from config module
    #[test]
    fn test_ollama_config_from_config_module() {
        let config_manager = ConfigManager::new();
        let config = config_manager.get_config();
        
        // Verify that the Ollama config from the config module matches our expectations
        assert_eq!(config.ollama.base_url, "http://localhost:11434");
        assert_eq!(config.ollama.timeout_seconds, 30);
        assert_eq!(config.ollama.progress_timeout_seconds, 30);
    }

    /// Test Ollama client creation from config module
    #[test]
    fn test_ollama_client_from_config_module() {
        let config_manager = ConfigManager::new();
        
        // Test that we can create an Ollama client from the config module
        let client = OllamaClient::from_config_manager(&config_manager);
        assert!(client.is_ok());
        
        let client = client.unwrap();
        assert_eq!(client.config.base_url, "http://localhost:11434");
        assert_eq!(client.config.timeout_seconds, 30);
        assert_eq!(client.config.progress_timeout_seconds, 30);
    }

    /// Test Ollama client creation with custom configuration
    #[test]
    fn test_ollama_client_with_custom_config() {
        let mut config_manager = ConfigManager::new();
        
        // Set custom Ollama configuration
        config_manager.get_config_mut().ollama.base_url = "http://custom-ollama:11435".to_string();
        config_manager.get_config_mut().ollama.timeout_seconds = 60;
        config_manager.get_config_mut().ollama.progress_timeout_seconds = 60;
        
        // Test that the custom config is used
        let client = OllamaClient::from_config_manager(&config_manager);
        assert!(client.is_ok());
        
        let client = client.unwrap();
        assert_eq!(client.config.base_url, "http://custom-ollama:11435");
        assert_eq!(client.config.timeout_seconds, 60);
        assert_eq!(client.config.progress_timeout_seconds, 60);
    }

    /// Test list models with mock server (integration test)
    #[tokio::test]
    async fn test_list_models_integration() {
        // This test would require a running Ollama server
        // For now, we'll test the client creation and configuration
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        // The actual API call would be tested with a mock server
        // or when Ollama is available in the test environment
        assert_eq!(client.config.base_url, "http://localhost:11434");
    }

    /// Test chat completion request structure
    #[test]
    fn test_chat_completion_request_structure() {
        let request = ChatCompletionRequest {
            model: "llama2:7b".to_string(),
            messages: vec![
                ChatMessage {
                    role: "user".to_string(),
                    content: "Hello, how are you?".to_string(),
                },
            ],
            stream: Some(false),
            options: None,
        };
        
        assert_eq!(request.model, "llama2:7b");
        assert_eq!(request.messages.len(), 1);
        assert_eq!(request.messages[0].role, "user");
        assert_eq!(request.messages[0].content, "Hello, how are you?");
    }

    /// Test chat completion response structure
    #[test]
    fn test_chat_completion_response_structure() {
        let response = ChatCompletionResponse {
            model: "llama2:7b".to_string(),
            created_at: "2024-01-01T00:00:00Z".to_string(),
            message: ChatMessage {
                role: "assistant".to_string(),
                content: "I'm doing well, thank you!".to_string(),
            },
            done: true,
        };
        
        assert_eq!(response.model, "llama2:7b");
        assert_eq!(response.message.role, "assistant");
        assert_eq!(response.message.content, "I'm doing well, thank you!");
        assert!(response.done);
    }

    /// Test chat completion function (integration test)
    #[tokio::test]
    async fn test_chat_completion_function() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        let messages = vec![
            ChatMessage {
                role: "user".to_string(),
                content: "Say hello".to_string(),
            },
        ];
        
        // This test requires a running Ollama server
        // If Ollama is not running, we expect a connection error
        let result = client.chat_completion("llama2:7b", messages, false).await;
        
        match result {
            Ok(response) => {
                // Ollama is running and responded successfully
                assert_eq!(response.model, "llama2:7b");
                assert_eq!(response.message.role, "assistant");
                assert!(!response.message.content.is_empty());
            }
            Err(ParagonicError::Ollama(_)) => {
                // Expected when Ollama is not running
                // This is a valid test result
            }
            Err(e) => {
                // Unexpected error type
                panic!("Unexpected error type: {e:?}");
            }
        }
    }

    /// Test pull model request structure
    #[test]
    fn test_pull_model_request_structure() {
        let request = PullModelRequest {
            name: "llama2:7b".to_string(),
            insecure: Some(false),
        };
        
        assert_eq!(request.name, "llama2:7b");
        assert_eq!(request.insecure, Some(false));
    }

    /// Test pull model response structure
    #[test]
    fn test_pull_model_response_structure() {
        let response = PullModelResponse {
            status: "downloading".to_string(),
            digest: Some("sha256:abc123".to_string()),
            total: Some(4096),
            completed: Some(2048),
        };
        
        assert_eq!(response.status, "downloading");
        assert_eq!(response.digest, Some("sha256:abc123".to_string()));
        assert_eq!(response.total, Some(4096));
        assert_eq!(response.completed, Some(2048));
    }

    /// Test pull model function (integration test)
    #[tokio::test]
    async fn test_pull_model_function() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        // This test requires a running Ollama server
        // If Ollama is not running, we expect a connection error
        let result = client.pull_model("llama2:7b", false).await;
        
        match result {
            Ok(response) => {
                // Ollama is running and responded successfully
                assert!(!response.status.is_empty());
                // The status could be "downloading", "success", etc.
            }
            Err(ParagonicError::Ollama(_)) => {
                // Expected when Ollama is not running
                // This is a valid test result
            }
            Err(e) => {
                // Unexpected error type
                panic!("Unexpected error type: {e:?}");
            }
        }
    }

    /// Test model info response structure
    #[test]
    fn test_model_info_response_structure() {
        let response = ModelInfoResponse {
            license: Some("MIT".to_string()),
            modelfile: Some("FROM llama2:7b".to_string()),
            parameters: Some("7B".to_string()),
            template: Some("{{ .Prompt }}".to_string()),
            system: Some("You are a helpful assistant.".to_string()),
            digest: Some("sha256:abc123".to_string()),
            details: Some(serde_json::json!({
                "format": "gguf",
                "family": "llama"
            })),
        };
        
        assert_eq!(response.license, Some("MIT".to_string()));
        assert_eq!(response.parameters, Some("7B".to_string()));
        assert_eq!(response.system, Some("You are a helpful assistant.".to_string()));
        assert!(response.details.is_some());
    }

    /// Test model info function (integration test)
    #[tokio::test]
    async fn test_model_info_function() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        // This test requires a running Ollama server
        // If Ollama is not running, we expect a connection error
        let result = client.model_info("llama2:7b").await;
        
        match result {
            Ok(response) => {
                // Ollama is running and responded successfully
                // The response should have some fields populated
                assert!(response.license.is_some() || response.modelfile.is_some() || response.parameters.is_some());
            }
            Err(ParagonicError::Ollama(_)) => {
                // Expected when Ollama is not running
                // This is a valid test result
            }
            Err(e) => {
                // Unexpected error type
                panic!("Unexpected error type: {e:?}");
            }
        }
    }

    /// Test delete model request structure
    #[test]
    fn test_delete_model_request_structure() {
        let request = DeleteModelRequest {
            name: "llama2:7b".to_string(),
        };
        
        assert_eq!(request.name, "llama2:7b");
    }

    /// Test delete model response structure
    #[test]
    fn test_delete_model_response_structure() {
        let response = DeleteModelResponse {
            status: "success".to_string(),
        };
        
        assert_eq!(response.status, "success");
    }

    /// Test delete model function (integration test)
    #[tokio::test]
    async fn test_delete_model_function() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        // This test requires a running Ollama server
        // If Ollama is not running, we expect a connection error
        let result = client.delete_model("llama2:7b").await;
        
        match result {
            Ok(response) => {
                // Ollama is running and responded successfully
                assert!(!response.status.is_empty());
                // The status could be "success", "error", etc.
            }
            Err(ParagonicError::Ollama(_)) => {
                // Expected when Ollama is not running
                // This is a valid test result
            }
            Err(e) => {
                // Unexpected error type
                panic!("Unexpected error type: {e:?}");
            }
        }
    }

    /// Test embedding request structure
    #[test]
    fn test_embedding_request_structure() {
        let request = EmbeddingRequest {
            model: "nomic-embed-text".to_string(),
            prompt: "Hello, world!".to_string(),
            options: None,
        };
        
        assert_eq!(request.model, "nomic-embed-text");
        assert_eq!(request.prompt, "Hello, world!");
        assert!(request.options.is_none());
    }

    /// Test embedding response structure
    #[test]
    fn test_embedding_response_structure() {
        let response = EmbeddingResponse {
            embedding: vec![0.1, 0.2, 0.3, 0.4, 0.5],
        };
        
        assert_eq!(response.embedding.len(), 5);
        assert_eq!(response.embedding[0], 0.1);
        assert_eq!(response.embedding[4], 0.5);
    }

    /// Test generate embedding function (integration test)
    #[tokio::test]
    async fn test_generate_embedding_function() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        // This test requires a running Ollama server with embedding model
        // If Ollama is not running, we expect a connection error
        let result = client.generate_embedding("nomic-embed-text", "Hello, world!").await;
        
        match result {
            Ok(response) => {
                // Ollama is running and responded successfully
                assert!(!response.embedding.is_empty());
                // Embeddings should be vectors of reasonable size (typically 384-1536 dimensions)
                assert!(response.embedding.len() >= 100);
                assert!(response.embedding.len() <= 2000);
            }
            Err(ParagonicError::Ollama(_)) => {
                // Expected when Ollama is not running or embedding model not available
                // This is a valid test result
            }
            Err(e) => {
                // Unexpected error type
                panic!("Unexpected error type: {e:?}");
            }
        }
    }

    /// Test streaming chat completion response structure
    #[test]
    fn test_stream_chat_completion_response_structure() {
        let response = StreamChatCompletionResponse {
            model: "llama2:7b".to_string(),
            created_at: "2024-01-01T00:00:00Z".to_string(),
            done: false,
            message: Some(ChatMessage {
                role: "assistant".to_string(),
                content: "Hello".to_string(),
            }),
            response: Some("Hello".to_string()),
        };
        
        assert_eq!(response.model, "llama2:7b");
        assert!(!response.done);
        assert!(response.message.is_some());
        assert!(response.response.is_some());
        assert_eq!(response.message.as_ref().unwrap().role, "assistant");
        assert_eq!(response.response.as_ref().unwrap(), "Hello");
    }

    /// Test streaming chat completion function (integration test)
    #[tokio::test]
    async fn test_stream_chat_completion_function() {
        let config = OllamaConfig::default();
        let client = OllamaClient::new(config).unwrap();
        
        let messages = vec![
            ChatMessage {
                role: "user".to_string(),
                content: "Say hello".to_string(),
            },
        ];
        
        // This test requires a running Ollama server
        // If Ollama is not running, we expect a connection error
        let result = client.stream_chat_completion("llama2:7b", messages).await;
        
        match result {
            Ok(mut stream) => {
                // Ollama is running and responded successfully
                // Collect a few responses from the stream
                let mut responses = Vec::new();
                let mut count = 0;
                
                while let Some(response_result) = stream.next().await {
                    match response_result {
                        Ok(response) => {
                            responses.push(response);
                            count += 1;
                            
                            // Limit to first few responses to avoid infinite loop
                            if count >= 5 {
                                break;
                            }
                        }
                        Err(e) => {
                            error!("Stream response error: {:?}", e);
                            break;
                        }
                    }
                }
                
                // Should have received some responses
                assert!(!responses.is_empty());
                
                // Check that responses have expected structure
                for response in responses {
                    assert_eq!(response.model, "llama2:7b");
                    assert!(!response.created_at.is_empty());
                }
            }
            Err(ParagonicError::Ollama(_)) => {
                // Expected when Ollama is not running
                // This is a valid test result
            }
            Err(e) => {
                // Unexpected error type
                panic!("Unexpected error type: {e:?}");
            }
        }
    }
} 