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

- Notion CLI：运行 `ntn doctor`，如果 token 无效，先运行 `ntn login`。
- Notion MCP / Connector：Codex 中可以 fetch Notion 页面正文、属性、tabs 和图片。

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
