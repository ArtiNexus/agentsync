#!/bin/bash
# AgentSync · 安装脚本
# 人跑或 Agent 跑，都一样。一个命令装好，下次启动自动生效。
#
# 安装: curl -fsSL <url>/install.sh | bash
# 或:   git clone <repo> && bash install.sh

set -e

INSTALL_DIR="${AGENTSYNC_HOME:-$HOME/.agentsync}"
VERSION="0.1.0"
REPO="https://github.com/your-org/agentsync"

echo "═══════════════════════════════════"
echo "  AgentSync v$VERSION · 安装中..."
echo "═══════════════════════════════════"
echo ""

# ── 1. 复制文件 ──
mkdir -p "$INSTALL_DIR"/{hooks,models/profiles}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 如果是从线上安装（curl | bash），本地没有源文件，从 GitHub 下载
if [ ! -f "$SCRIPT_DIR/agent-sync.sh" ]; then
    echo "📡 从 GitHub 下载..."
    TMPDIR=$(mktemp -d)
    git clone --depth 1 "$REPO" "$TMPDIR" 2>/dev/null || {
        echo "❌ 下载失败。请检查网络或手动安装。"
        echo "   手动: git clone $REPO && cd agentsync && bash install.sh"
        exit 1
    }
    cp "$TMPDIR"/agent-sync.sh "$INSTALL_DIR/"
    cp "$TMPDIR"/hooks/*.sh "$INSTALL_DIR/hooks/"
    cp "$TMPDIR"/models/*.md "$TMPDIR"/models/*.yaml "$INSTALL_DIR/models/" 2>/dev/null || true
    rm -rf "$TMPDIR"
else
    cp "$SCRIPT_DIR"/agent-sync.sh "$INSTALL_DIR/"
    cp "$SCRIPT_DIR"/hooks/*.sh "$INSTALL_DIR/hooks/" 2>/dev/null || true
    cp "$SCRIPT_DIR"/models/*.md "$SCRIPT_DIR"/models/*.yaml "$INSTALL_DIR/models/" 2>/dev/null || true
fi

chmod +x "$INSTALL_DIR"/agent-sync.sh
chmod +x "$INSTALL_DIR"/hooks/*.sh 2>/dev/null || true

echo "✅ 文件已安装到 $INSTALL_DIR"

# ── 2. 检测 Agent 框架，安装挂钩 ──
HOOK_INSTALLED=false

# 检测 pi
if [ -d "$HOME/.pi/agent" ]; then
    echo ""
    echo "🔍 检测到 pi Agent"
    
    # 注入到 AGENTS.md 的启动步骤
    AGENTS_MD="$HOME/.pi/agent/AGENTS.md"
    if [ -f "$AGENTS_MD" ]; then
        if ! grep -q "agent-sync" "$AGENTS_MD" 2>/dev/null; then
            # 在 Step 1 之后插入 AgentSync 步骤
            # 简单策略：追加到文件末尾作为一个 section
            cat >> "$AGENTS_MD" << 'PIHOOK'

---

## AgentSync · 自动适配层

> 此段由 `install.sh` 自动添加。每次会话启动时自动为当前模型适配。

```bash
~/.agentsync/agent-sync.sh adapt 2>/dev/null
```

> 适配指令已自动加载到 `~/.models/ADAPT.md`。
PIHOOK
            echo "✅ pi 挂钩已添加"
        else
            echo "   (已安装过，跳过)"
        fi
    fi
    HOOK_INSTALLED=true
fi

# 检测 Claude Code
if [ -d "$HOME/.claude" ]; then
    echo ""
    echo "🔍 检测到 Claude Code"
    
    CLAUDE_CONFIG="$HOME/.claude/config.json"
    if [ -f "$CLAUDE_CONFIG" ]; then
        echo "   请在 $HOME/.claude/claude.md 或你的启动指令中加入："
        echo "   bash ~/.agentsync/agent-sync.sh adapt"
    else
        echo "   Claude Code 挂钩需手动添加。详见 hooks/README.md"
    fi
    HOOK_INSTALLED=true
fi

# 通用挂钩
if [ "$HOOK_INSTALLED" = false ]; then
    echo ""
    echo "🔍 未检测到已知 Agent 框架（pi / Claude Code）"
    echo "   通用安装：把下面这行加到你的 Agent 启动脚本里："
    echo ""
    echo "   bash ~/.agentsync/agent-sync.sh adapt"
    echo ""
    echo "   详见: ~/.agentsync/hooks/README.md"
fi

# ── 3. 创建符号链接，方便直接调用 ──
ln -sf "$INSTALL_DIR/agent-sync.sh" "$HOME/.local/bin/agent-sync" 2>/dev/null || {
    mkdir -p "$HOME/.local/bin" 2>/dev/null
    ln -sf "$INSTALL_DIR/agent-sync.sh" "$HOME/.local/bin/agent-sync" 2>/dev/null || true
}

echo ""
echo "═══════════════════════════════════"
echo "  ✅ AgentSync v$VERSION 安装完成"
echo ""
echo "  下次 Agent 启动时自动生效。"
echo "  手动测试: agent-sync status"
echo "═══════════════════════════════════"
