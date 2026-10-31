# pi-sync

备份和恢复 pi 核心配置（针对 pi 1.4.0 目录布局），备份数据存放在本仓库 `config/`。

## 备份内容

| 仓库路径 | 本机路径 |
|---|---|
| `config/settings.json` | `~/.pi/agent/settings.json` |
| `config/mcp/mcp.json` | `~/.config/mcp/mcp.json`（共享 MCP 配置） |
| `config/skills/` | `~/.agents/skills/`（排除 `lark-*`） |
| `config/AGENTS.md` 等占位文件 | `~/.pi/agent/AGENTS.md`、`SYSTEM.md`、`APPEND_SYSTEM.md`、`keybindings.json`（出现后自动纳入） |
| `config/extensions/` `prompts/` `themes/` | `~/.pi/agent/` 下同名目录（出现后自动纳入） |

**不备份**：`auth.json`（凭据）、`sessions/`、`npm/`、`models-store.json`、`mcp-cache.json`（机器生成/纯缓存，pi 会自动重建）、`lark-*` 技能（restore 不会动本地 lark 技能）。

## 用法

```sh
./backup.sh   # rsync 配置到 config/ + commit + push
./restore.sh  # git pull + 覆盖恢复受管路径 + 按 settings.json 逐个 pi install
```

## 新机器恢复

```sh
git clone https://github.com/chchmlml/pi-sync.git
cd pi-sync && ./restore.sh
```

## 注意

- `restore.sh` 会**暴力覆盖**受管路径：`skills/` 使用 `rsync --delete`，本地多出的技能会被删除。
- `auth.json` 恢复后需单独配置（`pi auth` / 各 provider 登录）。
- 恢复后重启 pi 会话生效。
