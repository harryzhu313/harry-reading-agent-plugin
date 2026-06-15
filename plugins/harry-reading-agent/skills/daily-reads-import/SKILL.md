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

- 使用 Notion CLI-only 路径（`ntn datasources query` / `ntn api`）查询 data source、读取页面属性、读取页面正文、创建或更新目标页面。
- 不要求当前 Codex 会话具备 Notion MCP / Connector 权限；不得因为 Connector 对源库、目标库或页面返回 `object_not_found` 而停止同步。
- 如果 CLI-only 路径无法完整验证图片、文件媒体块或 tabs，只在收尾汇报中标记正文结构校验 warning，不把 Connector 不可用当作失败原因。
- 不依赖 `notion-query-data-sources`。如果工具 schema 出现但运行不可用，不要切换到它作为主路径。

执行前先做 Notion CLI 认证预检：

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
- 如果 `./scripts/notion-auth-check.sh` 输出 `status=ok`，或 `ntn whoami -v` 成功，才继续读写 Notion。
- 如果输出 `status=sandbox-keychain-blocked`，或 `ntn whoami -v` 提到 `seatbelt sandbox` / `keychain access`，不要说 Harry 没有登录；应说明当前 Codex 沙箱无法访问 macOS Keychain 中的 `ntn` 凭据。若当前 Codex 支持权限升级，按 Codex 规则请求在沙箱外重跑 Notion CLI；否则让 Harry 切换到可访问 Keychain 的真实环境，或改用文件认证方案 `NOTION_KEYRING=0 ntn login`。
- 如果输出 `status=sandbox-network-disabled`，不要说 Harry 没有登录；应说明当前 Codex 沙箱禁用了网络，Notion API 查询需要网络权限。
- 只有在非沙箱环境或 `ntn whoami -v` 明确显示未登录时，才要求 Harry 先完成 `ntn login`。

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
- 用 Notion CLI / Notion API 读取的页面正文。
- 图片、callout、tabs 等结构。
- 源页面图片数量：按 CLI / API 返回的 image、file、external、Markdown 图片引用等可见结构统计，记为 `sourceImageCount`。如果无法可靠统计，标记为“未知”，后续不得声称图片已验证。
- 源页面 image/file 媒体块的真实类型。Notion 内部图片通常是 `image.type = file`，API 返回的 URL 是短期签名下载链接，只能用于当次下载，不能直接写成目标页 external 图片 URL。

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
- CLI / API 能识别的图片相关 Markdown、media tag、文件块语法不得删除、改写为空行或替换成普通链接。
- 不得把 Notion 内部 file 图片的临时 S3 签名 URL 当作“已复制图片”。这类 URL 可能超过 Notion external URL 限制或很快过期，目标页会出现空 external 图片或失效图片。
- 对每个源 image/file 媒体块：
  - 如果源块是 Notion `file`，用当前 API 返回的 file URL 下载二进制内容，再用 `ntn files create --filename <name> --content-type <mime> --json` 上传到目标 workspace，并用 `ntn api /v1/blocks/{block_id} -X PATCH` 把目标 image 块更新为 `file_upload`。
  - 如果源块是稳定公开 `external` URL，可以复制为 external；如果目标 external URL 为空、过长、带 Notion/S3 临时签名参数或无法访问，必须改走二进制上传。
  - 保持源页面中的图片顺序和 caption；图片位于 tabs、callout 或其他嵌套 block 内时也要递归处理。
- 使用 Markdown 创建/替换正文后，必须复查目标 image block。若 Markdown 导入生成了 `image.type = external` 且 `external.url = ""`，或把 Notion file 图片写成临时外链，必须立即用 file upload 替换。
- 保留 `<tabs>` 结构，不重写、不简化 tabs 标签名。
- 对 `<tab>` 块逐行保留：
  - `<tabs>`
  - `<tab>`
  - `<tab>` 第一行标签名
  - tab 内正文
  - `</tab>`
  - `</tabs>`

- 新建页面：用 Notion CLI 创建目标页并写入正文。
- 更新页面：用 Notion CLI 更新目标属性和正文；替换正文前先确认不会误删目标页里的 child page / database。
- 如果 CLI 写入正文时报错，停止处理该文章并记录失败原因。

如果源页面正文包含 tabs，复制后必须检查目标页面的 tabs 标签名没有丢 emoji、没有被简化为英文裸词。

### 6. 验证

完成前逐项验证：

- 源文章数量 = 目标处理数量，除非有明确跳过原因。
- 每篇目标页 `fields.sourcePageUrl` 等于源页面 URL。
- 重跑同一天不会创建重复页面。
- `fields.targetIssueDate` 等于导入日期。
- `fields.progress` 等于 `fields.progressDoneValue`。
- `fields.conceptIngested` 已勾选。
- 用 Notion CLI 重新读取目标页面正文，确认正文结构已保留。
- 若 `sourceImageCount` 可统计，则目标图片数量必须等于源图片数量；如果源页面有图片但目标图片数量更少，该文章视为失败。
- 对源 `image.type = file` 的图片，目标对应 image block 必须是 `image.type = file` 且有非空 file URL；只验证 Markdown 图片数量不算通过。
- 目标 image block 不得出现空 external URL；若存在 `external.url = ""` 或临时签名外链，该文章视为图片复制失败。
- 若 `sourceImageCount` 未知，但源正文显然包含图片或 media 标记，必须在汇报中标记“图片数量未能自动验证”，不得写成“图片已保留”；不要求追加 Connector 复查。
- 若存在 tabs，目标页 tabs 标签名与源页面一致。

## 收尾汇报

简要汇报：

- 导入日期。
- 源文章数。
- 新建数、更新数、跳过数。
- 失败项标题和原因。
- 是否存在字段缺失或正文复制警告。
- 图片校验结果：源图片数、目标图片数、未能自动统计的页面数。
