#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="harry-reading-agent"
INSTALL_DIR="${HARRY_READING_AGENT_PLUGIN_DIR:-$HOME/.candobear/plugins/$PLUGIN_NAME}"
MARKETPLACE_FILE="${HARRY_READING_AGENT_MARKETPLACE_FILE:-$HOME/.agents/plugins/marketplace.json}"

export HARRY_READING_AGENT_PLUGIN_NAME="$PLUGIN_NAME"
export HARRY_READING_AGENT_INSTALL_DIR="$INSTALL_DIR"
export HARRY_READING_AGENT_MARKETPLACE_FILE="$MARKETPLACE_FILE"

python3 <<'PY'
import json
import os
import shutil
from datetime import datetime
from pathlib import Path

home = Path.home().resolve()
plugin_name = os.environ["HARRY_READING_AGENT_PLUGIN_NAME"]
install_dir = Path(os.environ["HARRY_READING_AGENT_INSTALL_DIR"]).expanduser().resolve()
marketplace_path = Path(os.environ["HARRY_READING_AGENT_MARKETPLACE_FILE"]).expanduser().resolve()
cache_root = home / ".codex" / "plugins" / "cache"
retired_root = home / ".codex" / "plugins" / "cache-retired"

if install_dir.exists():
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    retired = install_dir.parent / ".retired" / f"{install_dir.name}-{stamp}"
    retired.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(install_dir), str(retired))
    print(f"已移走安装目录: {retired}")

marketplaces = {"personal", "candobear-agentlab", "candobear-local"}
if marketplace_path.exists():
    try:
        marketplaces.add(json.loads(marketplace_path.read_text(encoding="utf-8")).get("name", "personal"))
    except json.JSONDecodeError:
        pass

for marketplace in sorted(marketplaces):
    cache_dir = cache_root / marketplace / plugin_name
    if cache_dir.exists():
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        retired = retired_root / marketplace / f"{plugin_name}-{stamp}"
        retired.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(cache_dir), str(retired))
        print(f"已移走 Codex cache: {retired}")

if marketplace_path.exists():
    data = json.loads(marketplace_path.read_text(encoding="utf-8"))
    data["plugins"] = [p for p in data.get("plugins", []) if p.get("name") != plugin_name]
    marketplace_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"已更新 marketplace: {marketplace_path}")

print("卸载完成。本机 ~/.codex/harry-reading-agent/config.json 会保留，避免误删你的私有配置。")
PY
