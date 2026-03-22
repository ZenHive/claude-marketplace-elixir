---
name: web-command
description: Web browsing in Claude Code using the `web` command. Use `web` for browser interactions: form submission, JavaScript execution, LiveView testing, screenshots, authenticated sessions. Use WebFetch for read-only content extraction (documentation, articles). Invoke when fetching pages, submitting forms, testing LiveView, or taking screenshots.
allowed-tools: Bash, Read
---

<!-- Auto-synced from ~/.claude/includes/web-command.md — do not edit manually -->

## Web Browsing: `web` Command and `WebFetch`

**Use the right tool for the job:**

- **`WebFetch` tool**: For read-only content extraction (docs, articles, data). Returns clean, summarized content.
- **`web` command** (`/usr/local/bin/web`): For interactions requiring a real browser — forms, JS execution, LiveView, screenshots, sessions.

**Why the distinction:** The `web` command launches a headless browser and dumps raw HTML-to-markdown, including navigation menus, sidebars, version dropdowns, and page chrome. For reading content, this noise often pushes actual content past truncation limits. `WebFetch` processes content through an LLM and returns only what you asked for.

**Repository:** https://github.com/chrismccord/web

### When to Use Which

| Task | Tool | Why |
|------|------|-----|
| Read documentation | `WebFetch` | Clean extraction, no chrome noise |
| Extract specific data from a page | `WebFetch` | Prompt-guided extraction |
| Read articles/blog posts | `WebFetch` | Content-focused output |
| Submit forms | `web` | Real browser, JS execution |
| Phoenix LiveView pages | `web` | Waits for `.phx-connected` |
| Take screenshots | `web` | `--screenshot` flag |
| Execute JavaScript | `web` | `--js` flag |
| Maintain login sessions | `web` | `--profile` for cookie persistence |
| Page requires JS to render content | `web` | Real browser engine |

### `web` Command Usage

```bash
# Convert webpage to markdown (default: 100k char limit)
web https://example.com

# Fetch with custom truncation
web https://example.com --truncate-after 5000

# Take a screenshot
web https://example.com --screenshot /tmp/page.png

# Execute JavaScript on page
web https://example.com --js "document.querySelector('button').click()"
```

### Phoenix LiveView Form Submission
```bash
# Login to Phoenix app (auto-waits for LiveView connection)
web http://localhost:4000/users/log-in \
    --form "login_form" \
    --input "user[email]" --value "test@example.com" \
    --input "user[password]" --value "secret123" \
    --after-submit "http://localhost:4000/dashboard"
```

### Session Persistence
```bash
# Use named profile to maintain cookies/auth across runs
web --profile "myapp" http://localhost:4000/login ...
web --profile "myapp" http://localhost:4000/protected-page
```

### `web` Options Reference
| Option | Description |
|--------|-------------|
| `--raw` | Output raw HTML instead of markdown |
| `--truncate-after N` | Limit output to N characters (default: 100000) |
| `--screenshot PATH` | Save full-page screenshot |
| `--form ID` | Target form by ID for input filling |
| `--input NAME` | Form field name attribute |
| `--value VALUE` | Value for the preceding `--input` |
| `--after-submit URL` | Navigate to URL after form submission |
| `--js CODE` | Execute JavaScript after page loads |
| `--profile NAME` | Named session profile for cookie persistence |
