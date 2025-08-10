// Using markdown crate for parsing and custom terminal formatting
use serde::{Deserialize, Serialize};
use crate::error::{ParagonicError, ParagonicResult};

/// Configuration for text formatting
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FormatConfig {
    /// Maximum width for text wrapping
    pub max_width: usize,
    /// Indentation for continuation lines (in spaces)
    pub continuation_indent: usize,
    /// Whether to format markdown as nice plain text (like groff/nroff)
    pub format_markdown: bool,
    /// Whether to preserve paragraph breaks
    pub preserve_paragraphs: bool,
    /// Whether to add extra spacing around structural elements (headers, code blocks, lists)
    pub enhanced_structural_spacing: bool,
}

impl Default for FormatConfig {
    fn default() -> Self {
        Self {
            max_width: 80,
            continuation_indent: 3,
            format_markdown: true,
            preserve_paragraphs: true,
            enhanced_structural_spacing: true,
        }
    }
}

/// Text formatter for Neovim responses
pub struct TextFormatter {
    config: FormatConfig,
}

impl TextFormatter {
    /// Create a new text formatter with default configuration
    pub fn new() -> Self {
        Self {
            config: FormatConfig::default(),
        }
    }

    /// Create a new text formatter with custom configuration
    pub fn with_config(config: FormatConfig) -> Self {
        Self { config }
    }



    /// Format markdown source for specified line width with basic formatting
    pub fn format_markdown(&self, text: &str) -> ParagonicResult<String> {
        // Calculate target line width: 65% of max_width - 3 characters
        let target_width = ((self.config.max_width as f64 * 0.65) as usize).saturating_sub(3);
        
        let mut result = String::new();
        let lines: Vec<&str> = text.lines().collect();
        
        for (i, line) in lines.iter().enumerate() {
            let trimmed = line.trim();
            if trimmed.is_empty() {
                result.push_str("\n");
                continue;
            }
            
            // Handle different markdown elements
            if trimmed.starts_with('#') {
                // Headers - keep as-is but ensure proper spacing
                result.push_str(trimmed);
                result.push_str("\n\n");
            } else if trimmed.starts_with('>') {
                // Blockquotes - keep as-is
                result.push_str(trimmed);
                result.push_str("\n");
            } else if trimmed.starts_with('-') || trimmed.starts_with('*') {
                // Unordered lists - keep as-is
                result.push_str(trimmed);
                result.push_str("\n");
            } else if let Some(_) = trimmed.chars().next().and_then(|c| c.to_digit(10)) {
                // Check if this looks like a numbered list item (number followed by .)
                if trimmed.contains('.') && trimmed.chars().nth(1) == Some('.') {
                    // Numbered lists - keep as-is
                    result.push_str(trimmed);
                    result.push_str("\n");
                } else {
                    // Regular text - word wrap
                    let wrapped = self.word_wrap_to_width(trimmed, target_width)?;
                    result.push_str(&wrapped);
                    result.push_str("\n");
                }
            } else if trimmed.starts_with("```") {
                // Code blocks - keep as-is
                result.push_str(trimmed);
                result.push_str("\n");
            } else {
                // Regular text - word wrap
                let wrapped = self.word_wrap_to_width(trimmed, target_width)?;
                result.push_str(&wrapped);
                result.push_str("\n");
            }
        }
        
        Ok(result.trim().to_string())
    }
    


    /// Convert HTML to plain text
    fn html_to_plain_text(&self, html: &str) -> ParagonicResult<String> {
        // Simple HTML to plain text conversion
        // This is a basic implementation - for production, consider using a proper HTML parser
        
        let mut text = html.to_string();
        
        // Remove HTML tags
        text = regex::Regex::new(r"<[^>]*>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&text, "")
            .to_string();
        
        // Decode common HTML entities
        text = text.replace("&amp;", "&");
        text = text.replace("&lt;", "<");
        text = text.replace("&gt;", ">");
        text = text.replace("&quot;", "\"");
        text = text.replace("&#39;", "'");
        text = text.replace("&nbsp;", " ");
        
        // Normalize whitespace
        text = regex::Regex::new(r"\s+")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&text, " ")
            .to_string();
        
        // Trim leading/trailing whitespace
        text = text.trim().to_string();
        
        Ok(text)
    }

    /// Split text into paragraphs
    fn split_paragraphs(&self, text: &str) -> Vec<String> {
        text.split("\n\n")
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
            .collect()
    }

    /// Word wrap text to fit within max_width
    fn word_wrap(&self, text: &str) -> ParagonicResult<Vec<String>> {
        if text.is_empty() {
            return Ok(vec![]);
        }

        let words: Vec<&str> = text.split_whitespace().collect();
        if words.is_empty() {
            return Ok(vec![]);
        }

        let mut lines = Vec::new();
        let mut current_line = String::new();
        let mut current_length = 0;

        for word in words {
            let word_length = word.len();
            
            // If adding this word would exceed the line limit
            if current_length + word_length + 1 > self.config.max_width && !current_line.is_empty() {
                lines.push(current_line.trim().to_string());
                current_line = word.to_string();
                current_length = word_length;
            } else {
                if !current_line.is_empty() {
                    current_line.push(' ');
                    current_length += 1;
                }
                current_line.push_str(word);
                current_length += word_length;
            }
        }

        // Add the last line if it has content
        if !current_line.is_empty() {
            lines.push(current_line.trim().to_string());
        }

        Ok(lines)
    }

