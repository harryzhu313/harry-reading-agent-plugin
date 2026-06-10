#!/usr/bin/env bash
set -euo pipefail

ORG="${1:-candobear}"
REPO="${2:-harry-reading-agent-plugin}"
TEAM="${3:-readers}"

echo "检查 GitHub 访问配置: org=$ORG repo=$REPO team=$TEAM"
gh repo view "$ORG/$REPO" --json name,visibility,url
gh api "repos/$ORG/$REPO/teams" --jq ".[] | select(.slug==\"$TEAM\") | {name: .name, slug: .slug, permission: .permission}"
echo "如果 permission=pull，学员 team 即为只读。"
