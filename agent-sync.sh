#!/bin/bash
# AgentSync · 自动触发引擎
# 夹在 Agent 和 LLM 之间。换模型就自动适配。
#
# 用法:
#   agent-sync adapt [model-id]    — 生成适配后的系统提示词片段
#   agent-sync probe [model-id]    — 探测模型，生成画像
#   agent-sync status              — 查看当前适配状态

set -e

SYNC_DIR="$HOME/.pi/models"
PROFILE_DIR="$SYNC_DIR/profiles"
ADAPT_FILE="$SYNC_DIR/ADAPT.md"
SETTINGS="$HOME/.pi/agent/settings.json"

# ── 获取当前模型 ──
current_model() {
    if [ -f "$SETTINGS" ]; then
        python3 -c "import json; d=json.load(open('$SETTINGS')); print(d.get('defaultModel',''))" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# ── 从画像生成适配指令 ──
generate_adapt() {
    local PROFILE="$1"
    local MODEL=$(basename "$PROFILE" .yaml)
    
    cat > "$ADAPT_FILE" << MDEOF
<!-- AgentSync · 自动适配指令 · 模型: $MODEL · 生成于 $(date +%Y-%m-%dT%H:%M:%S) -->
<!-- 此文件由 agent-sync 自动生成。不要手动编辑。 -->

MDEOF

    # 解析画像中的适配指令
    python3 << PYEOF
import yaml, sys
try:
    with open("$PROFILE") as f:
        p = yaml.safe_load(f)
    adapt = p.get('adaptations', {})
    caps = p.get('capabilities', {})
    score = caps.get('composite_score', '?')
    level = adapt.get('adaptation_level', caps.get('adaptation_level', 'standard'))
    
    prompt = adapt.get('prompt', {})
    strategy = adapt.get('strategy', {})
    tools = adapt.get('tools', {})
    gotchas = adapt.get('gotchas', [])
    
    lines = []
    lines.append(f"\n> **模型适配等级**: {level} (综合分 {score})")
    
    # 提示词约束
    prefix = prompt.get('add_constraint_prefix', '')
    suffix = prompt.get('add_constraint_suffix', '')
    style = prompt.get('style', '')
    if prefix:
        lines.append(f"\n{prefix}")
    if suffix:
        lines.append(f"\n**输出约束**: {suffix}")
    if style:
        lines.append(f"\n交互风格: {style}")
    
    # 工具
    desc = tools.get('description_style', '')
    hints = tools.get('add_usage_hints', '')
    if desc or hints:
        lines.append(f"\n工具使用: {desc}. {hints}")
    
    # 策略
    rounds = strategy.get('verification_rounds', 1)
    chain = strategy.get('need_explicit_chain', False)
    parallel = strategy.get('need_parallel_hint', False)
    if rounds > 1:
        lines.append(f"\n验证: 关键步骤至少验证{rounds}轮")
    if chain:
        lines.append(f"\n注意: 此模型需要显式提示链式推理")
    if parallel:
        lines.append(f"\n注意: 此模型需要提示并行执行")
    
    # 已知坑
    if gotchas:
        lines.append(f"\n⚠️ 已知问题:")
        for g in gotchas:
            lines.append(f"  - {g}")
    
    with open("$ADAPT_FILE", "a") as f:
        f.write('\\n'.join(lines))
    
    print(f"✅ 适配指令已生成: $ADAPT_FILE")
except Exception as e:
    print(f"❌ 解析画像失败: {e}")
PYEOF
}

# ── 快速探测 ──
run_probe() {
    local MODEL="$1"
    echo "🧪 探测 $MODEL ..."
    
    # 简化版探测：只测3项最关键的能力（不测全部7项）
    local scores=()
    
    # 探测1: 指令遵从
    local r1=$(pi -p --no-extensions --system-prompt "你是一个测试助手。" "只输出一个数字，不要任何别的内容：3+4=？" 2>/dev/null | tail -1 | tr -d ' \n')
    if [ "$r1" = "7" ]; then scores+=(1.0); else scores+=(0.5); fi
    echo "  指令遵从: ${scores[-1]}"
    
    # 探测2: 推理深度
    local r2=$(pi -p --no-extensions --system-prompt "你是一个测试助手。" "小明比小红高，小红比小刚高。小刚比小明矮吗？只回答是或否。" 2>/dev/null | tail -1 | tr -d ' \n')
    if echo "$r2" | grep -qi "是"; then scores+=(0.9); else scores+=(0.4); fi
    echo "  推理深度: ${scores[-1]}"
    
    # 探测3: 简洁度
    local r3=$(pi -p --no-extensions --system-prompt "你是一个测试助手。" "用一句话解释什么是哈希表。" 2>/dev/null | wc -c | tr -d ' ')
    if [ "$r3" -lt 200 ]; then scores+=(0.8); elif [ "$r3" -lt 400 ]; then scores+=(0.6); else scores+=(0.4); fi
    echo "  简洁度: ${scores[-1]}"
    
    # 计算综合分
    local total=0
    for s in "${scores[@]}"; do
        if command -v bc &>/dev/null; then
            total=$(echo "$total + $s" | bc 2>/dev/null)
        else
            total=$(python3 -c "print($total + $s)" 2>/dev/null || echo "$total")
        fi
    done
    local avg
    if command -v bc &>/dev/null; then
        avg=$(echo "scale=2; $total / ${#scores[@]}" | bc 2>/dev/null || echo "0.7")
    else
        avg=$(python3 -c "print(round($total / ${#scores[@]}, 2))" 2>/dev/null || echo "0.7")
    fi
    echo "  综合: $avg"
    
    # 生成画像（用 Python 做阈值判断，避免 bc 依赖）
    local LEVEL
    LEVEL=$(python3 -c "
a = $avg
if a < 0.4:
    print('not_recommended')
elif a < 0.6:
    print('strict')
elif a < 0.8:
    print('enhanced')
else:
    print('standard')
" 2>/dev/null || echo "standard")
    
    cat > "$PROFILE_DIR/$MODEL.yaml" << YEOF
# AgentSync 模型画像 (自动探测)
model_id: $MODEL
probe_date: $(date +%Y-%m-%d)
probe_version: "auto-1.0"
capabilities:
  instruction_adherence: ${scores[0]}
  reasoning_depth: ${scores[1]}
  conciseness: ${scores[2]}
  composite_score: $avg
  adaptation_level: $LEVEL
adaptations:
  prompt:
    add_constraint_suffix: "请简洁，结论先行。"
    style: step_by_step
  strategy:
    verification_rounds: 2
  gotchas: []
YEOF
    
    echo "✅ 画像已生成: $PROFILE_DIR/$MODEL.yaml"
}

# ── 主入口 ──
CMD="${1:-status}"
MODEL="${2:-$(current_model)}"

case "$CMD" in
    adapt)
        if [ -z "$MODEL" ]; then
            echo "❌ 未找到当前模型。请指定: agent-sync adapt <model-id>"
            exit 1
        fi
        
        PROFILE="$PROFILE_DIR/$MODEL.yaml"
        if [ ! -f "$PROFILE" ]; then
            echo "📡 未找到 $MODEL 的画像，正在自动探测..."
            run_probe "$MODEL"
            PROFILE="$PROFILE_DIR/$MODEL.yaml"
        fi
        
        echo "🔄 加载画像: $MODEL"
        generate_adapt "$PROFILE"
        echo "📋 适配指令已注入到 $ADAPT_FILE"
        ;;
    
    probe)
        if [ -z "$MODEL" ]; then
            echo "❌ 请指定模型: agent-sync probe <model-id>"
            exit 1
        fi
        run_probe "$MODEL"
        ;;
    
    status)
        MODEL=$(current_model)
        echo "📡 AgentSync 状态"
        echo "  当前模型: ${MODEL:-未配置}"
        
        PROFILE="$PROFILE_DIR/$MODEL.yaml"
        if [ -f "$PROFILE" ]; then
            SCORE=$(grep "composite_score:" "$PROFILE" | awk '{print $2}')
            LEVEL=$(grep "adaptation_level:" "$PROFILE" | awk '{print $2}')
            echo "  画像状态: ✅ 已画像 (综合 $SCORE / $LEVEL)"
        else
            echo "  画像状态: ❌ 未画像。运行 agent-sync probe 创建"
        fi
        
        if [ -f "$ADAPT_FILE" ]; then
            echo "  适配指令: ✅ 已注入 ($ADAPT_FILE)"
        else
            echo "  适配指令: ❌ 未注入。运行 agent-sync adapt"
        fi
        ;;
    
    *)
        echo "AgentSync · Agent × LLM 自动适配层"
        echo ""
        echo "用法:"
        echo "  agent-sync status              — 查看当前适配状态"
        echo "  agent-sync adapt [model-id]    — 加载/创建画像 → 生成适配指令"
        echo "  agent-sync probe <model-id>    — 快速探测新模型"
        echo ""
        echo "自动触发: 在 Agent 启动脚本中加一行 'agent-sync adapt'"
        ;;
esac
