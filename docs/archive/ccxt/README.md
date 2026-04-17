# CCXT Methodology Archive

These three reference files were originally attached to retired skills (`api-consumer`, `meta-development`) in the marketplace, but they describe methodology for two sibling projects — not for the marketplace itself. Preserved here because the content is proprietary and not in any training corpus.

| File | Topic | Home |
|------|-------|------|
| `layered-abstraction.md` | CCXT Node.js bridge over Unix sockets — thin Elixir wrapper pattern | `../../../../ccxt_client` |
| `sync-fixtures.md` | Compile-time ExUnit test generation from `__methods__()` introspection | `../../../../ccxt_client` |
| `code-generation.md` | Case study: generating 110 exchange modules with 7 signing patterns from CCXT specs | `../../../../ccxt_extract` |

Sibling repo paths (both under `/Users/efries/_DATA/code/`):
- `ccxt_client` — Elixir client that calls CCXT via the Node.js bridge
- `ccxt_extract` — tooling that extracts CCXT specs and generates Elixir modules

**Long-term home:** move each file into the docs folder of its owning repo when convenient. Kept here so the content survives the retirement of the skills that previously owned them (see root CHANGELOG for context).
