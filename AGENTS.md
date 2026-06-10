# 协作规则

本仓库当前维护 Harry 的个人阅读库 Codex plugin：`harry-reading-agent`。

## 文档语言

所有面向 Codex / agent / skill / plugin 的文档默认使用中文。命令名、路径、配置键和 API 名称可以保留英文。

## 维护边界

- 默认维护 `plugins/harry-reading-agent/`。
- 旧课程版 `plugins/neican-editor-course/` 已从仓库移除，不再作为维护对象；需要参考时查历史提交。
- 不加入网站发布 skill、公开站部署、搜索索引或任何网站发布逻辑。
- 不把真实 Notion / Readwise 配置写入 repo。
- 不把 Folo token、Folo session 或任何登录凭证写入 repo。
- 不提交 `config/harry-reading-agent.json`。
- 维护插件能力更新时，同步更新 README 的更新记录和 `CHANGELOG.md`。

## 修改后验收

每次修改后至少运行：

```bash
./scripts/verify-install.sh --scan-only
```

如果改了安装脚本，再用临时 HOME 做一次安装验证：

```bash
TMP_HOME="$(mktemp -d)"
HOME="$TMP_HOME" ./scripts/install-codex.sh
HOME="$TMP_HOME" ./scripts/verify-install.sh --skip-config
```
