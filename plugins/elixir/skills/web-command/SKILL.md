---
name: web-command
description: Use the `web` command for web browsing in Claude Code. Handles JavaScript, LiveView, forms, screenshots. Use when fetching web pages, submitting forms, or taking screenshots. NEVER use WebFetch.
allowed-tools: Bash, Read
---

# Web Command for Claude Code

Shell-based web browser optimized for Claude Code. **ALWAYS use `web` instead of WebFetch** - it handles JavaScript, Phoenix LiveView, and authenticated sessions properly.

## When to use this skill

Use this skill when you need to:
- Fetch and read web page content
- Submit forms (especially Phoenix LiveView forms)
- Maintain authenticated sessions across requests
- Take screenshots of web pages
- Execute JavaScript on loaded pages
- Work with any page requiring JavaScript execution

**NEVER use WebFetch** - the `web` command is more reliable and handles dynamic content.

## Installation

The `web` command is created by Chris McCord and available at: https://github.com/chrismccord/web.git

```bash
git clone https://github.com/chrismccord/web.git
cd web
./install.sh
```

After installation, the command is available at `/usr/local/bin/web`.

## What is the `web` command?

The `web` command is a shell-based browser that:
- Converts web pages to markdown for easy consumption by Claude
- Executes JavaScript and waits for dynamic content
- Auto-detects Phoenix LiveView and waits for `.phx-connected` class
- Supports form filling and submission
- Maintains session cookies across requests via profiles
- Captures full-page screenshots

## Basic usage

### Fetch a webpage as markdown

```bash
# Convert webpage to markdown (default: 100k char limit)
web https://example.com
```

### Truncate output

```bash
# Limit output to 5000 characters
web https://example.com --truncate-after 5000
```

### Get raw HTML

```bash
# Output raw HTML instead of markdown conversion
web https://example.com --raw
```

## Phoenix LiveView form submission

The `web` command auto-detects Phoenix LiveView applications and waits for the `.phx-connected` class before interacting. This is critical for reliable form submission.

### Login example

```bash
# Login to Phoenix app (auto-waits for LiveView connection)
web http://localhost:4000/users/log-in \
    --form "login_form" \
    --input "user[email]" --value "test@example.com" \
    --input "user[password]" --value "secret123" \
    --after-submit "http://localhost:4000/dashboard"
```

### Form submission pattern

1. `--form ID` - Target the form by its HTML `id` attribute
2. `--input NAME` - Specify form field name attribute
3. `--value VALUE` - Value for the preceding input
4. Repeat `--input`/`--value` pairs for multiple fields
5. `--after-submit URL` - Navigate to this URL after form submission

### Finding form IDs

Use browser dev tools or fetch the page first to identify form IDs:

```bash
# Fetch the login page and look for form elements
web http://localhost:4000/users/log-in --raw | grep -E '<form[^>]*id='
```

## Session persistence

Named profiles maintain cookies and authentication state across multiple requests.

```bash
# Login with a named profile
web --profile "myapp" http://localhost:4000/users/log-in \
    --form "login_form" \
    --input "user[email]" --value "test@example.com" \
    --input "user[password]" --value "secret123"

# Subsequent requests use the same session (authenticated)
web --profile "myapp" http://localhost:4000/dashboard
web --profile "myapp" http://localhost:4000/settings
```

**Profile use cases:**
- Testing authenticated workflows
- Multi-step form processes
- API exploration requiring auth tokens
- Maintaining CSRF tokens across requests

## Screenshot capture

Capture full-page screenshots for visual debugging or documentation.

```bash
# Save screenshot to file
web https://example.com --screenshot /tmp/page.png

# Combine with other options
web --profile "myapp" http://localhost:4000/dashboard --screenshot /tmp/dashboard.png
```

**Screenshot tips:**
- Use absolute paths for reliability
- PNG format recommended
- Screenshots capture full page (not just viewport)
- Useful for visual regression testing documentation

## JavaScript execution

Execute custom JavaScript after the page loads.

```bash
# Click a button
web https://example.com --js "document.querySelector('button').click()"

# Extract specific data
web https://example.com --js "document.querySelector('.price').textContent"

# Scroll to load lazy content
web https://example.com --js "window.scrollTo(0, document.body.scrollHeight)"

# Wait for element then interact
web https://example.com --js "
  await new Promise(r => setTimeout(r, 1000));
  document.querySelector('.load-more').click();
"
```

