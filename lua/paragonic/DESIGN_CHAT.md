# How Paragonic Agent Interation Works

- User starts a chat session with <leader>Pc
- The chat session opens a new vertical split window that is 1/3 the width of the screen.
- Instructions and a A tombstone is placed at the top of the chat window, the cursor is left
  on the line after the tombstone.
- The user types "hello world" and presses <ESC><CR>. 
- The client shows a zigzag on the next line followed by the model name. The request is 
  sent to the server.
- When this is a thinking model, the server returns a thinking_start message.
  The client shows a brain icon on the next line and indents and wraps the first
  thinking content, wrapped to the width of buffer.  Thinking content must be before any response content or the folding will not make any sense.
- When this is just a completion model, the server returns the response and 
- As the model returns thinking content, the client shows a vertical continuation icon 
  with the content wrapped to the width of the window.
- When the model returns a thinking_end message, a completed hourglass icon is shown.
- Now the client shows a lozenge icon and renders the post-thinking response. The 
  response is *NOT* indented. 
- The thinking content is now folded.

Example Converstation:
∎
hello world
↯ deepseek-r1:1.5b

🧠 <think>
⋮  Okay, so I just got this message from someone asking me
   "hello world." Hmm, that seems pretty straightforward.
   But wait, how do I respond? Let me think about this.

⋮  First off, when you see something like "hello world,"
   it's a common greeting in programming tutorials or coding
   platforms. It helps people recognize where my response
   should go. So maybe the assistant needs to acknowledge
   their message and offer help.

⋮  I remember that using step-by-step reasoning can make
   responses clearer. Even though this is a simple message,
   explaining my thought process might help them understand
   why I'm doing it that way. But in this case, since the
   answer is so basic, it might not be necessary unless
   they're learning or debugging something.

⋮  Wait, what exactly should the assistant do? They
   mentioned using tags like [your reasoning] to show the
   thinking process. So maybe after acknowledging their
   greeting, I can explain how my response was designed and
   what that purpose is in case they want more context later
   on.

⋮  I also need to keep it friendly but professional. Maybe
   start with a "Hello! How can I assist you today?" Then
   mention that this is a simple message and offer further
   help. That should make the conversation smooth and open
   for future interactions.
⌛ </think>

◊
Hello! It looks like your message came through as a
greeting. How can I assist you today?
∎


# Example 2

∎
create a guide to how to write LaTeX documents with Neovim
↯ deepseek-r1:1.5b

🧠 <think>
⋮  Okay, so I want to learn how to write LaTeX documents
   using Neovim. Hmm, I've heard of Neovim before; it's a
   command-line text editor that has some unique features
   compared to regular editors. But I'm not entirely sure how
   it works for LaTeX. Let me try to figure this out step by
   step.
⋮  First, I know that LaTeX is all about writing documents
   with commands and using the documentclass environment. So,
   I guess I need to set up a Neovim editor first. Maybe
   Neovim comes bundled with a template or some default
   settings. I should check if there's a default documentclass
   used in the editor.
⋮  Once I have my editor set up, how do I write a document?
   In LaTeX, the main file is usually something like
   latex/template.tex. I think Neovim can open that file and
   process it automatically, but maybe I need to write some
   commands manually. I'll probably need to learn basic Neovim
   commands for inserting text, creating sections, writing
   comments, formatting text, etc.
⋮  I'm not sure how to number the pages or include footers.
   I recall seeing something about using commands like
   \footnote{} and \pagebreak in LaTeX, but I'm not exactly
   sure where to place them. Maybe I should look up some
   examples of LaTeX files and see what's going on with page
   formatting there.
⋮  What about including graphics or images? Do I need to use
   the graphics package or include an image file directly? I
   think LaTeX can handle graphics if they're included via
   commands like \includegraphics{}, but I'm not certain.
   Maybe I should check how other people format their
   documents with images.
