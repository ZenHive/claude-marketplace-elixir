# Claude Code Plugins for Elixir

Unofficial Claude Code plugin marketplace for Elixir and BEAM ecosystem development.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## What is this?

This is a [**Claude Code plugin marketplace**](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces) that provides Elixir and BEAM ecosystem development tools for Claude Code.

## Quick Start

### Install the Marketplace

```bash
claude
/plugin marketplace add ZenHive/claude-marketplace-elixir
```

### Install Plugins

```bash
/plugin install elixir@deltahedge           # Main Elixir hooks + skills
/plugin install phoenix@deltahedge          # Phoenix-specific skills
/plugin install elixir-workflows@deltahedge # Workflow commands (research, plan, implement, qa)
/plugin install git-commit@deltahedge       # Commit workflow
/plugin install md-includes@deltahedge      # @include directive processing
/plugin install serena@deltahedge           # Serena MCP integration
/plugin install notifications@deltahedge    # OS notifications
```

## Available Plugins (7)

| Plugin | Description |
|--------|-------------|
| [elixir](./plugins/elixir/README.md) | Main Elixir development - consolidated hooks (format, compile, credo, sobelow, dialyzer, etc.) + skills (hex-docs-search, usage-rules) |
| [phoenix](./plugins/phoenix/README.md) | Phoenix framework patterns, LiveView, scope, JS hooks, daisyUI, Nexus template |
| [elixir-workflows](./plugins/elixir-workflows/README.md) | Development workflow commands (research, plan, implement, QA, oneshot) |
| [git-commit](./plugins/git-commit/README.md) | Intelligent git commit workflow with AI-powered file grouping |
| [md-includes](./plugins/md-includes/README.md) | Process @include directives in CLAUDE.md for composable instructions |
| [serena](./plugins/serena/README.md) | Serena MCP integration - auto-activation and workflow helpers |
| [notifications](./plugins/notifications/README.md) | Native OS notifications when Claude Code needs attention |

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/ZenHive/claude-marketplace-elixir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ZenHive/claude-marketplace-elixir/discussions)

## Attribution

This project is a fork of [claude-marketplace-elixir](https://github.com/bradleygolden/claude-marketplace-elixir), originally created by [Bradley Golden](https://github.com/bradleygolden).

---

**Made with care for the Elixir community**
