# Thinking Callback Test Plan

## Problem Statement
The thinking callback functionality is not working correctly. The `on_chunk` callback defined in `send_message_command_thinking` is not being called, resulting in no "CALLBACK:" notifications appearing in the debug output.

## Automated Testing Strategy

### 1. Quick Diagnostic Tests
Run these tests first to identify the root cause:

```bash
# Quick diagnostic (30 seconds)
./test_thinking_callback.sh quick

# Or from within Neovim
:ParagonicTestThinkingCallback
```

**Tests included:**
- ✅ Function availability check
- ✅ Model detection verification
- ✅ Notification system test
- ✅ Keymap setup verification

### 2. Full Test Suite
Run comprehensive tests to verify all components:

```bash
# Full test suite (2-3 minutes)
./test_thinking_callback.sh full

# Or from within Neovim
:ParagonicTestThinkingCallbackFull
```

**Tests included:**
- ✅ Keymap setup verification
- ✅ Model detection
- ✅ Function registration
- ✅ Callback creation and execution
- ✅ Function call chain
- ✅ Notification system
- ✅ Debug module integration
- ✅ Command execution simulation
- ✅ Keymap simulation
- ✅ Thinking callback integration

### 3. Manual Testing Steps
If automated tests pass, verify manually:

1. **Open chat buffer:**
   ```vim
   :ParagonicChat
   ```

2. **Add test message:**
   ```
   ∎
   hello world
   ```

3. **Press `<CR>` and check debug output for:**
   - "TEST: send_message_command_smart called"
   - "TEST: on_chunk callback type"
   - "CALLBACK: Processing chunk"

## Expected Results

### ✅ Success Indicators
- All automated tests pass
- Test notifications appear in debug output
- "CALLBACK:" notifications appear when chunks are processed
- Thinking content is displayed with proper formatting

### ❌ Failure Indicators
- Automated tests fail with specific error messages
- Test notifications don't appear
- "CALLBACK:" notifications are missing
- Wrong function is being called

## Troubleshooting Guide

### Issue: Keymap not working
**Symptoms:** `send_message_command_legacy` called instead of `send_message_command_smart`
**Solution:** Check keymap setup in chat buffer creation

### Issue: Model detection failing
**Symptoms:** Thinking model not detected, falls back to normal streaming
**Solution:** Verify model configuration in `config.lua`

### Issue: Callback not being called
**Symptoms:** "CALLBACK:" notifications missing
**Solution:** Check `on_chunk` callback definition and passing

### Issue: Function not registered
**Symptoms:** "function not found" errors
**Solution:** Check function registration in `init.lua`

## Rapid Iteration Workflow

1. **Make a change** to the code
2. **Run quick diagnostic:** `./test_thinking_callback.sh quick`
3. **If issues found:** Fix and repeat step 2
4. **If quick test passes:** Run full suite: `./test_thinking_callback.sh full`
5. **If full suite passes:** Test manually in Neovim
6. **If manual test passes:** Issue resolved!

## Test Output Interpretation

### Quick Diagnostic Output
```
🔍 Quick Diagnostic for Thinking Callback Issue
==================================================
✅ Functions available:
   - send_message_command_smart: true
   - send_message_command_thinking: true
   - send_message_thinking_streaming: true
✅ Model detection:
   - Current model: deepseek-r1:1.5b
   - Supports thinking: true
✅ Notification system: true
✅ Keymap <CR> found: :ParagonicSendSmart<CR>
==================================================
🔍 Diagnostic complete. Check the results above for issues.
```

### Full Test Suite Output
```
🧪 Starting Automated Test Suite for Thinking Callback Functionality
======================================================================
✅ Keymap Setup (PASSED in 0.05s)
✅ Model Detection (PASSED in 0.02s)
✅ Function Registration (PASSED in 0.01s)
...
======================================================================
📊 Test Summary:
   Passed: 10
   Failed: 0
   Total: 10

🎉 All tests passed! The thinking callback functionality should be working.
```

## Common Issues and Solutions

### Issue: "Keymap <CR> not found"
**Cause:** Buffer-specific keymap not set correctly
**Solution:** Check `create_chat_buffer()` function in `chat.lua`

### Issue: "Model should support thinking"
**Cause:** Wrong model configured or model detection failing
**Solution:** Check `model_capabilities` in `config.lua`

### Issue: "Test notification not found"
**Cause:** Function not being called or notification system broken
**Solution:** Check function registration and notification override

### Issue: "Callback not executed"
**Cause:** Callback creation or execution failing
**Solution:** Check callback definition and test execution

## Performance Considerations

- **Quick diagnostic:** ~30 seconds
- **Full test suite:** ~2-3 minutes
- **Manual testing:** ~1 minute
- **Total iteration time:** ~3-5 minutes

This allows for rapid iteration and quick identification of issues.

## Integration with Development Workflow

1. **Before making changes:** Run quick diagnostic to establish baseline
2. **After making changes:** Run quick diagnostic to verify fixes
3. **Before committing:** Run full test suite to ensure everything works
4. **When debugging:** Use manual testing to see real behavior

## Future Enhancements

- Add performance benchmarks
- Add stress testing for concurrent operations
- Add integration tests with actual backend
- Add visual regression tests for UI components
