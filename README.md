# AgentSync

> **Don't be a slave to tokens.**
>
> The big players ship hand-crafted profiles for their own models inside their own agents. That's a luxury you pay for—every month, every API call, every token. If you've got the budget, go for it.
>
> If you don't—keep reading.

AgentSync is a **self-learning adapter** that sits between your agent and any LLM. It probes the model, learns its temperament, and adjusts how your agent talks to it. No hand-crafting. No expensive subscriptions. No lock-in.

---

## ⚠️ We're being honest with you

This is a prototype. We know model-aware adaptation works—there's public data showing 10–20 point gains when prompts are tuned per model. But *we* haven't run our own A/B tests yet. The numbers are out there; ours aren't.

If you need polished, tested, enterprise-grade—this isn't for you yet. If you're a tinkerer, a builder, someone who runs open agents on API models and wants them to feel tighter—try it. Tell us what happens. Good or bad.

---

## How it works

```
You pick a model. Your agent starts up.
AgentSync steps in:

  1. Ever talked to this model before? → Check.
  2. No? → Quick 3-question probe → Now we know its vibe.
  3. Yes? → Load the profile → Adjust the prompt.
  4. Every session → Update what we know.

Your agent doesn't notice. The model just feels... less foreign.
```

Local. No cloud. No API keys. Your data stays yours.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ArtiNexus/agentsync/main/install.sh | bash
```

That's it. Next time your agent starts, AgentSync runs automatically.

Manual install (if you want to see what's inside first):

```bash
git clone https://github.com/ArtiNexus/agentsync.git
cd agentsync
bash install.sh
```

---

## Why this exists

Some agent platforms recently announced model-specific prompt profiles. Good idea. They chose to write them by hand—teams of people, one model at a time, indefinitely.

We don't have a team. Neither do you.

So we built something that figures the model out on its own. It gets better the more you use it. The tenth conversation should feel tighter than the first.

Hand-crafted profiles are a privilege of scale. This one was carved out by a single mind, thinking deeply about the problem for weeks.

---

## The comparison nobody asked for

| | The expensive way | The AgentSync way |
|:--|:------------------|:------------------|
| Who writes the profiles? | Teams of people, indefinitely | A thinker. Once. Then it learns. |
| How many models? | 3–5, hand-picked | Any model with an API |
| Does it learn? | No. Static. | Yes. Every session. |
| Framework lock-in? | Yes. Profiles only work there. | No. One bash line hooks it. |
| Monthly cost? | Your subscription. | Zero. |

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
    - "Likes bold formatting—suppress if unnecessary"
```

Seven dimensions. Scored in seconds. Adaptations derived from the scores, not from someone's opinion.

---

## Supported frameworks

| Framework | Auto-detected | Auto-hooked |
|:----------|:------------:|:-----------:|
| pi | yes | yes |
| Claude Code | yes | manual |
| Any other agent | — | one bash line |

---

## Commands

```bash
agent-sync status          # Is it working?
agent-sync adapt [model]   # Load or create a profile
agent-sync probe <model>   # Quick probe
```

---

## Contribute

Find a model we haven't profiled? Run `agent-sync probe` on it and send us the YAML. Run an A/B test? Share the numbers—even if they're bad. Found a bug? Open an issue.

This repo is small on purpose. Eight files, under 800 lines. Read the whole thing in ten minutes.

---

## No token left behind

MIT
