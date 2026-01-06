# Notifications Plugin

Native OS notifications when Claude Code needs your attention.

## Features

- **Idle notifications**: Get notified when Claude has been waiting for input for 60+ seconds
- **Permission prompts**: Get notified when Claude needs permission to execute a tool
- **Cross-platform**: Works on macOS, Linux, and Windows

## Installation

```bash
/plugin install notifications@deltahedge
```

## How It Works

This plugin uses a `Notification` hook that triggers on `idle_prompt` and `permission_prompt` events. When triggered, it sends a native OS notification:

- **macOS**: Uses `osascript` for native Notification Center integration
- **Linux**: Uses `notify-send` (requires libnotify/notification daemon)
- **Windows**: Uses PowerShell toast notifications

## Notification Types

| Type | When It Fires |
|------|---------------|
| `idle_prompt` | Claude has been waiting for input for 60+ seconds |
| `permission_prompt` | Claude needs permission to use a tool |
| `auth_success` | Authentication completed successfully |
| `elicitation_dialog` | MCP tool needs additional input |

## Configuration

The hook is configured to match `idle_prompt|permission_prompt` by default. To customize, you can override in your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt|permission_prompt|auth_success",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## Requirements

- **macOS**: No additional requirements (uses built-in `osascript`)
- **Linux**: `notify-send` command (usually from `libnotify-bin` package)
- **Windows**: PowerShell (included with Windows 10+)

## Terminal-Specific Alternatives

If you use iTerm2, you can also enable built-in notifications:

1. Open iTerm2 Preferences
2. Navigate to Profiles → Terminal
3. Enable "Silence bell"
4. Enable Filter Alerts → "Send escape sequence-generated alerts"

This plugin provides a terminal-agnostic alternative that works with any terminal including Ghostty, Alacritty, Kitty, WezTerm, etc.
