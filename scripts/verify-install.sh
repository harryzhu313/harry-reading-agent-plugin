#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_SRC="$ROOT_DIR/plugins/harry-reading-agent"
SCAN_ONLY=0
SKIP_CONFIG=0

for arg in "$@"; do
  case "$arg" in
    --scan-only)
      SCAN_ONLY=1
      ;;
    --skip-config)
      SKIP_CONFIG=1
      ;;
    *)
      echo "未知参数: $arg" >&2
      echo "用法: ./scripts/verify-install.sh [--scan-only] [--skip-config]" >&2
      exit 2
      ;;
  esac
done

export HARRY_READING_AGENT_ROOT="$ROOT_DIR"
export HARRY_READING_AGENT_PLUGIN_SRC="$PLUGIN_SRC"
export HARRY_READING_AGENT_SCAN_ONLY="$SCAN_ONLY"
export HARRY_READING_AGENT_SKIP_CONFIG="$SKIP_CONFIG"

python3 <<'PY'
import json
import os
import re
import sys
from pathlib import Path


credential_words = "|".join(["TO" + "KEN", "SEC" + "RET", "API" + "_KEY"])
excluded_skill = "neican-" + "site-publisher"
collection_scheme = "collection" + "://"
maintainer_path = "/Users/" + "ho" + "wie" + ".serious"
private_user_id = "7d" + "595d5a" + "-a982-4090-a947-a5435a3317ce"
deploy_config = "wrang" + "ler"

FORBIDDEN = [
    (re.compile(re.escape(collection_scheme) + r"[0-9a-f-]+", re.I), "Notion collection/data source URL"),
    (re.compile(r"https://www[.]notion[.]so/[^\s)`]+", re.I), "Notion private URL"),
    (re.compile(r"\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b", re.I), "UUID-shaped private ID"),
    (re.compile(r"\b[0-9a-f]{32}\b", re.I), "32-char Notion-style private ID"),
    (re.compile(re.escape(maintainer_path)), "maintainer local absolute path"),
    (re.compile(re.escape(private_user_id), re.I), "private Notion user ID"),
    (re.compile(r"\bsk-[A-Za-z0-9_-]{20,}"), "OpenAI style secret key"),
    (re.compile(rf"\b[A-Za-z0-9_]*({credential_words})[A-Za-z0-9_]*\s*=", re.I), "secret assignment"),
    (re.compile(excluded_skill), "excluded website publisher skill"),
    (re.compile(rf"{deploy_config}[.]jsonc|{deploy_config}[.]search[.]jsonc"), "website deployment config"),
]


def fail(message: str) -> None:
    print(f"验证失败: {message}", file=sys.stderr)
    raise SystemExit(1)


def ok(message: str) -> None:
    print(f"OK: {message}")


def scan_repo(root: Path) -> None:
    hits = []
    ignored_dirs = {".git", "node_modules", "artifacts", "dist", ".cache", ".tmp"}
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if any(part in ignored_dirs for part in path.parts):
            continue
        if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico"}:
            continue
        try:
            text = path.read_text(errors="ignore")
        except UnicodeDecodeError:
            continue
        rel = path.relative_to(root)
        for line_no, line in enumerate(text.splitlines(), 1):
            for pattern, label in FORBIDDEN:
                if pattern.search(line):
                    hits.append(f"{rel}:{line_no}: {label}")
    if hits:
        print("\n".join(hits), file=sys.stderr)
        fail(f"红线扫描命中 {len(hits)} 处")
    ok("红线扫描通过")


def check_placeholders(config_path: Path, skip_config: bool) -> None:
    if skip_config:
        ok("已跳过本机配置检查")
        return
    if not config_path.exists():
        fail(f"缺少本机配置文件: {config_path}")
    text = config_path.read_text()
    if "YOUR_" in text:
        print(f"提示: {config_path} 仍包含 YOUR_* 占位符；安装结构有效，但正式写入前必须补齐。")
    ok(f"本机配置文件存在: {config_path}")


def check_same_file(source: Path, installed: Path, label: str) -> None:
    if not installed.exists():
        fail(f"{label} 缺少文件: {installed}")
    if source.read_bytes() != installed.read_bytes():
        fail(f"{label} 与源码不一致: {installed}")


