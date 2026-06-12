# Harry 个人阅读库 Agent

这是 Harry 的个人阅读库 Codex plugin 发布包。它用于把「serious AI 阅读库｜reads」中前一天日报期数对应的文章同步到 Harry 的「阅读库｜reads」，并在手动触发时生成「每日必读」阅读提醒文本。

## 更新记录

- `0.1.1`：补充 Notion CLI 在 Codex 沙箱中的 Keychain / 网络诊断，新增 `scripts/notion-auth-check.sh`，并强化安装一致性校验。
- `0.1.1`：移除旧课程版 `plugins/neican-editor-course/` 和 `config/neican-editor.example.json`，仓库只保留 Harry 个人阅读库 Agent。
- `0.1.0`：新增个人阅读库同步与阅读提醒两个 skill，安装目标改为 `harry-reading-agent`。

完整记录见 `CHANGELOG.md`。

## 快速安装

```bash
git clone <PRIVATE_REPO_URL>
cd harry-reading-agent-plugin
./scripts/install-codex.sh
# 编辑 ~/.codex/harry-reading-agent/config.json，填入你自己的 Notion 配置
./scripts/verify-install.sh
```

安装后重启 Codex 或开启新会话，再尝试：

```text
同步昨日阅读库
生成阅读提醒
```

## 这个仓库包含什么

- `plugins/harry-reading-agent/`：当前默认安装的 Codex plugin。
- `config/harry-reading-agent.example.json`：本机配置模板。
- `scripts/install-codex.sh`：安装到当前用户的 Codex Personal Plugin。
- `scripts/verify-install.sh`：验证 marketplace、config、cache 三层安装状态，并检查安装目录与源码关键文件一致。
- `scripts/notion-auth-check.sh`：诊断当前 Codex 执行环境能否访问 Notion CLI 凭据和网络。
- `scripts/uninstall-codex.sh`：卸载 Harry 个人阅读库 Agent。

## 不包含什么

- 不包含真实 Notion database URL、data source ID、Notion user ID。
- 不包含任何服务密钥、Folo token 或本机绝对路径。
- 不包含公开站部署、搜索索引更新或网站发布逻辑。

详细安装见 `INSTALL.md`，配置见 `CONFIGURATION.md`，安全边界见 `SECURITY.md`。
