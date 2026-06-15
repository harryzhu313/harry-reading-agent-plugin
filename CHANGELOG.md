# 更新记录

本文件记录 `harry-reading-agent` plugin 的重要变化。

## 0.1.4 - 2026-06-15

- 修正 `daily-reads-import` 的图片复制口径：Notion 内部 file 图片必须下载二进制并通过 `ntn files create` 上传为目标页 file image，不能把临时 S3 签名 URL 当作已复制图片。
- 要求同步后复查目标 image block 类型；目标图片必须是 `image.type = file` 且有非空 file URL，空 external URL 或临时签名外链视为失败。
- 将 plugin manifest 版本升级为 `0.1.4`，避免继续命中 `0.1.3` cache。

## 0.1.3 - 2026-06-15

- 回滚 `daily-reads-import` 的强制 Notion Connector 依赖，恢复 Notion CLI-only 同步路径。
- 明确 Connector 对源库、目标库或页面返回 `object_not_found` 时不应阻塞同步。
- 图片、文件媒体和 tabs 校验改为基于 CLI / API 可见结构；无法完整验证时在收尾汇报中标记 warning。
- 将 plugin manifest 版本升级为 `0.1.3`，避免继续命中 `0.1.2` cache。

## 0.1.2 - 2026-06-14

- 收紧 `daily-reads-import` 的图片同步规则：页面正文读取、写入和图片 / tabs 校验必须使用当前 Codex 会话中的 Notion MCP / Connector。
- 新增 Connector 预检要求：当前会话必须能 fetch 源/目标 Notion 页面或 data source，并具备目标正文创建或更新能力。
- 明确禁止在 Connector 不可用或图片写入失败时静默降级为纯文字同步。
- 要求同步后重新 fetch 目标页面，按源/目标图片数量验证正文复制结果，并在收尾汇报中列出图片校验状态。
- 将 plugin manifest 版本升级为 `0.1.2`，避免其他设备继续复用旧 `0.1.1` cache。

## 0.1.1 - 2026-06-12

- 新增 `scripts/notion-auth-check.sh`，用于区分 Notion CLI 真实未登录、Codex 沙箱无法访问 Keychain、以及沙箱网络禁用。
- 更新 `daily-reads-import` 和 `personal-reading-reminder` 的 Notion CLI 预检规则，避免只凭 `ntn doctor` 误判 Harry 未登录。
- 更新安装说明，补充 `NOTION_KEYRING=0 ntn login` 与 Codex 用户级 `shell_environment_policy` / `sandbox_workspace_write.network_access` 配置口径。
- 将 plugin manifest 版本升级为 `0.1.1`，避免 Codex 继续复用旧 `0.1.0` cache。
- 强化 `verify-install.sh`：校验已安装目录和 Codex cache 的关键文件必须与源码一致，并检查安装包不再残留旧课程插件。
- 移除旧课程版 `plugins/neican-editor-course/`，仓库不再保留内参编辑课程模板内容。
- 移除旧配置模板 `config/neican-editor.example.json`，避免与 `harry-reading-agent` 当前配置口径混淆。

## 0.1.0 - 2026-06-10

- 新增 `daily-reads-import` skill：按 `Asia/Shanghai` 前一天日期查询源「serious AI 阅读库｜reads」的 `日报期数`，复制到 Harry 的「阅读库｜reads」，并用目标库 `原文 = 源页面 URL` 去重。
- 新增 `personal-reading-reminder` skill：从目标阅读库筛选同一期且 `标签` 包含 `每日必读` 的文章，生成可复制的阅读提醒文本，链接使用目标阅读库页面 URL。
- 新增 `config/harry-reading-agent.example.json` 配置模板。
- 安装、卸载、校验脚本改为默认处理 `harry-reading-agent`。
- README、安装说明、配置说明和安全边界改为个人阅读库口径。
- 配置字段拆分为 `fields.sourceIssueDate` 和 `fields.targetIssueDate`，适配源库按 `日报期数` 查询、目标库按 `收录日期` 生成提醒。
