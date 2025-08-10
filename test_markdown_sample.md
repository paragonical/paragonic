# Server-Side Markdown Formatting Test

This is a **comprehensive test document** to verify that the Paragonic server correctly formats markdown into *groff/nroff style* plain text.

## Headers and Structure

### Level 3 Header
#### Level 4 Header
##### Level 5 Header

## Text Formatting

**Bold text should be UPPERCASE and wrapped in asterisks**

*Italic text should be surrounded by forward slashes*

`Inline code should use special quotes`

## Lists

### Unordered Lists
- First bullet point item
- Second bullet point item  
- Third bullet point item

### Ordered Lists
1. First numbered item
2. Second numbered item
3. Third numbered item

## Code Blocks

```rust
fn main() {
    println!("Hello, world!");
    let x = 42;
    println!("The answer is {}", x);
}
```

```javascript
function greet(name) {
    console.log(`Hello, ${name}!`);
    return `Welcome, ${name}`;
}
```

## Blockquotes

> This is a blockquote that should be nicely formatted
> with proper indentation and visual indicators.

> Another blockquote to test multiple quote blocks.

## Links and References

Check out [Rust Documentation](https://doc.rust-lang.org/) for more information.

Visit [GitHub](https://github.com) to see the source code.

## Mixed Content

Here's a paragraph with **bold text**, *italic text*, and `inline code` all mixed together. This tests how the formatter handles multiple inline elements in a single line.

### Complex List with Formatting

1. **First item** with *emphasis* and `code`
2. Second item with [a link](https://example.com)
3. Third item with a nested concept:
   - Nested bullet point
   - Another nested item with **bold text**

## Edge Cases

This paragraph has **bold with *italic inside*** to test nested formatting.

Here's `code with **bold inside**` which should be handled carefully.

## Final Notes

This document tests all the major markdown elements that the server-side formatter should handle according to the groff/nroff style specification.
