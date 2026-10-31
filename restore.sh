#!/bin/sh
# 从本仓库 config/ 恢复 pi 核心配置（暴力覆盖受管路径），并安装 settings 里的扩展包
# 受管路径：settings.json / mcp-cache.json / skills/ / AGENTS.md 等 / extensions|prompts|themes
# 绝不触碰：auth.json、sessions/、npm/、models-store.json
set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"
CFG="$REPO/config"
PI_DIR="$HOME/.pi/agent"
SKILLS_DST="$HOME/.agents/skills"

cd "$REPO"
if ! git pull --ff-only; then
  printf 'git pull 失败（网络或本地改动）？继续用本地仓库内容恢复? [y/N] '
  read -r ans
  [ "$ans" = "y" ] || exit 1
fi

mkdir -p "$PI_DIR"

rsync -a "$CFG/settings.json" "$PI_DIR/"
if [ -f "$CFG/mcp-cache.json" ]; then
  rsync -a "$CFG/mcp-cache.json" "$PI_DIR/"
fi
rsync -a --delete --exclude='.DS_Store' "$CFG/skills/" "$SKILLS_DST/"

# 非空才恢复，避免把占位空文件写进本地
for f in AGENTS.md SYSTEM.md APPEND_SYSTEM.md keybindings.json; do
  if [ -s "$CFG/$f" ]; then
    rsync -a "$CFG/$f" "$PI_DIR/"
  fi
done

for d in extensions prompts themes; do
  if [ -d "$CFG/$d" ]; then
    rsync -a --delete --exclude='.gitkeep' --exclude='.DS_Store' "$CFG/$d/" "$PI_DIR/$d/"
  fi
done

# 按恢复后的 settings.json 逐个安装扩展包（pi 没有全量安装命令）
PI="$PI_DIR/bin/pi"
if [ ! -x "$PI" ]; then
  PI="$(command -v pi || true)"
fi
if [ -n "$PI" ]; then
  sed -n '/"packages"/,/]/p' "$PI_DIR/settings.json" \
    | grep -oE '"[^"]+"' | grep -v '"packages"' | tr -d '"' \
    | while read -r src; do
        [ -n "$src" ] || continue
        echo "安装 $src ..."
        "$PI" install "$src" || echo "  安装失败: $src（稍后手动 pi install $src）" >&2
      done
else
  echo "未找到 pi 可执行文件，跳过扩展安装" >&2
fi

echo "恢复完成，重启 pi 会话生效"
