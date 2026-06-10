# 更新记录

本文件记录 `harry-reading-agent` plugin 的重要变化。

## 未发布 - 2026-06-10

- 移除旧课程版 `plugins/neican-editor-course/`，仓库不再保留内参编辑课程模板内容。
- 移除旧配置模板 `config/neican-editor.example.json`，避免与 `harry-reading-agent` 当前配置口径混淆。

## 0.1.0 - 2026-06-10

- 新增 `daily-reads-import` skill：按 `Asia/Shanghai` 前一天日期查询源「serious AI 阅读库｜reads」的 `日报期数`，复制到 Harry 的「阅读库｜reads」，并用目标库 `原文 = 源页面 URL` 去重。
- 新增 `personal-reading-reminder` skill：从目标阅读库筛选同一期且 `标签` 包含 `每日必读` 的文章，生成可复制的阅读提醒文本，链接使用目标阅读库页面 URL。
- 新增 `config/harry-reading-agent.example.json` 配置模板。
- 安装、卸载、校验脚本改为默认处理 `harry-reading-agent`。
- README、安装说明、配置说明和安全边界改为个人阅读库口径。
- 配置字段拆分为 `fields.sourceIssueDate` 和 `fields.targetIssueDate`，适配源库按 `日报期数` 查询、目标库按 `收录日期` 生成提醒。
