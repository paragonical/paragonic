// TODO: Custom Markdown source formatter using comrak's AST
// Features to implement:
// - Headings with configurable spacing (H1: 4 lines before, H2: 3, H3: 2, others: 1)
// - Blockquotes
// - Numerical lists and ordinary lists (with nesting)
// - Fenced code blocks with language detection
// - Definition lists (Pandoc syntax)
// - Configurable indentation (default 3 spaces)

use comrak::nodes::{AstNode, NodeValue};
use comrak::{parse_document, Arena, ComrakOptions};
use serde::{Deserialize, Serialize};
use crate::error::{ParagonicError, ParagonicResult};

/// Configuration for Markdown source formatting
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MarkdownFormatConfig {
    /// Base indentation for nested elements (default: 3 spaces)
    pub base_indent: usize,
    /// Lines before H1 headers (default: 4)
    pub h1_spacing: usize,
    /// Lines before H2 headers (default: 3)
    pub h2_spacing: usize,
    /// Lines before H3 headers (default: 2)
    pub h3_spacing: usize,
    /// Lines before other headers (default: 1)
    pub other_header_spacing: usize,
    /// Whether to format code blocks with language-specific handling
    pub format_code_blocks: bool,
}

impl Default for MarkdownFormatConfig {
    fn default() -> Self {
        Self {
            base_indent: 3,
            h1_spacing: 4,
            h2_spacing: 3,
            h3_spacing: 2,
            other_header_spacing: 1,
            format_code_blocks: true,
        }
    }
}

/// Markdown source formatter using comrak's AST
pub struct MarkdownSourceFormatter {
    config: MarkdownFormatConfig,
}

impl MarkdownSourceFormatter {
    /// Create a new formatter with default configuration
    pub fn new() -> Self {
        Self {
            config: MarkdownFormatConfig::default(),
        }
    }

    /// Create a new formatter with custom configuration
    pub fn with_config(config: MarkdownFormatConfig) -> Self {
        Self { config }
    }

    /// Format markdown source using AST-based approach
    pub fn format_markdown_source(&self, input: &str) -> ParagonicResult<String> {
        let arena = Arena::new();
        let mut options = ComrakOptions::default();
        
        // Enable GitHub-flavored markdown extensions
        options.extension.strikethrough = true;
        options.extension.tagfilter = false;
        options.extension.table = true;
        options.extension.autolink = true;
        options.extension.tasklist = true;
        options.extension.superscript = true;
        options.extension.footnotes = true;
        options.extension.description_lists = true; // Pandoc-style definition lists

        let root = parse_document(&arena, input, &options);

        let mut formatter = AstFormatter::new(&self.config);
        formatter.format_node(root)?;
        
        Ok(formatter.finish())
    }
}

/// Internal AST formatter that walks the tree and builds formatted output
struct AstFormatter<'a> {
    config: &'a MarkdownFormatConfig,
    output: String,
    current_indent: usize,
    last_was_header: bool,
}

impl<'a> AstFormatter<'a> {
    fn new(config: &'a MarkdownFormatConfig) -> Self {
        Self {
            config,
            output: String::new(),
            current_indent: 0,
            last_was_header: false,
        }
    }

    fn format_node(&mut self, node: &'a AstNode<'a>) -> ParagonicResult<()> {
        match &node.data.borrow().value {
            NodeValue::Document => {
                // Process children
                for child in node.children() {
                    self.format_node(child)?;
                }
            }
            NodeValue::Heading(heading) => {
                self.format_heading(node, heading.level)?;
            }
            _ => {
                // TODO: Handle other node types
                // For now, just process children
                for child in node.children() {
                    self.format_node(child)?;
                }
            }
        }
        Ok(())
    }

    fn format_heading(&mut self, node: &'a AstNode<'a>, level: u8) -> ParagonicResult<()> {
        // Add spacing before header based on level
        let spacing = match level {
            1 => self.config.h1_spacing,
            2 => self.config.h2_spacing,
            3 => self.config.h3_spacing,
            _ => self.config.other_header_spacing,
        };

        // Add blank lines before header
        for _ in 0..spacing {
            self.output.push('\n');
        }

        // Add header prefix
        for _ in 0..level {
            self.output.push('#');
        }
        self.output.push(' ');

        // Add header text
        self.collect_text_content(node)?;
        self.output.push('\n');
        
        self.last_was_header = true;
        Ok(())
    }

    fn collect_text_content(&mut self, node: &'a AstNode<'a>) -> ParagonicResult<()> {
        match &node.data.borrow().value {
            NodeValue::Text(text) => {
                self.output.push_str(text);
            }
            _ => {
                // Process children to collect text
                for child in node.children() {
                    self.collect_text_content(child)?;
                }
            }
        }
        Ok(())
    }

    fn finish(self) -> String {
        // Return the output as-is, since we already add newlines in format_heading
        self.output
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_single_h1_header() {
        let formatter = MarkdownSourceFormatter::new();
        let input = "# Main Title";
        let result = formatter.format_markdown_source(input).unwrap();
        
        // Should have 4 blank lines before H1, then header, then final newline
        let expected = "\n\n\n\n# Main Title\n";
        assert_eq!(result, expected);
    }

    #[test]
    fn test_format_single_h2_header() {
        let formatter = MarkdownSourceFormatter::new();
        let input = "## Subtitle";
        let result = formatter.format_markdown_source(input).unwrap();
        
        // Should have 3 blank lines before H2
        let expected = "\n\n\n## Subtitle\n";
        assert_eq!(result, expected);
    }

    #[test]
    fn test_format_single_h3_header() {
        let formatter = MarkdownSourceFormatter::new();
        let input = "### Section";
        let result = formatter.format_markdown_source(input).unwrap();
        
        // Should have 2 blank lines before H3
        let expected = "\n\n### Section\n";
        assert_eq!(result, expected);
    }

    #[test]
    fn test_format_h4_and_below() {
        let formatter = MarkdownSourceFormatter::new();
        let input = "#### Subsection";
        let result = formatter.format_markdown_source(input).unwrap();
        
        // Should have 1 blank line before H4+
        let expected = "\n#### Subsection\n";
        assert_eq!(result, expected);
    }

    #[test]
    fn test_custom_header_spacing() {
        let config = MarkdownFormatConfig {
            h1_spacing: 2,
            h2_spacing: 1,
            h3_spacing: 1,
            other_header_spacing: 0,
            ..Default::default()
        };
        let formatter = MarkdownSourceFormatter::with_config(config);
        let input = "# Custom Title";
        let result = formatter.format_markdown_source(input).unwrap();
        
        // Should have 2 blank lines before H1 with custom config
        let expected = "\n\n# Custom Title\n";
        assert_eq!(result, expected);
    }
}