def check_plugin_files(source_plugin: Path, installed_plugin: Path, label: str) -> None:
    key_files = [
        ".codex-plugin/plugin.json",
        "README.md",
        "skills/daily-reads-import/SKILL.md",
        "skills/personal-reading-reminder/SKILL.md",
        "assets/app-icon.svg",
    ]
    for rel_path in key_files:
        check_same_file(source_plugin / rel_path, installed_plugin / rel_path, label)
    ok(f"{label} 与源码关键文件一致")


root = Path(os.environ["HARRY_READING_AGENT_ROOT"]).resolve()
plugin_src = Path(os.environ["HARRY_READING_AGENT_PLUGIN_SRC"]).resolve()
scan_repo(root)

if os.environ["HARRY_READING_AGENT_SCAN_ONLY"] == "1":
    print("扫描完成。")
    raise SystemExit(0)

home = Path(os.environ["HOME"]).expanduser().resolve()
manifest = json.loads((plugin_src / ".codex-plugin" / "plugin.json").read_text())
plugin_name = manifest["name"]
version = manifest["version"]

installed_package = home / ".candobear" / "plugins" / plugin_name
installed_plugin = installed_package / "plugins" / plugin_name
marketplace_path = home / ".agents" / "plugins" / "marketplace.json"
config_path = home / ".codex" / "config.toml"
agent_config = home / ".codex" / plugin_name / "config.json"

if not installed_plugin.exists():
    fail(f"安装目录不存在: {installed_plugin}")
ok(f"安装目录存在: {installed_plugin}")
removed_plugin = installed_package / "plugins" / "neican-editor-course"
if removed_plugin.exists():
    fail(f"安装包仍包含已移除的旧课程插件: {removed_plugin}")
ok("安装包不包含旧课程插件")
check_plugin_files(plugin_src, installed_plugin, "安装目录")

if not marketplace_path.exists():
    fail(f"marketplace 不存在: {marketplace_path}")
marketplace = json.loads(marketplace_path.read_text())
marketplace_name = marketplace.get("name", "personal")
entry = next((p for p in marketplace.get("plugins", []) if p.get("name") == plugin_name), None)
if not entry:
    fail(f"marketplace.json 缺少 {plugin_name} 条目")
expected_source_path = f"./.candobear/plugins/{plugin_name}/plugins/{plugin_name}"
if entry.get("source", {}).get("path") != expected_source_path:
    fail(f"marketplace.json 的 source.path 应为 {expected_source_path}")
ok("marketplace 条目正确")

if not config_path.exists():
    fail(f"Codex config 不存在: {config_path}")
config = config_path.read_text()
plugin_header = re.escape(f'[plugins."{plugin_name}@{marketplace_name}"]')
plugin_match = re.search(rf"^{plugin_header}\s*$([\s\S]*?)(?=^\[|\Z)", config, flags=re.MULTILINE)
if not plugin_match:
    fail(f"config.toml 缺少 [plugins.\"{plugin_name}@{marketplace_name}\"]")
if not re.search(r"^\s*enabled\s*=\s*true\s*$", plugin_match.group(1), flags=re.MULTILINE):
    fail("config.toml 中 Harry 个人阅读库 Agent 未启用")
ok(f"Codex config 已启用 {plugin_name}@{marketplace_name}")

cache_plugin = home / ".codex" / "plugins" / "cache" / marketplace_name / plugin_name / version
cache_manifest = cache_plugin / ".codex-plugin" / "plugin.json"
if cache_manifest.exists():
    cache_data = json.loads(cache_manifest.read_text())
    if cache_data.get("name") != plugin_name or cache_data.get("version") != version:
        fail("cache manifest 的 name/version 与源码不一致")
    check_plugin_files(plugin_src, cache_plugin, "Codex cache")
    ok(f"Codex cache 存在: {cache_plugin}")
else:
    ok("Codex cache 尚未重建；重启 Codex 后会自动生成")

prompts = manifest.get("interface", {}).get("defaultPrompt", [])
if len(prompts) > 10:
    fail("plugin.json interface.defaultPrompt 数量异常")
ok("plugin manifest 基础结构正确")

check_placeholders(agent_config, os.environ["HARRY_READING_AGENT_SKIP_CONFIG"] == "1")
print("验证完成。重启 Codex 或开启新会话后即可使用 Harry 个人阅读库 Agent。")
PY