**Common JavaScript patterns:**
- Click buttons or links
- Fill inputs programmatically
- Trigger client-side events
- Extract dynamic content
- Wait for async operations

## Options reference

| Option | Description |
|--------|-------------|
| `--raw` | Output raw HTML instead of markdown |
| `--truncate-after N` | Limit output to N characters (default: 100000) |
| `--screenshot PATH` | Save full-page screenshot to PATH |
| `--form ID` | Target form by its HTML `id` attribute |
| `--input NAME` | Form field name attribute (use with `--value`) |
| `--value VALUE` | Value for the preceding `--input` |
| `--after-submit URL` | Navigate to URL after form submission |
| `--js CODE` | Execute JavaScript after page loads |
| `--profile NAME` | Named session profile for cookie persistence |

## When to use `web` vs WebFetch

| Scenario | Use |
|----------|-----|
| Any web browsing task | `web` (always try first) |
| Phoenix LiveView pages | `web` (required - waits for connection) |
| JavaScript-rendered content | `web` (executes JS) |
| Form submission | `web` (handles CSRF, sessions) |
| Authenticated sessions | `web` (profile persistence) |
| Screenshots needed | `web` (only option) |
| WebFetch tool available | Still use `web` |

**Rule: ALWAYS use `web` for web browsing. WebFetch is a fallback only if `web` is unavailable.**

## Examples

### Example 1: Fetch documentation

```bash
# Fetch Phoenix documentation
web https://hexdocs.pm/phoenix/Phoenix.html --truncate-after 20000
```

### Example 2: Test a Phoenix application

```bash
# Create a profile and log in
web --profile "test" http://localhost:4000/users/log-in \
    --form "login_form" \
    --input "user[email]" --value "admin@example.com" \
    --input "user[password]" --value "password123" \
    --after-submit "http://localhost:4000/admin"

# Take a screenshot of the admin dashboard
web --profile "test" http://localhost:4000/admin --screenshot /tmp/admin.png

# Navigate to settings
web --profile "test" http://localhost:4000/admin/settings
```

### Example 3: Debug a LiveView issue

```bash
# Fetch the page and check for LiveView connection
web http://localhost:4000/live-page --raw | grep -E 'phx-|data-phx'

# Take a screenshot to see current state
web http://localhost:4000/live-page --screenshot /tmp/debug.png

# Execute JS to check LiveView socket
web http://localhost:4000/live-page --js "window.liveSocket?.isConnected()"
```

### Example 4: Scrape dynamic content

```bash
# Fetch a page with JS-rendered content
web https://example.com/spa-page

# If content loads lazily, trigger it with JS
web https://example.com/spa-page --js "
  window.scrollTo(0, document.body.scrollHeight);
  await new Promise(r => setTimeout(r, 2000));
"
```

## Troubleshooting

### Page content missing or incomplete

- The page may require JavaScript: content should load automatically with `web`
- For lazy-loaded content, use `--js` to scroll or trigger loading
- Check if authentication is required (use `--profile`)

### Form submission fails

- Verify the form `id` with `--raw` output
- Check input field `name` attributes match exactly
- Ensure LiveView is connected (auto-detected, but check for JS errors)
- Use `--screenshot` to see the page state

### Session not persisting

- Ensure you're using the same `--profile` name for all requests
- Profiles are local to the machine - different machines need separate login
- Some sites may have short session timeouts

### LiveView not connecting

- The `web` command waits for `.phx-connected` class automatically
- If it times out, the LiveView may have an error
- Check the Phoenix server logs for connection issues
- Try `--js` to check socket state: `window.liveSocket?.isConnected()`

## Best practices

1. **Always use `web` first** - It handles JavaScript and dynamic content automatically
2. **Use profiles for auth workflows** - Maintains sessions across requests
3. **Take screenshots for debugging** - Visual context helps identify issues
4. **Truncate large pages** - Use `--truncate-after` to limit token usage
5. **Check form IDs first** - Fetch with `--raw` to find correct form/input names
6. **Use `--after-submit` for redirects** - Ensures you land on the expected page after form submission
