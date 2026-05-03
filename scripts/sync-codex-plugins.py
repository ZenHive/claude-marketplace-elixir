#!/usr/bin/env python3
"""Sync a Codex-friendly subset of this Claude marketplace into local paths."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import shlex
import stat
import subprocess
import sys


DEFAULT_CORE_SYNC_SCRIPT = Path(
    "~/.codex/skills/sync-claude-includes/scripts/sync_claude_includes.py"
).expanduser()
DEFAULT_HOOKS_PATH = Path("~/.codex/hooks.json").expanduser()
DEFAULT_MARKETPLACE_PATH = Path("~/.agents/plugins/marketplace.json").expanduser()
DEFAULT_PLUGINS_ROOT = Path("~/plugins").expanduser()

PLUGIN_ORDER = [
    "elixir",
    "phoenix",
    "staged-review",
    "task-driver",
    "portfolio-strategy",
    "cloud-delegation",
]

PLUGIN_CONFIG = {
    "elixir": {
        "category": "Developer Tools",
        "display_name": "Elixir",
        "skills": {
            "git-worktrees",
            "hex-docs-search",
            "integration-testing",
            "popcorn",
            "tidewave-guide",
            "usage-rules",
        },
        "scripts": {
            "phx-new-check.sh",
            "prefer-dialyzer-json.sh",
            "prefer-test-json.sh",
            "pre-commit-unified.sh",
            "recommend-docs-lookup.sh",
            "reset-test-tracker.sh",
            "suggest-test-failed.sh",
            "suggest-test-include.sh",
        },
        "lib_dirs": {"lib"},
    },
    "phoenix": {
        "category": "Developer Tools",
        "display_name": "Phoenix",
    },
    "staged-review": {
        "category": "Productivity",
        "display_name": "Staged Review",
    },
    "task-driver": {
        "category": "Productivity",
        "display_name": "Task Driver",
    },
    "portfolio-strategy": {
        "category": "Productivity",
        "display_name": "Portfolio Strategy",
    },
    "cloud-delegation": {
        "category": "Productivity",
        "display_name": "Cloud Delegation",
    },
}

SAFE_MARKDOWN_REPLACEMENTS = (
    ("Claude Code", "Codex"),
    ("AskUserQuestion", "request_user_input"),
    ("TodoWrite", "update_plan"),
    ("TaskCreate", "update_plan"),
    ("TaskUpdate", "update_plan"),
    ("SlashCommand", "skill"),
)

ELIXIR_RETAINED_HOOKS = {
    "PreToolUse": {"matcher": "Bash"},
    "PostToolUse": {"matcher": "Bash"},
    "UserPromptSubmit": None,
}


@dataclass(frozen=True)
class FileSpec:
    path: Path
    content: bytes
    mode: int | None = None


@dataclass(frozen=True)
class FileAction:
    status: str
    path: Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without writing. This is the default mode.",
    )
    mode.add_argument(
        "--apply",
        action="store_true",
        help="Write files to the destination roots.",
    )
    parser.add_argument(
        "--plugin",
        action="append",
        default=[],
        help="Sync only specific supported plugin(s). Can be repeated.",
    )
    parser.add_argument(
        "--skip-core-sync",
        action="store_true",
        help="Do not invoke the include-backed core skill sync helper.",
    )
    parser.add_argument(
        "--marketplace-only",
        action="store_true",
        help="Only regenerate the marketplace JSON for the selected plugins.",
    )
    parser.add_argument(
        "--plugins-root",
        default=str(DEFAULT_PLUGINS_ROOT),
        help="Destination root for local Codex plugins (default: ~/plugins).",
    )
    parser.add_argument(
        "--marketplace-path",
        default=str(DEFAULT_MARKETPLACE_PATH),
        help="Destination path for marketplace.json (default: ~/.agents/plugins/marketplace.json).",
    )
    parser.add_argument(
        "--hooks-path",
        default=str(DEFAULT_HOOKS_PATH),
        help="Destination path for a discovered Codex hooks.json layer (default: ~/.codex/hooks.json).",
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Repository root containing the plugins/ directory (default: current directory).",
    )
    parser.add_argument(
        "--core-sync-script",
        default=str(DEFAULT_CORE_SYNC_SCRIPT),
        help="Path to sync_claude_includes.py (default: ~/.codex/skills/.../sync_claude_includes.py).",
    )
    parser.add_argument(
        "--skip-hooks-sync",
        action="store_true",
        help="Do not regenerate a discovered hooks.json layer from supported plugin hooks.",
    )
    return parser.parse_args()


def normalize_selected_plugins(values: list[str]) -> list[str]:
    if not values:
        return list(PLUGIN_ORDER)

    selected = []
    invalid = []
    for value in values:
        if value not in PLUGIN_CONFIG:
            invalid.append(value)
            continue
        if value not in selected:
            selected.append(value)

    if invalid:
        valid = ", ".join(PLUGIN_ORDER)
        invalid_list = ", ".join(invalid)
        raise ValueError(f"Unsupported plugin(s): {invalid_list}. Valid values: {valid}")

    return [name for name in PLUGIN_ORDER if name in selected]


def strip_allowed_tools(text: str) -> str:
    if not text.startswith("---\n"):
        return text

    try:
        _, frontmatter, body = text.split("---\n", 2)
    except ValueError:
        return text

    filtered = [
        line for line in frontmatter.splitlines() if not line.startswith("allowed-tools:")
    ]
    normalized_frontmatter = "\n".join(filtered).rstrip()
    return f"---\n{normalized_frontmatter}\n---\n{body}"


def transform_markdown(text: str) -> str:
    transformed = strip_allowed_tools(text)
    for source, target in SAFE_MARKDOWN_REPLACEMENTS:
        transformed = transformed.replace(source, target)
    return transformed


def read_text_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def build_manifest(
    source_manifest_path: Path,
    plugin_name: str,
    *,
    has_skills: bool,
) -> bytes:
    source_manifest = json.loads(read_text_file(source_manifest_path))
    config = PLUGIN_CONFIG[plugin_name]

    manifest = {
        "name": source_manifest["name"],
        "version": source_manifest["version"],
        "description": source_manifest["description"],
        "author": source_manifest["author"],
        "repository": source_manifest.get("repository"),
        "license": source_manifest.get("license"),
        "keywords": source_manifest.get("keywords", []),
        "interface": {
            "displayName": config["display_name"],
            "shortDescription": source_manifest["description"],
            "developerName": source_manifest["author"]["name"],
            "category": config["category"],
        },
    }

    if source_manifest.get("homepage"):
        manifest["homepage"] = source_manifest["homepage"]
    if has_skills:
        manifest["skills"] = "./skills/"

    return json.dumps(manifest, indent=2, sort_keys=False).encode("utf-8") + b"\n"


def build_marketplace(selected_plugins: list[str]) -> bytes:
    entries = []
    for plugin_name in selected_plugins:
        config = PLUGIN_CONFIG[plugin_name]
        entries.append(
            {
                "name": plugin_name,
                "source": {
                    "source": "local",
                    "path": f"./plugins/{plugin_name}",
                },
                "policy": {
                    "installation": "AVAILABLE",
                    "authentication": "ON_INSTALL",
                },
                "category": config["category"],
            }
        )

    marketplace = {
        "name": "local-codex",
        "interface": {"displayName": "Local Codex Plugins"},
        "plugins": entries,
    }
    return json.dumps(marketplace, indent=2, sort_keys=False).encode("utf-8") + b"\n"


def iter_files(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*") if path.is_file())


def copy_tree_specs(
    source_root: Path,
    dest_root: Path,
    *,
    markdown_transform: bool = False,
) -> list[FileSpec]:
    specs = []
    for source_path in iter_files(source_root):
        relative_path = source_path.relative_to(source_root)
        destination_path = dest_root / relative_path

        if markdown_transform and source_path.suffix.lower() == ".md":
            text = transform_markdown(read_text_file(source_path))
            specs.append(FileSpec(destination_path, text.encode("utf-8"), 0o644))
            continue

        specs.append(
            FileSpec(
                destination_path,
                source_path.read_bytes(),
                stat.S_IMODE(source_path.stat().st_mode),
            )
        )

    return specs


def build_elixir_hook_entries(
    source_plugin_root: Path,
    plugins_root: Path,
) -> dict[str, list[dict[str, object]]]:
    source_path = source_plugin_root / "hooks" / "hooks.json"
    source_data = json.loads(read_text_file(source_path))
    filtered_hooks: dict[str, list[dict[str, object]]] = {}

    for event_name, matcher_config in ELIXIR_RETAINED_HOOKS.items():
        retained_entries = []
        for entry in source_data.get("hooks", {}).get(event_name, []):
            if matcher_config and entry.get("matcher") != matcher_config["matcher"]:
                continue

            retained_commands = []
            for hook in entry.get("hooks", []):
                command = hook.get("command")
                if not isinstance(command, str):
                    continue

                script_name = Path(command.replace("${CLAUDE_PLUGIN_ROOT}/scripts/", "")).name
                if script_name not in PLUGIN_CONFIG["elixir"]["scripts"]:
                    continue

                new_hook = dict(hook)
                script_path = (plugins_root / "elixir" / "scripts" / script_name).resolve()
                new_hook["command"] = shlex.quote(str(script_path))
                retained_commands.append(new_hook)

            if retained_commands:
                new_entry = dict(entry)
                new_entry["hooks"] = retained_commands
                retained_entries.append(new_entry)

        if retained_entries:
            filtered_hooks[event_name] = retained_entries

    return filtered_hooks


def is_managed_hook_command(command: str) -> bool:
    return any(script_name in command for script_name in PLUGIN_CONFIG["elixir"]["scripts"])


def merge_hook_lists(
    existing_entries: list[dict[str, object]],
    generated_entries: list[dict[str, object]],
) -> list[dict[str, object]]:
    retained_entries: list[dict[str, object]] = []
    for entry in existing_entries:
        entry_hooks = entry.get("hooks")
        if not isinstance(entry_hooks, list):
            retained_entries.append(entry)
            continue

        unmanaged_hooks = []
        for hook in entry_hooks:
            command = hook.get("command")
            if isinstance(command, str) and is_managed_hook_command(command):
                continue
            unmanaged_hooks.append(hook)

        if unmanaged_hooks:
            new_entry = dict(entry)
            new_entry["hooks"] = unmanaged_hooks
            retained_entries.append(new_entry)

    return retained_entries + generated_entries


def build_hooks_spec(repo_root: Path, plugins_root: Path, hooks_path: Path) -> FileSpec | None:
    source_plugin_root = repo_root / "plugins" / "elixir"
    generated_hooks = build_elixir_hook_entries(source_plugin_root, plugins_root)
    if not generated_hooks:
        return None

    existing_data: dict[str, object] = {"hooks": {}}
    if hooks_path.exists():
        existing_data = json.loads(read_text_file(hooks_path))

    existing_hooks = existing_data.get("hooks", {})
    if not isinstance(existing_hooks, dict):
        existing_hooks = {}

    merged_hooks = dict(existing_hooks)
    for event_name, generated_entries in generated_hooks.items():
        existing_entries = existing_hooks.get(event_name, [])
        if not isinstance(existing_entries, list):
            existing_entries = []
        merged_hooks[event_name] = merge_hook_lists(existing_entries, generated_entries)

    return FileSpec(
        hooks_path,
        json.dumps({"hooks": merged_hooks}, indent=2, sort_keys=False).encode("utf-8") + b"\n",
        0o644,
    )


def build_plugin_specs(repo_root: Path, plugins_root: Path, plugin_name: str) -> list[FileSpec]:
    source_plugin_root = repo_root / "plugins" / plugin_name
    destination_plugin_root = plugins_root / plugin_name
    specs: list[FileSpec] = []
    has_skills = False

    if plugin_name == "elixir":
        for skill_name in sorted(PLUGIN_CONFIG["elixir"]["skills"]):
            source_skill_root = source_plugin_root / "skills" / skill_name
            destination_skill_root = destination_plugin_root / "skills" / skill_name
            specs.extend(
                copy_tree_specs(
                    source_skill_root,
                    destination_skill_root,
                    markdown_transform=True,
                )
            )
        has_skills = True

        for lib_dir in PLUGIN_CONFIG["elixir"]["lib_dirs"]:
            source_lib_root = source_plugin_root / lib_dir
            destination_lib_root = destination_plugin_root / lib_dir
            specs.extend(copy_tree_specs(source_lib_root, destination_lib_root))

        for script_name in sorted(PLUGIN_CONFIG["elixir"]["scripts"]):
            source_script_path = source_plugin_root / "scripts" / script_name
            destination_script_path = destination_plugin_root / "scripts" / script_name
            specs.append(
                FileSpec(
                    destination_script_path,
                    source_script_path.read_bytes(),
                    stat.S_IMODE(source_script_path.stat().st_mode),
                )
            )
    else:
        source_skills_root = source_plugin_root / "skills"
        destination_skills_root = destination_plugin_root / "skills"
        if source_skills_root.exists():
            specs.extend(
                copy_tree_specs(
                    source_skills_root,
                    destination_skills_root,
                    markdown_transform=True,
                )
            )
            has_skills = True

    manifest_spec = FileSpec(
        destination_plugin_root / ".codex-plugin" / "plugin.json",
        build_manifest(
            source_plugin_root / ".claude-plugin" / "plugin.json",
            plugin_name,
            has_skills=has_skills,
        ),
        0o644,
    )
    specs.append(manifest_spec)
    return specs


def classify_file(path: Path, desired: bytes) -> str:
    if not path.exists():
        return "CREATE"
    current = path.read_bytes()
    return "UNCHANGED" if current == desired else "UPDATE"


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def write_file(spec: FileSpec) -> None:
    ensure_parent(spec.path)
    spec.path.write_bytes(spec.content)
    if spec.mode is not None:
        spec.path.chmod(spec.mode)


def apply_specs(specs: list[FileSpec], *, apply_changes: bool) -> list[FileAction]:
    actions = []
    for spec in specs:
        status = classify_file(spec.path, spec.content)
        actions.append(FileAction(status, spec.path))
        if apply_changes and status != "UNCHANGED":
            write_file(spec)
    return actions


def run_core_sync(script_path: Path, *, apply_changes: bool) -> str:
    command = [sys.executable, str(script_path)]
    if apply_changes:
        command.append("--apply")
    else:
        command.append("--dry-run")

    subprocess.run(command, check=True)
    return "APPLY" if apply_changes else "DRY-RUN"


def count_status(actions: list[FileAction], status: str) -> int:
    return sum(1 for action in actions if action.status == status)


def main() -> int:
    args = parse_args()
    apply_changes = args.apply

    repo_root = Path(args.repo_root).expanduser().resolve()
    plugins_root = Path(args.plugins_root).expanduser().resolve()
    marketplace_path = Path(args.marketplace_path).expanduser().resolve()
    hooks_path = Path(args.hooks_path).expanduser().resolve()
    core_sync_script = Path(args.core_sync_script).expanduser().resolve()

    try:
        selected_plugins = normalize_selected_plugins(args.plugin)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 1

    if not (repo_root / "plugins").exists():
        print(f"Missing plugins/ directory under repo root: {repo_root}", file=sys.stderr)
        return 1

    core_sync_mode = "SKIPPED"
    if not args.skip_core_sync and not args.marketplace_only:
        if not core_sync_script.exists():
            print(f"Core sync script not found: {core_sync_script}", file=sys.stderr)
            return 1
        try:
            core_sync_mode = run_core_sync(core_sync_script, apply_changes=apply_changes)
        except subprocess.CalledProcessError as error:
            print(f"Core sync failed with exit code {error.returncode}", file=sys.stderr)
            return error.returncode or 1

    plugin_actions: list[FileAction] = []
    if not args.marketplace_only:
        for plugin_name in selected_plugins:
            specs = build_plugin_specs(repo_root, plugins_root, plugin_name)
            plugin_actions.extend(apply_specs(specs, apply_changes=apply_changes))

    hook_actions: list[FileAction] = []
    if (
        not args.marketplace_only
        and not args.skip_hooks_sync
        and "elixir" in selected_plugins
    ):
        hook_spec = build_hooks_spec(repo_root, plugins_root, hooks_path)
        if hook_spec is not None:
            hook_actions = apply_specs([hook_spec], apply_changes=apply_changes)

    marketplace_spec = FileSpec(
        marketplace_path,
        build_marketplace(selected_plugins),
        0o644,
    )
    marketplace_actions = apply_specs([marketplace_spec], apply_changes=apply_changes)

    mode = "APPLY" if apply_changes else "DRY-RUN"
    print(f"Mode: {mode}")
    print(f"Repo root: {repo_root}")
    print(f"Plugins root: {plugins_root}")
    print(f"Marketplace: {marketplace_path}")
    print(f"Hooks path: {hooks_path}")
    print(f"Core sync: {core_sync_mode}")
    print(f"Selected plugins: {', '.join(selected_plugins)}")
    print("")

    for action in plugin_actions + hook_actions + marketplace_actions:
        print(f"[{action.status:<9}] {action.path}")

    print("")
    print(
        "Summary: "
        f"created={count_status(plugin_actions + hook_actions + marketplace_actions, 'CREATE')} "
        f"updated={count_status(plugin_actions + hook_actions + marketplace_actions, 'UPDATE')} "
        f"unchanged={count_status(plugin_actions + hook_actions + marketplace_actions, 'UNCHANGED')} "
        f"plugins={len(selected_plugins)} "
        f"marketplace_only={'yes' if args.marketplace_only else 'no'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
