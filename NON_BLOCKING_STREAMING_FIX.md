# Non-Blocking Streaming Fix

## Problem
The thinking streaming implementation in the Neovim client was blocking the UI during streaming requests, preventing users from doing any work while streaming was in progress. Additionally, when users switched to different buffers during streaming, the client would crash with "Cursor position outside buffer" errors. Debug notifications were also creating noise during normal operation.

## Root Cause
The issue was caused by blocking `vim.wait()` calls in two streaming functions:

1. **`send_message_thinking_streaming`** (line 1225): `vim.wait(wait_interval * 1000)` - Blocked while waiting for streaming chunks
2. **`send_message_streaming`** (line 1133): `vim.wait(wait_interval * 1000)` - Blocked while waiting for streaming chunks
3. **Chunk processing delay** (line 1259): `vim.wait(50)` - Blocked between processing chunks

**Window Safety Issues:**
4. **Cursor position error**: `vim.api.nvim_win_set_cursor(0, ...)` used current window instead of stored window ID
5. **Buffer width error**: `vim.api.nvim_win_get_width(0)` used current window during streaming

**Debug Notification Issues:**
6. **Excessive noise**: Debug notifications were showing during normal operation
7. **No configuration**: No way to disable debug notifications while keeping debug buffer functionality

## Solution
Replaced the blocking polling approach with a non-blocking asynchronous implementation using:

- **`vim.loop.new_timer()`** - For non-blocking chunk checking
- **`vim.defer_fn()`** - For scheduling chunk processing with delays
- **Timer-based polling** - Instead of blocking `vim.wait()` calls
- **Window ID storage** - Store window ID at start to avoid current window issues
- **Window validation** - Check if stored window still exists before using it
- **Debug notification configuration** - Allow disabling notifications while keeping debug buffer

## Changes Made

### 1. `send_message_thinking_streaming` function
- Replaced blocking `while` loop with timer-based chunk checking
- Used `vim.loop.new_timer()` for non-blocking polling
- Implemented recursive `process_chunk_async()` function for smooth chunk processing
- Added proper timer cleanup on completion or timeout
- **Window safety**: Store window ID and validate before use

### 2. `send_message_streaming` function  
- Applied the same non-blocking pattern
- Replaced blocking `vim.wait()` with timer-based approach
- Maintained the same functionality while being non-blocking

### 3. Window Safety Fixes
- **Store window ID**: `local chat_window_id = vim.api.nvim_get_current_win()` at start
- **Validate window**: Check `vim.api.nvim_win_is_valid(chat_window_id)` before use
- **Safe cursor setting**: Use stored window ID instead of current window (0)
- **Safe width getting**: Use stored window ID for buffer width calculations
- **Fallback values**: Provide default width (80) if window is invalid

### 4. Debug Notification Configuration
- **Configuration system**: Added `debug_config` with `show_notifications` setting
- **Disable by default**: Debug notifications are disabled by default in chat module
- **Toggle function**: `M.toggle_debug_notifications()` to enable/disable notifications
- **Configuration functions**: `debug.configure_debug()`, `debug.disable_notifications()`, `debug.enable_notifications()`
- **Debug buffer preserved**: All debug messages still go to debug buffer regardless of notification setting

### 5. Test Implementation
- Created `test_non_blocking_streaming.lua` to verify the fix
- Created `test_window_safety.lua` to verify window safety
- Created `test_debug_notifications.lua` to verify debug notification configuration
- Tests confirm functions return immediately (0ms) instead of blocking
- Uses mocked backend to avoid actual network calls during testing

## Benefits
- ✅ **Non-blocking UI**: Users can continue working while streaming
- ✅ **Smooth streaming**: Chunks are still processed with appropriate delays
- ✅ **Proper cleanup**: Timers are properly stopped and closed
- ✅ **Timeout handling**: Graceful timeout after 30 seconds
- ✅ **Backward compatibility**: Same API, different implementation
- ✅ **Window safety**: No crashes when switching buffers during streaming
- ✅ **Robust error handling**: Graceful fallbacks when windows become invalid
- ✅ **Reduced noise**: Debug notifications disabled by default
- ✅ **Configurable debugging**: Users can enable notifications when needed for troubleshooting

## Technical Details
- **Polling interval**: 100ms (reduced from 100ms wait)
- **Chunk processing delay**: 50ms between chunks (using `vim.defer_fn`)
- **Timeout**: 30 seconds maximum wait time
- **Memory management**: Proper timer cleanup prevents memory leaks
- **Window validation**: `vim.api.nvim_win_is_valid()` checks before window operations
- **Default width**: 80 characters when window is unavailable
- **Debug configuration**: Centralized configuration system for debug settings

## Usage

### Debug Notifications
Debug notifications are disabled by default to reduce noise. To enable them for troubleshooting:

```lua
-- Enable debug notifications
local debug = require("paragonic.debug")
debug.enable_notifications()

-- Or use the toggle function
local chat = require("paragonic.chat")
chat.toggle_debug_notifications()
```

### Debug Buffer
Debug messages are always written to the debug buffer regardless of notification settings:

```lua
-- Open debug buffer to see all debug messages
local debug = require("paragonic.debug")
debug.open_debug_buffer()
```

## Testing
The fix has been verified with unit tests that confirm:
- Functions return immediately (non-blocking)
- No UI blocking during streaming operations
- Proper error handling when backend is unavailable
- No crashes when windows become invalid during streaming
- Graceful handling of buffer switches during streaming
- Debug notification configuration works correctly
- Debug buffer functionality is preserved when notifications are disabled
