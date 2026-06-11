---
name: personal-reading-reminder
description: 用于 Harry 手动生成个人阅读提醒。当用户说“生成阅读提醒”“生成今日阅读提醒”“生成阅读分享”等类似指令时使用；从 Harry 的「阅读库｜reads」中筛选「标签」包含「每日必读」的文章，输出可直接复制到 Telegram / 微信 / 群聊的纯文本，不修改数据库。
---

# 个人阅读提醒 skill

## 使用场景

Harry 在个人阅读库里给文章打上 `每日必读` 标签后，手动说“生成阅读提醒”。此 skill 只读取 Harry 的「阅读库｜reads」，把命中的文章整理成可复制文本。

## 核心原则

- 只读目标阅读库，不修改任何数据库字段、页面内容、标签或 relation。
- 默认筛选同一期 `日报期数`，避免把历史 `每日必读` 全部拉出来。
- 默认日期为 `Asia/Shanghai` 当前日期的前一天；如果用户指定日期，则按指定日期筛选。
- 文章必须来自 Harry 的「阅读库｜reads」目标库。
- 最终链接放目标阅读库页面 URL，不放源 serious AI 页面 URL，也不放文章外部原文 URL。
- 命中 N 篇文章，输出 N 条；不要因为作者、番茄或阅读理由为空而丢弃文章。
- 输出为纯文本代码块，方便直接复制。

## 配置项

执行前读取：

```text
~/.codex/harry-reading-agent/config.json
```

必需配置：

| 项目 | 配置键 |
|---|---|
| 时区 | `timezone` |
| 目标阅读库 data source | `notion.targetReadsDataSourceId` |
| 目标阅读库页面 URL 前缀 | `notion.targetReadsDatabaseUrl` |
| 标题字段 | `fields.title` |
| 作者字段 | `fields.author` |
| 日期字段 | `fields.targetIssueDate` |
| 标签字段 | `fields.tags` |
| 每日必读标签 | `fields.dailyMustReadTag` |
| 注意力番茄字段 | `fields.tomato` |
| 阅读理由字段 | `fields.readingReason` |
| 策展人名称 | `brand.curatorName` |

## Notion CLI 认证预检

查询前先确认当前执行环境能访问 Notion CLI 凭据：

```bash
./scripts/notion-auth-check.sh
```

如果当前不在 repo 根目录，或脚本不可用，则至少运行：

```bash
ntn whoami -v
ntn doctor
```

判断规则：

- `ntn doctor` 可用于查看 CLI 配置，但它在 `no token found` 时仍可能返回成功状态；不得只凭 `ntn doctor` 判断 Harry 未登录。
- 如果 `./scripts/notion-auth-check.sh` 输出 `status=ok`，或 `ntn whoami -v` 成功，才继续查询目标阅读库。
- 如果输出 `status=sandbox-keychain-blocked`，或 `ntn whoami -v` 提到 `seatbelt sandbox` / `keychain access`，不要说 Harry 没有登录；应说明当前 Codex 沙箱无法访问 macOS Keychain 中的 `ntn` 凭据。若当前 Codex 支持权限升级，按 Codex 规则请求在沙箱外重跑 Notion CLI；否则让 Harry 切换到可访问 Keychain 的真实环境，或改用文件认证方案 `NOTION_KEYRING=0 ntn login`。
- 如果输出 `status=sandbox-network-disabled`，不要说 Harry 没有登录；应说明当前 Codex 沙箱禁用了网络，Notion API 查询需要网络权限。
- 只有在非沙箱环境或 `ntn whoami -v` 明确显示未登录时，才要求 Harry 先完成 `ntn login`。

## 工作流

### 1. 解析提醒日期

1. 如果用户说了具体日期或日报期数，使用用户指定值。
2. 如果用户只说“生成阅读提醒 / 今日阅读提醒”，按配置时区取当前日期的前一天。
3. 日期统一为 `YYYY-MM-DD`，用于匹配 `fields.targetIssueDate`。

### 2. 查询目标阅读库

用 Notion CLI 查询 `notion.targetReadsDataSourceId`：

- `fields.targetIssueDate` 等于提醒日期。
- `fields.tags` 包含 `fields.dailyMustReadTag`，默认 `每日必读`。

按目标库查询返回顺序输出；不要按标题、分数或主观判断重排。

如果没有命中，输出：

```text
今日暂无每日必读文章。
```

并简要说明使用的筛选日期。

### 3. 读取文章属性

每篇文章读取：

- 标题：优先 `fields.title`，没有时用页面 title。
- 作者 / 来源：读取 `fields.author`，为空则省略。
- 注意力番茄：读取 `fields.tomato`，为空则省略。
- 阅读理由：读取 `fields.readingReason`，为空则省略，不编造。
- 目标阅读库页面 URL：用目标页面 page id 构造真实 Notion URL。

不得使用源页面 URL、`source link`、外部原文链接或 canonical URL 替代目标阅读库页面 URL。

### 4. 输出前校验

- 查询命中数量 N 必须等于准备输出的阅读项数量。
- 每条阅读项第二行必须是目标阅读库页面 URL。
- 没有作者、番茄或阅读理由时，只省略对应字段，不删除文章。
- 不输出 Markdown 链接格式。

### 5. 生成消息文本

严格按以下格式输出代码块：

```text
📰 今日份阅读

今日阅读已更新 👇
[提醒日期]

📚 今日必读（[文章数量] 篇）：
• 《文章标题》— 作者 / 来源 · 注意力番茄
  [目标阅读库页面 URL]
  阅读理由：[阅读理由]
• 《文章标题》
  [目标阅读库页面 URL]

—— by  harry
```

格式规则：

- 每篇文章至少两行：标题行 + 目标阅读库页面 URL。
- 作者为空时省略 `— 作者 / 来源`。
- 注意力番茄为空时省略 `· 注意力番茄`。
- 阅读理由为空时省略阅读理由行。
- 如果只有 1 篇，标题仍写 `📚 今日必读（1 篇）：`。
- 代码块后附一句：`✅ 已生成，可直接复制粘贴到 Telegram / 微信。`

## 收尾汇报

代码块后简短说明：

- 使用的日报期数 / 日期。
- 命中 `每日必读` 的文章数。
- 如有字段缺失，列出缺作者、缺番茄、缺阅读理由的数量。
