# dsh-allrouter

**One base URL, one key — Kimi K3 · Claude · GPT · Grok · GLM · DeepSeek · MiniMax-H3.**

DSH lets you add any OpenAI-compatible provider. Point it at [AllRouter](https://allrouter.ai) and you
stop juggling three providers and three keys: switch between Kimi-K3, Claude Opus 5, GPT-5.6, Grok, GLM,
DeepSeek and **MiniMax-H3** from one endpoint, billed to your own account at direct rates. Every response
reports its real cost.

## Install

```sh
dsh plugin --profile <your-profile> add github:mario03690/dsh-allrouter
export ALLROUTER_API_KEY=sk-...
```

Then pick any model above in dsh. This plugin ships **only a provider block** (`llm-pi-ai.providers.allrouter`
in `cordis.patch.yml`, per the dsh v0.1 provider docs) — no tool code runs on your machine, and your key stays
in your own environment. Settings changes take effect on the next request; no restart needed.

**Verified 2026-08-17** against `https://allrouter.ai/v1`: `Kimi-K3`, `claude-fable-5`, `gpt-5.6-sol`,
`grok-4.6`, `GLM5.2`, `deepseek-v4-flash` all return valid `openai-completions` responses with a `usage`
block (so per-call cost is computable).

> **MiniMax-H3**: available on AllRouter but priced as a "self-serve" model — enable it once in your
> AllRouter console (系统设置 → 运营设置 → 开启自用模型) before selecting it. The other models work out of the box.

## Why AllRouter

- One account, one key, one bill across many frontier models — no per-provider setup.
- Direct token rates, no markup; failed calls not charged.
- Real cost returned on every call, so you can compare models on price/latency, not marketing.

**Disclosure:** published by the team behind [ainetcafe.com](https://ainetcafe.com); AllRouter is the routing
service we build on. Get a key: <https://allrouter.ai/register>. MIT.

## Compatibility & permissions (at a glance)

| Signal | This plugin |
| --- | --- |
| **Runtime** | dsh v0.1 developer preview (2026-08-13, Cordis v4). Touches only the MCP client config shape — the narrowest surface available. Verified against a live endpoint on 2026-08-17. |
| **What runs locally** | Nothing. Ships one provider config block (`llm-pi-ai.providers.allrouter`); no tool code, no build step, no lifecycle script. |
| **Filesystem access** | None. |
| **Shell / process access** | None. |
| **Network access** | Outbound HTTPS to `allrouter.ai/v1` only, made by dsh itself — this package adds no network client. |
| **Credentials** | Your own `ALLROUTER_API_KEY`, read from your environment by dsh and stored in `$DSH_HOME/.credentials.yaml`. We never see it. |
| **Data retention** | Prompts go directly from dsh to AllRouter; this package stores nothing. |
| **Dependencies** | None. |
| **License** | MIT (see `LICENSE`). |
| **Publisher** | The team that runs [ainetcafe.com](https://ainetcafe.com) — our own hosted service, free tier plus paid usage. Issues get a same-day reply. |

> A directory listing is not a security review. Read `cordis.patch.yml` — it is short enough to read in full in under a minute.
