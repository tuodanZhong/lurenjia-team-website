> ⚠️ **此套件已併入 [`@bryan-cmf/dsh-insights`](https://github.com/Bryan-cmf/dsh-insights)(2026-08-17)。此 repo 僅保留作合併前歷史,後續迭代請到 dsh-insights。**

# 🔭 Infra Observability — DSH-Plugin

> **結構化觀測層**:真實的工具/技能使用記錄(`tools/result`)、技能目錄審計、看門狗。**零模型自報**——平台記什麼,報告就寫什麼。

[![npm](https://img.shields.io/npm/v/@bryan-cmf/dsh-infra-observability)](https://www.npmjs.com/package/@bryan-cmf/dsh-infra-observability)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![DSH](https://img.shields.io/badge/DSH-Plugin-4B32C3)](https://github.com/deepseek-ai/deepseek-harness)

A [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) host plugin
that replaces model self-reporting with **structural recording**:

- **`tools/result` listener** — every real tool execution (name + outcome) is
  recorded by the platform into a ring buffer and per-day aggregates.
- **`agent/error` / `agent/status`** — error totals and live-agent tracking.
- **Watchdog** — timer-driven alert when agent errors spike (≥ N in 5 min).
- **Three tools** for the model and humans:

| Tool | What it reports |
| --- | --- |
| `usage_report` | Per-day tool/skill aggregates (calls / ok / err) + recent executions |
| `audit_skills` | Catalog totals, provider spread, warnings (missing description, non-kebab names), today's skill usage |
| `infra_health` | Uptime, records kept, error counts, running agents, catalog size, watchdog state |

## Dashboard (browser)

The client half registers an **「觀測」view tab** (order 20, right of
chat / trajectory) rendering a live per-session dashboard from the `infraView`
session projection: turn counts, failure count, tool/skill TOP lists with
success-rate bars, and the recent execution trail. Data updates as events
commit — no refresh needed.

## Install

### Path A — Host composition (recommended, always-on)

Add to the profile's `package.json` `dsh.profile.bundles` (the package ships a
`dsh.bundle.patch` that inserts the plugin row):

```jsonc
"dsh": { "profile": { "bundles": ["@bryan-cmf/dsh-infra-observability"] } }
```

### Path B — Agent preset row

```yaml
- id: infra-observability
  name: '@bryan-cmf/dsh-infra-observability'
```

## Requirements

- DSH `>= 0.1.0-rc.6` (services: `tools`, `timer`, `skills` — all part of the
  shipped `dsh-base` bundle)

## Configuration

| Key | Default | Meaning |
| --- | --- | --- |
| `maxRecords` | `5000` | Ring-buffer cap for recent execution records |
| `healthIntervalMs` | `60000` | Watchdog check interval |
| `errorAlertThreshold` | `5` | Alert at ≥ this many agent errors per 5-minute window |

## Scope notes

- Aggregates are process-lifetime (like `dsh-skill-trail`); the durable source
  of truth remains the session log. Cross-restart persistence is planned.
- Companion package: [`@bryan-cmf/dsh-skill-trail`](https://github.com/Bryan-cmf/dsh-skill-trail)
  renders the per-reply badge row; this package is the backend layer.

## Development

```bash
pnpm install --store-dir .pnpm-store
pnpm build
```

## License

MIT
