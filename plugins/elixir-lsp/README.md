# Elixir LSP Plugin

Integrates [Expert](https://expert-lsp.org/) - the official Elixir language server - with Claude Code.

## Features

Once installed, Claude Code gains access to LSP capabilities for Elixir files:

| Feature | Description |
|---------|-------------|
| **Go to Definition** | Jump to function/module definitions |
| **Find References** | Find all usages of a symbol |
| **Hover** | View documentation and type info |
| **Document Symbols** | List all symbols in a file |
| **Workspace Symbols** | Search symbols across the project |

## Prerequisites

You must install Expert separately. Choose one method:

### GitHub Releases (Recommended)

```bash
# Apple Silicon
gh release download nightly \
  --pattern '*darwin_arm64' \
  --output ~/.local/bin/expert \
  --clobber \
  --repo elixir-lang/expert && \
  chmod +x ~/.local/bin/expert

# Linux AMD64
gh release download nightly \
  --pattern '*linux_amd64' \
  --output ~/.local/bin/expert \
  --clobber \
  --repo elixir-lang/expert && \
  chmod +x ~/.local/bin/expert
```

### Mason (Neovim)

```vim
:MasonInstall expert
```

### Arch Linux (AUR)

```bash
yay -S expert-git
# or
paru -S expert-git
```

### From Source

```bash
git clone https://github.com/elixir-lang/expert.git
cd expert
just install  # Builds and copies to ~/.local/bin/
```

## Installation

```bash
# Add the marketplace (if not already added)
claude plugin marketplace add ZenHive/claude-marketplace-elixir

# Install the plugin
claude plugin install elixir-lsp@deltahedge
```

## Verification

After installation, verify Expert is working:

```bash
# Check Expert is in PATH
which expert

# Check version
expert --version
```

In Claude Code, the LSP tool will automatically use Expert for `.ex`, `.exs`, `.heex`, and `.leex` files.

## Supported File Types

| Extension | Language ID |
|-----------|-------------|
| `.ex` | elixir |
| `.exs` | elixir |
| `.heex` | elixir |
| `.leex` | elixir |

## Troubleshooting

### "Executable not found in $PATH"

Ensure Expert is installed and in your PATH:

```bash
# Add to your shell profile (~/.zshrc, ~/.bashrc, etc.)
export PATH="$HOME/.local/bin:$PATH"
```

### Expert not starting

Check Claude Code's LSP logs:

```bash
claude --enable-lsp-logging
# Logs are written to ~/.claude/debug/
```

## About Expert

Expert is the official Elixir language server, created by merging the three community LSP projects:

- [ElixirLS](https://github.com/elixir-lsp/elixir-ls)
- [Lexical](https://github.com/lexical-lsp/lexical)
- [Next LS](https://github.com/elixir-tools/next-ls)

Learn more at [expert-lsp.org](https://expert-lsp.org/).
