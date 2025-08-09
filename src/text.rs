// Note: comrak is available if needed for more complex markdown processing
use serde::{Deserialize, Serialize};
use crate::error::{ParagonicError, ParagonicResult};

/// Configuration for text formatting
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FormatConfig {
    /// Maximum width for text wrapping
    pub max_width: usize,
    /// Whether to include diamond prefix (🮮) on first line
    pub include_diamond: bool,
    /// Indentation for continuation lines (in spaces)
    pub continuation_indent: usize,
    /// Whether to format markdown as nice plain text (like groff/nroff)
    pub format_markdown: bool,
    /// Whether to preserve paragraph breaks
    pub preserve_paragraphs: bool,
}

impl Default for FormatConfig {
    fn default() -> Self {
        Self {
            max_width: 80,
            include_diamond: true,
            continuation_indent: 3,
            format_markdown: true,
            preserve_paragraphs: true,
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

    /// Format text for Neovim display with diamond prefix and indentation
    pub fn format_for_neovim(&self, text: &str) -> ParagonicResult<String> {
        // First, format markdown if configured
        let formatted_text = if self.config.format_markdown {
            self.format_markdown(text)?
        } else {
            text.to_string()
        };

        // Split into paragraphs
        let paragraphs = if self.config.preserve_paragraphs {
            self.split_paragraphs(&formatted_text)
        } else {
            vec![formatted_text]
        };

        let mut formatted_lines = Vec::new();

        for (para_idx, paragraph) in paragraphs.iter().enumerate() {
            if paragraph.trim().is_empty() {
                formatted_lines.push("".to_string());
                continue;
            }

            // Word wrap the paragraph
            let wrapped_lines = self.word_wrap(paragraph)?;

            // Apply formatting to each line
            for (line_idx, line) in wrapped_lines.iter().enumerate() {
                let formatted_line = if para_idx == 0 && line_idx == 0 && self.config.include_diamond {
                    // First line of first paragraph gets diamond prefix
                    format!("🮮  {}", line)
                } else {
                    // Other lines get continuation indentation
                    format!("{}{}", " ".repeat(self.config.continuation_indent), line)
                };
                formatted_lines.push(formatted_line);
            }

            // Add blank line between paragraphs (except after the last one)
            if para_idx < paragraphs.len() - 1 && self.config.preserve_paragraphs {
                formatted_lines.push("".to_string());
            }
        }

        Ok(formatted_lines.join("\n"))
    }

    /// Format markdown as nicely formatted plain text (like groff/nroff)
    fn format_markdown(&self, text: &str) -> ParagonicResult<String> {
        let mut result = String::new();
        let lines: Vec<&str> = text.lines().collect();
        let mut i = 0;
        
        while i < lines.len() {
            let line = lines[i].trim();
            
            // Skip empty lines but preserve them
            if line.is_empty() {
                result.push('\n');
                i += 1;
                continue;
            }
            
            // Headers - convert to bold uppercase with underlines
            if let Some(caps) = regex::Regex::new(r"^(#{1,6})\s*(.*)$")
                .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
                .captures(line) {
                let level = caps.get(1).unwrap().as_str().len();
                let title = caps.get(2).unwrap().as_str().to_uppercase();
                
                result.push('\n');
                result.push_str(&title);
                result.push('\n');
                
                // Add underline for headers
                match level {
                    1 => result.push_str(&"=".repeat(title.len())),
                    2 => result.push_str(&"-".repeat(title.len())),
                    _ => result.push_str(&"⋅".repeat(title.len())),
                }
                result.push('\n');
                result.push('\n');
            }
            // Code blocks - preserve with indentation
            else if line.starts_with("```") {
                i += 1; // Skip opening ```
                result.push_str("    CODE:\n");
                while i < lines.len() && !lines[i].trim().starts_with("```") {
                    result.push_str("    │ ");
                    result.push_str(lines[i]);
                    result.push('\n');
                    i += 1;
                }
                result.push('\n');
            }
            // Blockquotes - indent with nice prefix
            else if line.starts_with('>') {
                let quote_text = line.strip_prefix('>').unwrap_or(line).trim();
                result.push_str("    ❝ ");
                result.push_str(quote_text);
                result.push('\n');
            }
            // Lists - format with nice bullets
            else if let Some(caps) = regex::Regex::new(r"^[\s]*[-*+]\s+(.*)$")
                .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
                .captures(line) {
                let item = caps.get(1).unwrap().as_str();
                result.push_str("  • ");
                result.push_str(item);
                result.push('\n');
            }
            // Numbered lists
            else if let Some(caps) = regex::Regex::new(r"^[\s]*(\d+)\.\s+(.*)$")
                .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
                .captures(line) {
                let number = caps.get(1).unwrap().as_str();
                let item = caps.get(2).unwrap().as_str();
                result.push_str(&format!("  {}. ", number));
                result.push_str(item);
                result.push('\n');
            }
            // Regular text - format inline elements
            else {
                let formatted_line = self.format_inline_markdown(line)?;
                result.push_str(&formatted_line);
                result.push('\n');
            }
            
            i += 1;
        }
        
        Ok(result.trim().to_string())
    }
    
    /// Format inline markdown elements (bold, italic, code, links)
    fn format_inline_markdown(&self, text: &str) -> ParagonicResult<String> {
        let mut result = text.to_string();
        
        // Use placeholders to avoid conflicts between bold and italic
        
        // 1. Links first [text](url) - show both text and URL
        result = regex::Regex::new(r"\[([^\]]+)\]\(([^)]+)\)")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "$1 ⟨$2⟩")
            .to_string();
        
        // 2. Inline code (`code`) - use different quotes
        result = regex::Regex::new(r"`([^`]+)`")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "‹$1›")
            .to_string();
        
        // 3. Bold text first - replace with placeholder to avoid conflicts
        let mut bold_placeholders = Vec::new();
        
        // Process **bold** 
        let bold_re = regex::Regex::new(r"\*\*([^*]+)\*\*")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?;
        result = bold_re.replace_all(&result, |caps: &regex::Captures| {
            let content = caps[1].to_uppercase();
            let formatted = format!("**{}**", content);
            let placeholder = format!("§§§BOLD〈{}〉§§§", bold_placeholders.len());
            bold_placeholders.push(formatted);
            placeholder
        }).to_string();
        
        // Process __bold__
        let bold_underscore_re = regex::Regex::new(r"__([^_]+)__")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?;
        result = bold_underscore_re.replace_all(&result, |caps: &regex::Captures| {
            let content = caps[1].to_uppercase();
            let formatted = format!("**{}**", content);
            let placeholder = format!("§§§BOLD〈{}〉§§§", bold_placeholders.len());
            bold_placeholders.push(formatted);
            placeholder
        }).to_string();
        
        // 4. Now process italic safely (no more ** or __ to conflict with)
        result = regex::Regex::new(r"\*([^*]+)\*")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "/$1/")
            .to_string();
        result = regex::Regex::new(r"_([^_]+)_")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "/$1/")
            .to_string();
        
        // 5. Restore bold placeholders
        for (i, bold_text) in bold_placeholders.iter().enumerate() {
            let placeholder = format!("§§§BOLD〈{}〉§§§", i);
            result = result.replace(&placeholder, bold_text);
        }
        
        Ok(result)
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

    /// Format text with timing information
    pub fn format_with_timing(&self, text: &str, duration_sec: f64) -> ParagonicResult<String> {
        let mut formatted = self.format_for_neovim(text)?;
        
        // Add timing information
        formatted.push_str("\n");
        formatted.push_str(&format!("   ⏱️  {:.2}s", duration_sec));
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
        assert!(formatter.config.include_diamond);
        assert_eq!(formatter.config.continuation_indent, 3);
    }

    #[test]
    fn test_text_formatter_with_config() {
        let config = FormatConfig {
            max_width: 60,
            include_diamond: false,
            continuation_indent: 2,
            format_markdown: false,
            preserve_paragraphs: false,
        };
        
        let formatter = TextFormatter::with_config(config);
        assert_eq!(formatter.config.max_width, 60);
        assert!(!formatter.config.include_diamond);
        assert_eq!(formatter.config.continuation_indent, 2);
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
    fn test_format_for_neovim_with_diamond() {
        let formatter = TextFormatter::new();
        let text = "This is a test message that should be formatted with a diamond prefix and should wrap to multiple lines to test continuation indentation.";
        let formatted = formatter.format_for_neovim(text).unwrap();
        
        assert!(formatted.starts_with("🮮  "));
        // Check that there are lines with continuation indentation
        let lines: Vec<&str> = formatted.split('\n').collect();
        assert!(lines.len() > 1, "Text should wrap to multiple lines");
        
        // Check that continuation lines start with three spaces
        let continuation_lines: Vec<&str> = lines.iter().skip(1).filter(|line| !line.is_empty()).cloned().collect();
        if !continuation_lines.is_empty() {
            assert!(continuation_lines[0].starts_with("   "), "Continuation lines should start with three spaces");
        }
    }

    #[test]
    fn test_format_markdown() {
        let formatter = TextFormatter::new();
        let markdown_text = r#"# Header
        
**Bold text** and *italic text* and `inline code`.

- List item 1
- List item 2

> Blockquote text

[Link text](https://example.com)

```rust
fn main() {
    println!("code block");
}
```"#;
        
        let formatted = formatter.format_markdown(markdown_text).unwrap();
        
        // Debug: print the formatted output
        println!("Formatted output:\n{}", formatted);
        
        // Should format markdown nicely, not remove it
        assert!(formatted.contains("HEADER"));  // Headers become uppercase
        assert!(formatted.contains("===="));    // With underlines
        assert!(formatted.contains("**BOLD TEXT**")); // Bold becomes uppercase
        assert!(formatted.contains("/italic text/")); // Italic gets slashes
        assert!(formatted.contains("‹inline code›")); // Code gets angle quotes
        assert!(formatted.contains("  • List item 1")); // Lists get bullets
        assert!(formatted.contains("    ❝ Blockquote text")); // Blockquotes get quotes
        assert!(formatted.contains("Link text ⟨https://example.com⟩")); // Links show URL
        assert!(formatted.contains("    CODE:")); // Code blocks labeled
        assert!(formatted.contains("    │ fn main()")); // Code indented with pipe
    }

    #[test]
    fn test_format_for_neovim_without_diamond() {
        let mut formatter = TextFormatter::new();
        formatter.config.include_diamond = false;
        
        let text = "This is a test message without diamond prefix.";
        let formatted = formatter.format_for_neovim(text).unwrap();
        
        assert!(!formatted.starts_with("🮮  "));
        assert!(formatted.starts_with("   ")); // should start with indentation
    }



    #[test]
    fn test_format_with_timing() {
        let formatter = TextFormatter::new();
        let text = "Test message";
        let formatted = formatter.format_with_timing(text, 1.23).unwrap();
        
        assert!(formatted.contains("⏱️  1.23s"));
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
