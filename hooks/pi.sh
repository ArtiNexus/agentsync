#!/bin/bash
# AgentSync · pi 框架挂钩
# 被 install.sh 调用，或手动运行。

PI_DIR="$HOME/.pi"
AGENTS_MD="$PI_DIR/agent/AGENTS.md"
AGENTSYNC="$HOME/.agentsync/agent-sync.sh"

echo "pi Agent 挂钩安装..."
if [ -f "$AGENTS_MD" ]; then
    if grep -q "agent-sync" "$AGENTS_MD" 2>/dev/null; then
        echo "  已安装，跳过"
    else
        echo "" >> "$AGENTS_MD"
        echo "## AgentSync · 模型自动适配" >> "$AGENTS_MD"
        echo "> 每次会话启动时自动运行: bash $AGENTSYNC adapt" >> "$AGENTS_MD"
        echo "bash $AGENTSYNC adapt 2>/dev/null || true" >> "$AGENTS_MD"
        echo "✅ 已注入 AGENTS.md"
    fi
else
    echo "❌ 未找到 AGENTS.md。请在 pi 启动脚本中手动加入:"
    echo "   bash $AGENTSYNC adapt"
fi