    /// Word wrap text to a specific width and return as a single string
    fn word_wrap_to_width(&self, text: &str, width: usize) -> ParagonicResult<String> {
        if text.is_empty() {
            return Ok(String::new());
        }

        let words: Vec<&str> = text.split_whitespace().collect();
        if words.is_empty() {
            return Ok(String::new());
        }

        let mut result = String::new();
        let mut current_line = String::new();
        let mut current_length = 0;

        for word in words {
            let word_length = word.len();
            
            // If adding this word would exceed the line limit
            if current_length + word_length + 1 > width && !current_line.is_empty() {
                result.push_str(&current_line.trim());
                result.push('\n');
                current_line = word.to_string();
                current_length = word_length;
            } else {
                if !current_line.is_empty() {
                    current_line.push(' ');
                    current_length += 1;
                }
                current_line.push_str(word);
                current_length += word_length;
            }
        }

        // Add the last line if it has content
        if !current_line.is_empty() {
            result.push_str(&current_line.trim());
        }

        Ok(result)
    }

    /// Format text with timing information
    pub fn format_with_timing(&self, text: &str, duration_sec: f64) -> ParagonicResult<String> {
        let mut formatted = if self.config.format_markdown {
            self.format_markdown(text)?
        } else {
            text.to_string()
        };
        
        // Add timing information
        formatted.push_str("\n");
        formatted.push_str(&format!(" ⏱️   {:.2}s", duration_sec));
        formatted.push_str("\n");
        formatted.push_str("\n");
        formatted.push_str("∎");
        
        Ok(formatted)
    }

    /// Update configuration
    pub fn update_config(&mut self, config: FormatConfig) {
        self.config = config;
    }

    /// Get current configuration
    pub fn get_config(&self) -> &FormatConfig {
        &self.config
    }

    /// Check if markdown formatting is enabled
    pub fn is_markdown_enabled(&self) -> bool {
        self.config.format_markdown
    }
}

impl Default for TextFormatter {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_text_formatter_creation() {
        let formatter = TextFormatter::new();
        assert_eq!(formatter.config.max_width, 80);
        assert_eq!(formatter.config.continuation_indent, 3);
    }

    #[test]
    fn test_text_formatter_with_config() {
        let config = FormatConfig {
            max_width: 60,
            continuation_indent: 2,
            format_markdown: false,
            preserve_paragraphs: false,
            enhanced_structural_spacing: false,
        };
        
        let formatter = TextFormatter::with_config(config);
        assert_eq!(formatter.config.max_width, 60);
        assert_eq!(formatter.config.continuation_indent, 2);
        assert!(!formatter.config.enhanced_structural_spacing);
    }

    #[test]
    fn test_word_wrap() {
        let formatter = TextFormatter::new();
        let text = "This is a long sentence that should be wrapped to fit within the maximum width limit.";
        let wrapped = formatter.word_wrap(text).unwrap();
        
        assert!(!wrapped.is_empty());
        for line in &wrapped {
            assert!(line.len() <= formatter.config.max_width);
        }
    }



    #[test]
    fn test_format_markdown() {
        let mut formatter = TextFormatter::new();
        // Set a small max_width for testing
        formatter.config.max_width = 30;
        
        let markdown_text = r#"# Header

This is a long paragraph that should be wrapped to fit within the specified line width.

- List item 1
- List item 2

> Blockquote text

1. Numbered item 1
2. Numbered item 2

```rust
fn main() {
    println!("code block");
}
```"#;
        
        let formatted = formatter.format_markdown(markdown_text).unwrap();
        
        // Debug: print the formatted output
        println!("Formatted output:\n{}", formatted);
        
        // Should preserve markdown structure
        assert!(formatted.contains("# Header"));  // Headers preserved
        assert!(formatted.contains("- List item 1")); // Lists preserved
        assert!(formatted.contains("> Blockquote text")); // Blockquotes preserved
        assert!(formatted.contains("1. Numbered item 1")); // Numbered lists preserved
        assert!(formatted.contains("```rust")); // Code blocks preserved
        assert!(formatted.contains("fn main()")); // Code content preserved
        
        // Should wrap long lines
        let lines: Vec<&str> = formatted.lines().collect();
        for line in &lines {
            if !line.starts_with('#') && !line.starts_with('-') && !line.starts_with('>') && 
               !line.starts_with('1') && !line.starts_with('2') && !line.starts_with('`') {
                // Regular text lines should be wrapped
                assert!(line.len() <= 30, "Line '{}' exceeds max width of 30", line);
            }
        }
    }





    #[test]
    fn test_format_with_timing() {
        let formatter = TextFormatter::new();
        let text = "Test message";
        let formatted = formatter.format_with_timing(text, 1.23).unwrap();
        
        assert!(formatted.contains("⏱️   1.23s"));
        assert!(formatted.ends_with("∎"));
    }

    #[test]
    fn test_split_paragraphs() {
        let formatter = TextFormatter::new();
        let text = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph.";
        let paragraphs = formatter.split_paragraphs(text);
        
        assert_eq!(paragraphs.len(), 3);
        assert!(paragraphs[0].contains("First paragraph"));
        assert!(paragraphs[1].contains("Second paragraph"));
        assert!(paragraphs[2].contains("Third paragraph"));
    }

    #[test]
    fn test_html_to_plain_text() {
        let formatter = TextFormatter::new();
        let html = "<p>This is <strong>bold</strong> and <em>italic</em> text.</p>";
        let plain = formatter.html_to_plain_text(html).unwrap();
        
        assert!(!plain.contains("<"));
        assert!(!plain.contains(">"));
        assert!(plain.contains("bold"));
        assert!(plain.contains("italic"));
    }
}
