# AgentSync

> Some agent frameworks recently started shipping hand-crafted profiles for the models they support. That's a good signal. It means the industry is waking up to something we've been thinking about: a single harness cannot be optimal for every model.
>
> We just don't think you should have to write those profiles yourself.

**AgentSync is a self-learning adapter that sits between your agent and any LLM.** No hand-crafting. No static configs. No framework lock-in.

---

## ⚠️ This is a prototype

We believe model-aware adaptation matters. The evidence from the broader agent ecosystem points toward 10–20 point performance gains when prompts are tuned per model. But we have not yet completed our own A/B comparison tests for AgentSync.

If that bothers you, this project isn't ready for you yet. If you're willing to test it anyway, we'd welcome your data—good or bad.

---

## What it does

```
Your agent is about to send a prompt to an LLM.
AgentSync steps in:

  1. Checks if it knows this model
  2. If not → runs a quick probe → builds a profile
  3. If yes → reads the profile → adjusts the prompt
  4. After each session → updates the profile

The agent never notices. The LLM feels more natural.
```

That's it. No cloud service. No API key. Everything runs locally.

---

## Install

Tell your agent to run this:

```bash
curl -fsSL https://raw.githubusercontent.com/your-org/agentsync/main/install.sh | bash
```

Or do it yourself if you prefer:

```bash
git clone https://github.com/your-org/agentsync.git
cd agentsync
bash install.sh
```

---

## Why this exists

In the last six months, several major agent frameworks began offering model-specific prompt configurations. They chose to hand-write them—one engineer, one model, one profile at a time. That approach scales at the speed of your team's free time.

AgentSync takes a different path. When you connect a new model, it figures out the model's temperament on its own. Then it keeps learning. The tenth conversation with that model should feel tighter than the first.

Hand-written profiles are a good idea. We think automatic ones are a better one.

---

## How it compares

| Approach | Creation | Updates | Framework | Model coverage |
|:---------|:---------|:--------|:----------|:--------------|
| Hand-written per model | Manual, per engineer | Static | Single framework | 3–5 models |
| Generic single prompt | Once | Never | Any | All, poorly |
| AgentSync | Automatic probe | Continuous | Any | All, adapted |

---

## Supported frameworks

| Framework | Auto-detect | Auto-hook |
|:----------|:-----------:|:---------:|
| pi | yes | yes |
| Claude Code | yes | manual |
| Any other | — | one bash line |

---

## What's in a profile

```yaml
model_id: deepseek-v4-pro
capabilities:
  instruction_adherence: 1.0
  reasoning_depth: 1.0
  conciseness: 0.7
  composite_score: 0.91
adaptations:
  prompt:
    add_constraint_suffix: "Be concise."
  strategy:
    verification_rounds: 2
  gotchas:
    - "Occasionally adds bold formatting—suppress if not needed"
```

Seven dimensions, scored automatically. Adaptations derived from scores.

---

## Commands

```bash
agent-sync status          # Is the adapter active?
agent-sync adapt [model]   # Load/create profile, inject adaptations
agent-sync probe <model>   # Quick 3-dimensional probe
```

---

## Contribute

If you test AgentSync with a model we haven't profiled yet, send us the profile. If you run an A/B comparison, share the numbers. If it breaks, tell us how.

This project is small on purpose. Seven files. Seven hundred lines. Easy to audit, easy to extend.

---

MIT
