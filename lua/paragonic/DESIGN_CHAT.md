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
  thinking content, wrapped to the width of buffer.  
- As the model returns thinking content, the client shows a vertical continuation icon 
  with the content wrapped to the width of the window.
- When the model returns a thinking_end message, a completed hourglass icon is shown.
- Now the client shows a lozenge icon and renders the post-thinking response.
- The thinking content is now folded.
