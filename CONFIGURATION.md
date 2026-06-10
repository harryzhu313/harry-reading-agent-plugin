# 配置说明

示例配置文件是 `config/harry-reading-agent.example.json`。如果你在 repo 内调试，可以复制为 `config/harry-reading-agent.json`；这个本地文件会被 `.gitignore` 忽略。

安装后，实际运行时优先使用：

```text
~/.codex/harry-reading-agent/config.json
```

## 必填配置

| 区域 | 字段 | 含义 |
|---|---|---|
| `notion` | `sourceReadsDataSourceId` | 「serious AI 阅读库｜reads」data source ID |
| `notion` | `sourceReadsDatabaseUrl` | 源阅读库 URL 口径，用于构造真实页面链接 |
| `notion` | `targetReadsDataSourceId` | Harry「阅读库｜reads」data source ID |
| `notion` | `targetReadsDatabaseUrl` | 目标阅读库 URL 口径，用于构造真实页面链接 |
| `notion` | `curatorUserId` | 如需写入 people 字段时使用的 Notion 用户 ID |
| `fields` | `sourceIssueDate` | 源库用于判断日报期数的字段，默认 `日报期数` |
| `fields` | `targetIssueDate` | 目标库用于筛选提醒日期的字段，默认 `收录日期` |
| `fields` | `sourcePageUrl` | 目标库中保存源页面 URL 的字段，默认 `原文` |
| `fields` | `tags` | 标签字段，必须是 multi_select |
| `fields` | `dailyMustReadTag` | 生成提醒时筛选的标签值，默认 `每日必读` |
| `fields` | `readingReason` | 阅读提醒中使用的理由字段，默认 `阅读理由` |
| `fields` | `progress` | 入库后更新的进度字段 |
| `fields` | `progressDoneValue` | 入库后写入的进度值，默认 `3.1 已笔记+概念` |

## 配置原则

- 配置文件里可以填你的真实 Notion ID 和字段名，但不要提交。
- `config/harry-reading-agent.example.json` 只能保留 `YOUR_*` 占位符。
- `sourceIssueDate` 是同步源库的日期门禁；`targetIssueDate` 是目标库生成阅读提醒的日期门禁。
- 目标库去重字段是 `原文`，写入源 serious AI 页面 URL。
- 阅读提醒链接使用目标阅读库页面 URL，不使用源页面 URL 或外部原文 URL。

## Notion Data Source ID

推荐用 Notion CLI 解析数据库：

```bash
ntn datasources resolve <你的 Notion database URL>
```

把返回的 data source ID 填进本机配置文件。不要把 database URL 当作 data source ID。

## 每日同步默认口径

```json
{
  "timezone": "Asia/Shanghai",
  "import": {
    "lookbackDays": 1,
    "dedupeField": "原文"
  }
}
```

每天 `01:00 Asia/Shanghai` 运行时，默认查询前一天的 `日报期数`。

## 阅读提醒默认口径

```json
{
  "reminder": {
    "lookbackDays": 1,
    "requiredTag": "每日必读",
    "linkTarget": "target_page"
  }
}
```

当你说“生成阅读提醒”时，默认查询前一天 `日报期数` 且 `标签` 包含 `每日必读` 的目标阅读库文章。
