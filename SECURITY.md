# 安全边界

## 不应进入仓库的内容

- Notion database URL、page URL、data source ID、user ID。
- Readwise、Notion、OpenAI、Anthropic 等服务密钥。
- Folo session token、`FOLO_TOKEN` 或其他登录凭证。
- 本机绝对路径。
- 公开站发布配置和部署密钥。
- Harry 自己的 `config/harry-reading-agent.json`。

## 发布前红线扫描

维护者发布前应运行：

```bash
./scripts/verify-install.sh --scan-only
```

示例配置只能出现 `YOUR_*` 占位符，不能出现真实配置。

## Notion 权限原则

- 源「serious AI 阅读库｜reads」只需要读取权限。
- 目标「阅读库｜reads」需要创建和更新页面的权限。
- 自动同步不得修改源库页面、属性、schema、relation 或评论。
- 阅读提醒 skill 只读目标库，不修改任何数据库内容。
