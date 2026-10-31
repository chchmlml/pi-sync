#!/bin/sh
# 备份 pi 核心配置到本仓库 config/，并 commit + push（对应 pi 1.4.0 目录布局）
set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"
CFG="$REPO/config"
PI_DIR="$HOME/.pi/agent"
SKILLS_SRC="$HOME/.agents/skills"

mkdir -p "$CFG/skills" "$CFG/extensions" "$CFG/prompts" "$CFG/themes"

# 必备文件（mcp-cache.json 是纯缓存，pi 连上 MCP 服务器会自动生成，不备份）
rsync -a "$PI_DIR/settings.json" "$CFG/"

# 技能目录（--delete：仓库跟随本地删除；绝不触碰 ~/.agents 以外路径）
if [ -d "$SKILLS_SRC" ]; then
  rsync -a --delete --exclude='.DS_Store' --exclude='lark-*' --delete-excluded "$SKILLS_SRC/" "$CFG/skills/"
fi

# 可选文件：源存在才覆盖，否则保留仓库里的占位空文件
for f in AGENTS.md SYSTEM.md APPEND_SYSTEM.md keybindings.json; do
  if [ -f "$PI_DIR/$f" ]; then
    rsync -a "$PI_DIR/$f" "$CFG/"
  fi
done

# 可选目录：源存在才同步（--exclude .gitkeep 防止占位文件反向污染本地）
for d in extensions prompts themes; do
  if [ -d "$PI_DIR/$d" ]; then
    rsync -a --delete --exclude='.gitkeep' --exclude='.DS_Store' "$PI_DIR/$d/" "$CFG/$d/"
  fi
done

cd "$REPO"
git add -A
if git diff --cached --quiet; then
  echo "无变更，跳过提交"
  exit 0
fi
git commit -m "backup: $(date '+%Y-%m-%d %H:%M:%S')"
if ! git push; then
  echo "已提交但推送失败，稍后手动 git push" >&2
  exit 1
fi
echo "备份完成"