⋮  I also wonder if Neovim has any specific features for
   formatting text, like bolding or italicizing. The
   documentation might mention this. I'll need to look into
   how to use the appropriate commands for that. But maybe
   it's simpler to just type out the text directly into Neovim
   and then process it as a LaTeX document.
⋮  There are also some tricky parts, like handling
   multi-line equations or using packages. If I'm not familiar
   with certain packages, I might need to search online for
   examples or use the \usepackage{} command in my Neovim file
   to include necessary packages. This could be a bit
   time-consuming if I don't know where to look.
⋮  I also recall something about using comments and comments
   in LaTeX. How does that work? Do I just write // at the
   start of a line, and then when processing the document,
   Neovim interprets it as a comment? That seems useful for
   avoiding errors or adding placeholders.
⋮  Another thing is compiling the document properly. After
   writing all my commands in Neovim, how do I get the
   compiled output? Is there an automatic compile command, or
   do I need to run a separate tool? If Neovim handles
   everything itself, that would be convenient, but maybe it
   doesn't if I'm using certain packages.
⋮  I also think about version control. How can I keep track
   of changes and maintain collaboration with others? Maybe
   using a Git repository in the same directory as my LaTeX
   file could help, but I'm not sure how to set that up.
   Neovim might have some command-line utilities for managing
   files and directories automatically.
⋮  Lastly, maybe there are some limitations or gotchas when
   working with LaTeX in Neovim. For example, can I use
   certain commands directly without escaping? Or is there a
   specific order of operations or formatting that needs to be
   followed?
⋮  Overall, while Neovim seems like a powerful tool for text
   editing, integrating it effectively with LaTeX might
   require some learning and experimentation. I'll need to
   start by familiarizing myself with the Neovim editor's
   features, then gradually learn how to format my documents
   step by step.
⌛ </think>

◊
Creating a guide to writing LaTeX documents using Neovim
involves setting up your editor, understanding basic
commands, writing document structure, handling page
formatting, including graphics, and exploring advanced
features. Here's an organized guide:

### 1. **Setting Up Neovim**
- **Check for Defaults**: Ensure Neovim opens a typical
LaTeX template (latex/template.tex) by default.
- **Install Necessary Packages**: Use `guix -- install
latex` to include the `basku` package, which enhances
Neovim's features.
### 2. **Writing Basic LaTeX Documents**
- **Open Your Document**: Click `File > Open...` and
select your `.latex` file.
- **Insert Commands Manually**: Use Neovim commands for
text insertion, sections, comments, etc., even if the
documentclass is default.
### 3. **Structure Your Document**
- **Document Class**: Use `documentclass{article}` as a
default. You can change classes by modifying the
documentclass line.
- **Pages and Footers**: Adjust page numbering with
commands like `\pagebreak`. Include footers using
`\footnote{}`.
### 4. **Including Graphics and Images**
- **Include Graphic Packages**: Use
`\usepackage{graphicx}` or `includegraphics` if your
package lists graphic handling.
- **Direct Image Input**: Add images via
`includegraphics{image.jpg}` directly in the document.
### 5. **Handling Page-By-Page Compilation**
- **Run Neovim**: After writing, use `neovim -- compile`
to process the file and generate a PDF or other output.
### 6. **Advanced Formatting and Comments**
- **Commenting**: Use `//` at start of lines for
comments; Neovim processes them as LaTeX comments.
- **Formatting Text**: Use commands like `\texttt{}` for
bold text, or simply type it directly.
### 7. **Version Control and Collaboration**
- **Git Repository**: Create a Git repository in the same
directory using `git init myproject` to manage files and
directories automatically.
### 8. **Troubleshooting and Best Practices**
- **Check Neovim Settings**: Ensure page handling works
(press F5 for help).
- **Command Order**: Be cautious with certain commands;
use escaping if needed.
- **Collaboration Tools**: Use Git effectively for
sharing changes and collaboration.

By following these steps, you can effectively utilize
Neovim as a powerful text editor alongside LaTeX,
automating many tasks while allowing manual configuration
where necessary.

∎