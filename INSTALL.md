# 安装说明

## 1. 克隆仓库

```bash
git clone <PRIVATE_REPO_URL>
cd harry-reading-agent-plugin
```

如果你是在 Codex 里打开这个仓库，可以直接说：

```text
请读取 AGENTS.md，并安装这个 repo 里的 Harry 个人阅读库 Agent。
```

## 2. 准备配置

配置模板在：

```text
config/harry-reading-agent.example.json
```

安装脚本会准备一份本机运行配置：

```text
~/.codex/harry-reading-agent/config.json
```

安装后打开这份本机配置，把所有 `YOUR_*` 占位符替换成你自己的 Notion 配置。不要把真实配置提交到 Git。

## 3. 确认工具登录

至少需要：

- Notion CLI：运行 `./scripts/notion-auth-check.sh`，确认当前 Codex 执行环境能访问 `ntn` 凭据和 Notion API 网络。
- Notion MCP / Connector：Codex 中可以 fetch Notion 页面正文、属性、tabs 和图片。

不要只看 `ntn doctor`。在 Codex 的 `seatbelt` 沙箱里，`ntn doctor` 可能显示 `no token found` 但仍返回成功状态；这通常不是 Harry 没登录，而是沙箱进程无法访问 macOS Keychain。

如果 `./scripts/notion-auth-check.sh` 输出：

- `status=ok`：可以继续安装和使用。
- `status=sandbox-keychain-blocked`：当前 Codex 沙箱看不到 Keychain 里的 `ntn` 登录凭据。手动执行时，切换到可访问 Keychain 的真实环境，或允许 Notion CLI 命令在沙箱外运行。
- `status=sandbox-network-disabled`：当前 Codex 沙箱禁用了网络，Notion API 查询需要网络权限。
- `status=not-logged-in`：当前环境确实没有可用凭据，先运行 `ntn login`。

自动化运行建议改用文件认证，避免 Keychain 在沙箱里不可见：

```bash
NOTION_KEYRING=0 ntn login
```

然后在用户级 Codex 配置 `~/.codex/config.toml` 中显式传入该环境变量，并确保 workspace-write 沙箱允许网络：

```toml
[shell_environment_policy]
inherit = "core"
set = { NOTION_KEYRING = "0" }

[sandbox_workspace_write]
network_access = true
```

`shell_environment_policy` 和 `sandbox_workspace_write.network_access` 是 Codex 用户级配置项，参考 OpenAI Codex 文档：<https://developers.openai.com/codex/config-advanced#shell-environment-policy>。不要把 `NOTION_API_TOKEN`、Folo token 或任何登录凭证写入本仓库。

## 4. 安装 plugin

```bash
./scripts/install-codex.sh
./scripts/verify-install.sh
```

安装脚本会把 plugin 同步到：

- `~/.candobear/plugins/harry-reading-agent/`
- `~/.agents/plugins/marketplace.json`
- `~/.codex/config.toml`
- `~/.codex/harry-reading-agent/config.json`

## 5. 使用

重启 Codex 或开启新会话后，可以使用：

```text
同步昨日阅读库
导入前一天日报文章
生成阅读提醒
生成今日阅读提醒
```

第一次正式写入 Notion 前，建议先让 Codex 只做预检，确认源阅读库、目标阅读库和字段都能读取。

## 6. 定时运行

插件本身不常驻后台。每天凌晨自动同步需要 Codex automation 或其他调度器唤起。推荐使用 Codex automation 每天 `01:00 Asia/Shanghai` 执行：

```text
使用 $daily-reads-import 同步昨日阅读库。
```
