# Harry 个人阅读库 Agent

这个 Codex plugin 服务 Harry 的个人阅读工作流：

```text
serious AI 阅读库｜reads
  -> 按前一天的「日报期数」筛选
  -> 复制到 Harry 的「阅读库｜reads」
  -> Harry 手动给文章打「每日必读」标签
  -> 生成可复制的阅读提醒文本
```

## Skills

- `daily-reads-import`：从源阅读库按日报期数同步文章到目标阅读库。
- `personal-reading-reminder`：读取目标阅读库中带 `每日必读` 标签的文章，生成阅读提醒文本。

## 配置

安装后填写：

```text
~/.codex/harry-reading-agent/config.json
```

不要把真实 Notion data source ID、页面 URL、用户 ID 或 token 写进仓库。

## Notion CLI 认证

执行同步或提醒前，优先用仓库脚本检查当前 Codex 环境：

```bash
./scripts/notion-auth-check.sh
```

如果脚本提示 `sandbox-keychain-blocked`，不要重新登录；这通常表示 Codex 沙箱无法访问 macOS Keychain 中已有的 `ntn` 凭据。手动执行时切换到可访问 Keychain 的真实环境；自动化执行建议使用 `NOTION_KEYRING=0 ntn login` 的文件认证方案，并在 Codex 用户配置中传入 `NOTION_KEYRING=0`。

## Notion Connector 正文同步

文章正文、图片和 tabs 的复制依赖当前 Codex 会话里的 Notion MCP / Connector。执行 `daily-reads-import` 时，必须能用 Connector fetch 源页面正文，并用 Connector 创建或更新目标页面正文；如果当前会话没有这些工具或没有源/目标页面权限，应停止同步，不要降级成只复制文字。

## 自动化

插件本身不常驻后台。每天凌晨运行需要 Codex automation 或其他调度器唤起 `daily-reads-import`。推荐每天 `01:00 Asia/Shanghai` 执行一次。
