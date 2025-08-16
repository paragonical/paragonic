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
- Now the client shows a lozenge icon and renders the post-thinking response.
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

◊  Hello! It looks like your message came through as a
   greeting. How can I assist you today?
∎