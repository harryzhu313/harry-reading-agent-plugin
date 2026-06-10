---
name: daily-reads-import
description: 用于每天从「serious AI 阅读库｜reads」按前一天的「日报期数」抓取文章，并复制到 Harry 的「阅读库｜reads」。当用户说“同步昨日阅读库”“导入前一天日报文章”“抓取昨天日报内容”等类似指令时使用；源库只读，所有写入只发生在目标阅读库。
---

# 每日阅读库同步 skill

## 使用场景

每天凌晨由 Codex automation 或 Harry 手动触发。此 skill 从「serious AI 阅读库｜reads」读取前一天日报期数对应的文章，并复制到 Harry 的「阅读库｜reads」。

核心边界：

- 源库只读，不编辑「serious AI 阅读库｜reads」的页面、属性、schema、relation 或评论。
- 目标库可写，只在 Harry 的「阅读库｜reads」中新建或更新文章页面。
- 默认按 `Asia/Shanghai` 的前一天日期过滤 `日报期数`。
- 去重使用目标库字段 `原文`，其值必须等于源页面的 Notion URL。
- 不写真实 Notion ID。所有 data source、字段名和 URL 口径从 `~/.codex/harry-reading-agent/config.json` 读取。

## 配置项

执行前读取配置，优先使用安装后的文件：

```text
~/.codex/harry-reading-agent/config.json
```

在 repo 内调试时可使用：

```text
config/harry-reading-agent.json
```

必需配置：

| 项目 | 配置键 |
|---|---|
| 时区 | `timezone` |
| 源阅读库 data source | `notion.sourceReadsDataSourceId` |
| 目标阅读库 data source | `notion.targetReadsDataSourceId` |
| 目标阅读库页面 URL 前缀 | `notion.targetReadsDatabaseUrl` |
| 源日期字段 | `fields.sourceIssueDate` |
| 目标日期字段 | `fields.targetIssueDate` |
| 标题字段 | `fields.title` |
| 去重/源页面链接字段 | `fields.sourcePageUrl` |
| 标签字段 | `fields.tags` |
| 阅读理由字段 | `fields.readingReason` |
| 进度字段 | `fields.progress` |
| 完成进度值 | `fields.progressDoneValue` |

## 工具分工

- 优先用 Notion CLI（`ntn datasources query` / `ntn api`）查询 data source、读取页面属性、创建或更新目标页面。
- 用 Notion MCP / Connector fetch 源页面正文，保留 enhanced Markdown 结构、图片和 tabs。
- 不依赖 `notion-query-data-sources`。如果工具 schema 出现但运行不可用，不要切换到它作为主路径。

执行前先确认：

```bash
ntn doctor
```

如果 token 无效，停止并要求 Harry 先完成 `ntn login`。

## 工作流

### 1. 解析导入日期

1. 如果用户显式给出日期，使用该日期。
2. 如果用户只说“昨日 / 前一天 / 自动同步”，按配置 `timezone` 计算当前日期的前一天。
3. 日期格式统一为 `YYYY-MM-DD`，作为源库 `日报期数` 的匹配值。

### 2. 查询源阅读库

用 Notion CLI 查询 `notion.sourceReadsDataSourceId`：

- 条件：`fields.sourceIssueDate` 等于导入日期。
- 排序：优先保持 Notion 查询返回顺序；不要按标题或主观重要性重排。
- 查询结果为 0 时，只汇报“没有找到该日报期数的源文章”，不要写目标库。

每个源页面必须读取：

- 全部属性。
- 源页面 URL。
- 页面正文 enhanced Markdown。
- 图片、callout、tabs 等结构。

### 3. 定位或创建目标文章

对每篇源文章：

1. 构造源页面真实 Notion URL。
2. 在目标阅读库中查询 `fields.sourcePageUrl` 是否等于源页面 URL。
3. 已存在：更新该页面。
4. 不存在：新建页面，图标可沿用源页面图标；没有图标时选择一个与标题主题匹配的 emoji。

不要使用标题作为唯一去重依据；标题只能作为辅助诊断。

### 4. 复制属性并覆写特定字段

默认规则：

- 源页面存在且目标库也存在的同名字段，尽量原样复制。
- 源页面为空的字段，目标也留空，不猜测。
- select / multi_select 目标库缺少选项时，可直接新增；写入后必须检查是否出现 `Invalid multi_select value` 或部分写入 warning。

必须覆写：

| 目标属性 | 规则 |
|---|---|
| `fields.sourcePageUrl` | 写入源页面 Notion URL |
| `fields.progress` | 写入 `fields.progressDoneValue`，默认 `3.1 已笔记+概念` |
| `fields.dailyDeepRead` | 留空 |
| `fields.targetIssueDate` | 写入导入日期 |
| `fields.readingReason` | 如果配置或源页面有明确阅读理由则写入；否则留空 |
| `fields.conceptIngested` | 写入 `true` |
| `fields.actionRelation` | 留空，不复制源页面行动库 relation |
| `fields.ideaRelation` | 留空，不复制源页面思想库 relation |

不要修改源页面的任何字段。

### 5. 复制页面正文

把源页面正文完整复制到目标页面：

- 保留文字、标题、列表、图片、callout、quote、divider。
- 保留 `<tabs>` 结构，不重写、不简化 tabs 标签名。
- 对 `<tab>` 块逐行保留：
  - `<tabs>`
  - `<tab>`
  - `<tab>` 第一行标签名
  - tab 内正文
  - `</tab>`
  - `</tabs>`

如果源页面正文包含 tabs，复制后必须检查目标页面的 tabs 标签名没有丢 emoji、没有被简化为英文裸词。

### 6. 验证

完成前逐项验证：

- 源文章数量 = 目标处理数量，除非有明确跳过原因。
- 每篇目标页 `fields.sourcePageUrl` 等于源页面 URL。
- 重跑同一天不会创建重复页面。
- `fields.targetIssueDate` 等于导入日期。
- `fields.progress` 等于 `fields.progressDoneValue`。
- `fields.conceptIngested` 已勾选。
- 图片和正文结构已保留。
- 若存在 tabs，目标页 tabs 标签名与源页面一致。

## 收尾汇报

简要汇报：

- 导入日期。
- 源文章数。
- 新建数、更新数、跳过数。
- 失败项标题和原因。
- 是否存在字段缺失或正文复制警告。
