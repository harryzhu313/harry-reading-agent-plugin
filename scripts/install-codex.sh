#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_NAME="harry-reading-agent"
INSTALL_DIR="${HARRY_READING_AGENT_PLUGIN_DIR:-$HOME/.candobear/plugins/$PLUGIN_NAME}"
MARKETPLACE_FILE="${HARRY_READING_AGENT_MARKETPLACE_FILE:-$HOME/.agents/plugins/marketplace.json}"
PLUGIN_SRC="$ROOT_DIR/plugins/$PLUGIN_NAME"
CONFIG_EXAMPLE="$ROOT_DIR/config/harry-reading-agent.example.json"

if [[ ! -f "$PLUGIN_SRC/.codex-plugin/plugin.json" ]]; then
  echo "找不到 plugin manifest: $PLUGIN_SRC/.codex-plugin/plugin.json" >&2
  exit 1
fi

if [[ ! -f "$CONFIG_EXAMPLE" ]]; then
  echo "找不到配置模板: $CONFIG_EXAMPLE" >&2
  exit 1
fi

export HARRY_READING_AGENT_SOURCE_DIR="$ROOT_DIR"
export HARRY_READING_AGENT_INSTALL_DIR="$INSTALL_DIR"
export HARRY_READING_AGENT_MARKETPLACE_FILE="$MARKETPLACE_FILE"
export HARRY_READING_AGENT_CONFIG_EXAMPLE="$CONFIG_EXAMPLE"
export HARRY_READING_AGENT_PLUGIN_NAME="$PLUGIN_NAME"

python3 <<'PY'
import json
import os
import shutil
from datetime import datetime
from pathlib import Path


def copy_package(src: Path, dest: Path) -> None:
    if src == dest:
        return
    if dest.exists():
        retired_root = dest.parent / ".retired"
        retired_root.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        retired = retired_root / f"{dest.name}-{stamp}"
        suffix = 1
        while retired.exists():
            retired = retired_root / f"{dest.name}-{stamp}-{suffix}"
            suffix += 1
        shutil.move(str(dest), str(retired))
        print(f"已备份旧安装目录: {retired}")

    def ignore(_dir, names):
        ignored = {".DS_Store", ".agents", ".git", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache"}
        return {name for name in names if name in ignored}

    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src, dest, ignore=ignore)
    print(f"已刷新安装目录: {dest}")


def update_marketplace(marketplace_path: Path, plugin_name: str, source_path: str) -> str:
    if marketplace_path.exists():
        data = json.loads(marketplace_path.read_text(encoding="utf-8"))
    else:
        data = {"name": "personal", "interface": {"displayName": "Personal"}, "plugins": []}
    data.setdefault("name", "personal")
    data.setdefault("interface", {}).setdefault("displayName", "Personal")
    entry = {
        "name": plugin_name,
        "source": {"source": "local", "path": source_path},
        "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
        "category": "Productivity",
    }
    plugins = []
    replaced = False
    for plugin in data.get("plugins", []):
        if plugin.get("name") == plugin_name:
            if not replaced:
                plugins.append(entry)
                replaced = True
            continue
        plugins.append(plugin)
    if not replaced:
        plugins.append(entry)
    data["plugins"] = plugins
    marketplace_path.parent.mkdir(parents=True, exist_ok=True)
    marketplace_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return str(data["name"])


def ensure_toml_table(config_path: Path, header: str, settings: dict[str, str]) -> None:
    text = config_path.read_text(encoding="utf-8") if config_path.exists() else ""
    lines = text.splitlines()
    try:
        start = next(i for i, line in enumerate(lines) if line.strip() == header)
    except StopIteration:
        if lines and lines[-1].strip():
            lines.append("")
        lines.append(header)
        for key, value in settings.items():
            lines.append(f"{key} = {value}")
        config_path.parent.mkdir(parents=True, exist_ok=True)
        config_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
        return
    end = start + 1
    while end < len(lines) and not (lines[end].strip().startswith("[") and lines[end].strip().endswith("]")):
        end += 1
    existing = {}
    for i in range(start + 1, end):
        stripped = lines[i].strip()
        if "=" in stripped and not stripped.startswith("#"):
            existing[stripped.split("=", 1)[0].strip()] = i
    for key, value in settings.items():
        if key in existing:
            lines[existing[key]] = f"{key} = {value}"
        else:
            lines.insert(end, f"{key} = {value}")
            end += 1
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def retire_cache(home: Path, plugin_name: str, marketplace_name: str) -> None:
    cache_root = home / ".codex" / "plugins" / "cache"
    retired_root = home / ".codex" / "plugins" / "cache-retired"
    for marketplace in sorted({"personal", marketplace_name, "candobear-agentlab", "candobear-local"}):
        cache_dir = cache_root / marketplace / plugin_name
        if not cache_dir.exists():
            continue
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        retired = retired_root / marketplace / f"{plugin_name}-{stamp}"
        suffix = 1
        while retired.exists():
            retired = retired_root / marketplace / f"{plugin_name}-{stamp}-{suffix}"
            suffix += 1
        retired.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(cache_dir), str(retired))
        print(f"已移走 Codex cache: {retired}")


home = Path.home().resolve()
source_dir = Path(os.environ["HARRY_READING_AGENT_SOURCE_DIR"]).resolve()
install_dir = Path(os.environ["HARRY_READING_AGENT_INSTALL_DIR"]).expanduser().resolve()
plugin_name = os.environ["HARRY_READING_AGENT_PLUGIN_NAME"]
marketplace_file = Path(os.environ["HARRY_READING_AGENT_MARKETPLACE_FILE"]).expanduser().resolve()
config_example = Path(os.environ["HARRY_READING_AGENT_CONFIG_EXAMPLE"]).resolve()

copy_package(source_dir, install_dir)
plugin_dir = install_dir / "plugins" / plugin_name
manifest = json.loads((plugin_dir / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8"))
source_path = "./" + plugin_dir.relative_to(home).as_posix()
marketplace_name = update_marketplace(marketplace_file, manifest["name"], source_path)

codex_config = home / ".codex" / "config.toml"
ensure_toml_table(codex_config, f"[marketplaces.{marketplace_name}]", {"source_type": "\"local\"", "source": json.dumps(str(home), ensure_ascii=False)})
ensure_toml_table(codex_config, f"[plugins.\"{manifest['name']}@{marketplace_name}\"]", {"enabled": "true"})

agent_config_dir = home / ".codex" / manifest["name"]
agent_config_dir.mkdir(parents=True, exist_ok=True)
shutil.copy2(config_example, agent_config_dir / "config.example.json")
if not (agent_config_dir / "config.json").exists():
    shutil.copy2(config_example, agent_config_dir / "config.json")

retire_cache(home, manifest["name"], marketplace_name)
print(f"已更新 marketplace: {marketplace_file}")
print(f"已使用 marketplace: {marketplace_name}")
print(f"已注册 plugin path: {source_path}")
print(f"本机配置文件: {agent_config_dir / 'config.json'}")
PY

echo "安装完成。请重启 Codex，或开启新会话后使用 Harry 个人阅读库 Agent。"
