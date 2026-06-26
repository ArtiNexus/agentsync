#!/bin/bash
# AgentSync · 通用挂钩
# 适用任何 Agent 框架。在 Agent 的启动脚本中加入一行。

echo "AgentSync 通用挂钩"
echo ""
echo "在你的 Agent 启动脚本中加入以下行（在 Agent 加载系统提示词之前）："
echo ""
echo "  # AgentSync: 自动为当前模型适配"
echo "  bash ~/.agentsync/agent-sync.sh adapt"
echo ""
echo "这会让你的 Agent 在每次启动时："
echo "  1. 检查当前是什么模型"
echo "  2. 如果有画像 → 自动调整提示词"
echo "  3. 如果没有画像 → 自动探测 → 创建画像 → 调整"
echo ""
echo "适配指令会写入 ~/.agentsync/models/ADAPT.md"
echo "在你的系统提示词中包含这个文件即可。"
