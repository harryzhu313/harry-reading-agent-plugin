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

## 自动化

插件本身不常驻后台。每天凌晨运行需要 Codex automation 或其他调度器唤起 `daily-reads-import`。推荐每天 `01:00 Asia/Shanghai` 执行一次。
