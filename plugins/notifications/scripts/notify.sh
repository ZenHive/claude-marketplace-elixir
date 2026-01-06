#!/bin/bash
# Native OS notification script for Claude Code
# Sends notifications when Claude is idle or needs permission

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract notification details
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code needs attention"')
TYPE=$(echo "$INPUT" | jq -r '.notification_type // "notification"')

# Format the subtitle based on notification type
case "$TYPE" in
  "idle_prompt")
    SUBTITLE="Waiting for input"
    ;;
  "permission_prompt")
    SUBTITLE="Permission required"
    ;;
  "auth_success")
    SUBTITLE="Authentication"
    ;;
  "elicitation_dialog")
    SUBTITLE="Input needed"
    ;;
  *)
    SUBTITLE="$TYPE"
    ;;
esac

# Detect OS and send notification
case "$(uname -s)" in
  Darwin)
    # macOS - use osascript for native notifications
    osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\" subtitle \"$SUBTITLE\"" 2>/dev/null || true
    ;;
  Linux)
    # Linux - try notify-send (common on most distros)
    if command -v notify-send &> /dev/null; then
      notify-send "Claude Code - $SUBTITLE" "$MESSAGE" 2>/dev/null || true
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    # Windows - use PowerShell toast notification
    powershell -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null; \$template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02; \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(\$template); \$text = \$xml.GetElementsByTagName('text'); \$text[0].AppendChild(\$xml.CreateTextNode('Claude Code - $SUBTITLE')) | Out-Null; \$text[1].AppendChild(\$xml.CreateTextNode('$MESSAGE')) | Out-Null; \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml); [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)" 2>/dev/null || true
    ;;
esac

exit 0
