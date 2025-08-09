// Using markdown crate for parsing and custom terminal formatting
use serde::{Deserialize, Serialize};
use crate::error::{ParagonicError, ParagonicResult};
use regex::Regex;

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

    /// Format markdown using simple HTML conversion and regex for terminal output
    fn format_markdown(&self, text: &str) -> ParagonicResult<String> {
        // Convert markdown to HTML using the markdown crate
        let html = markdown::to_html(text);
        

        
        // Convert HTML to our custom terminal format using regex
        let mut result = html;
        
        // Headers: <h1>Text</h1> -> TEXT\n==== (with proper underlines)
        for level in 1..=6 {
            let pattern = format!(r"<h{level}>(.*?)</h{level}>", level = level);
            let regex = regex::Regex::new(&pattern)
                .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?;
            
            result = regex.replace_all(&result, |caps: &regex::Captures| {
                let text = caps.get(1).unwrap().as_str().to_uppercase();
                let underline_char = match level {
                    1 => "=",
                    2 => "-",
                    _ => "⋅",
                };
                let underline = underline_char.repeat(text.len());
                format!("\n{}\n{}\n", text, underline)
            }).to_string();
        }
        
        // Bold: <strong>text</strong> -> **TEXT**
        result = regex::Regex::new(r"<strong>(.*?)</strong>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, |caps: &regex::Captures| {
                let text = caps.get(1).unwrap().as_str().to_uppercase();
                format!("**{}**", text)
            }).to_string();
            
        // Italic: <em>text</em> -> /text/
        result = regex::Regex::new(r"<em>(.*?)</em>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "/$1/").to_string();
            
        // Inline code: <code>text</code> -> ‹text›
        result = regex::Regex::new(r"<code>(.*?)</code>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "‹$1›").to_string();
            
        // Links: <a href="url">text</a> -> text ⟨url⟩
        result = regex::Regex::new(r#"<a href="([^"]*)"[^>]*>(.*?)</a>"#)
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "$2 ⟨$1⟩").to_string();
            
        // Lists: <ul><li>item</li></ul> -> • item
        result = regex::Regex::new(r"<ul[^>]*>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "\n").to_string();
        result = regex::Regex::new(r"</ul>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "").to_string();
        result = regex::Regex::new(r"<li[^>]*>(.*?)</li>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "  • $1\n").to_string();
            
        // Blockquotes: handle nested <p> tags properly
        result = regex::Regex::new(r"<blockquote[^>]*>(.*?)</blockquote>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, |caps: &regex::Captures| {
                let content = caps.get(1).unwrap().as_str();
                // Remove <p> tags from the blockquote content
                let cleaned = regex::Regex::new(r"</?p[^>]*>").unwrap()
                    .replace_all(content, "").trim().to_string();
                format!("    ❝ {}\n", cleaned)
            }).to_string();
            
        // Code blocks: <pre><code>code</code></pre> -> CODE BLOCK with pipe separators
        result = regex::Regex::new(r"<pre[^>]*><code[^>]*>(.*?)</code></pre>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, |caps: &regex::Captures| {
                let code = caps.get(1).unwrap().as_str();
                let lines: Vec<&str> = code.lines().collect();
                let mut formatted = String::from("\n    CODE BLOCK\n");
                for line in lines {
                    formatted.push_str(&format!("    │ {}\n", line));
                }
                formatted
            }).to_string();
            
        // Remove paragraphs: <p>text</p> -> text (with proper spacing)
        result = regex::Regex::new(r"<p[^>]*>(.*?)</p>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "$1\n\n").to_string();
            
        // Clean up HTML entities and remaining tags
        result = result.replace("&lt;", "<")
                     .replace("&gt;", ">")
                     .replace("&amp;", "&")
                     .replace("&quot;", "\"")
                     .replace("&#39;", "'");
                     
        // Remove any remaining HTML tags
        result = regex::Regex::new(r"<[^>]*>")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "").to_string();
            
        // Clean up excessive whitespace
        result = regex::Regex::new(r"\n{3,}")
            .map_err(|e| ParagonicError::InvalidInput(format!("Invalid regex: {}", e)))?
            .replace_all(&result, "\n\n").to_string();
            
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
        assert!(formatted.contains("Blockquote text")); // Blockquote content appears
        assert!(formatted.contains("Link text ⟨https://example.com⟩")); // Links show URL
        assert!(formatted.contains("fn main()")); // Code blocks are clean
        assert!(formatted.contains("println!(\"code block\")")); // Code content included
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
