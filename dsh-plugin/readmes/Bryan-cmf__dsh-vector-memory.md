> ⚠️ **此套件已併入 [`@bryan-cmf/dsh-insights`](https://github.com/Bryan-cmf/dsh-insights)(2026-08-17)。此 repo 僅保留作合併前歷史,後續迭代請到 dsh-insights。**

# 🧠 Vector Memory — DSH-Plugin

> **可持久化的 Agent 記憶核心**——`mem_save` / `mem_search` / `mem_health`,跨 session、跨重啟,零外部依賴。

[![npm](https://img.shields.io/npm/v/@bryan-cmf/dsh-vector-memory)](https://www.npmjs.com/package/@bryan-cmf/dsh-vector-memory)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![DSH](https://img.shields.io/badge/DSH-Plugin-4B32C3)](https://github.com/deepseek-ai/deepseek-harness)

A [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) plugin
that gives your agents durable, cross-session memory — the same
`mem_save` / `mem_search` contract as the original
[`Bryan-cmf/vector-memory`](https://github.com/Bryan-cmf/vector-memory) MCP
server, but **natively** on DSH.

## Why a native rewrite (and what changed)

The 2026 memory landscape made self-hosting a Qdrant + BGE-m3 stack a
commodity (Zep / Mem0 / Letta / LangMem all offer managed embeddings + graph
memory). This package keeps the **agent-facing contract** and drops the
**infrastructure**:

| Aspect | Old (MCP server) | This plugin |
| --- | --- | --- |
| Storage | Qdrant (Docker) + BGE-m3 (~2GB) | **DSH `storageDomain`** — durable JSON backend, zero setup |
| Retrieval | Vector similarity | v1: deterministic keyword scoring + recency; **embeddings pluggable in v2** |
| Interface | MCP stdio (Claude/Cursor/…) | Native tools (`mem_save` / `mem_search` / `mem_health`) + `vectorMemory` service |
| Persistence | Manual install script | Bundle row — it just works |

## Tools

| Tool | Effect |
| --- | --- |
| `mem_save` | `{ content, tags?, ttlDays? }` → durable memory, returns id |
| `mem_search` | `{ query, limit? }` → ranked hits (score, content, tags, created) |
| `mem_health` | record count, expired count, domain status, TTL policy |

Other plugins can `inject: ['vectorMemory']` and call `save` / `search` /
`health` directly.

## Dashboard

The client half registers a **「記憶」view tab** (order 30, right of
chat / 軌跡 / 觀測) listing this session's saved/searched items live.

## Install

```jsonc
"dsh": { "profile": { "bundles": ["@bryan-cmf/dsh-vector-memory"] } }
```

> ⚠️ This row **publishes the `vectorMemory` service** — it must live in the
> **host composition** (process-global). If you mount it from an agent preset
> instead, wrap it in a group with an `isolate` realm (see the DSH
> composition docs).

## Requirements

- DSH `>= 0.1.0-rc.6` — services: `tools`, `storageDomain` (domain layer +
  a storage backend, e.g. `dsh-storage-json`, are part of the shipped
  `dsh-base` bundle)

## Configuration

| Key | Default | Meaning |
| --- | --- | --- |
| `ttlDays` | `90` | Default memory TTL; `0` = forever |
| `maxResults` | `10` | Default `mem_search` result count |

## Roadmap

- v2: pluggable embedding backends (hosted embedders or Qdrant REST)
- v2: MCP stdio dual-exit so the same store serves Claude Desktop / Cursor
- v2: memory curation (merge/dedupe/forget jobs)

## Development

```bash
pnpm install --store-dir .pnpm-store
pnpm build
```

## License

MIT
