# dsh-llm-aimux

[![CI](https://github.com/arcships/dsh-llm-aimux/actions/workflows/ci.yml/badge.svg)](https://github.com/arcships/dsh-llm-aimux/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**DeepSeek Harness (dsh) LLM adapter backed by [aimux](https://github.com/arcships/aimux)** — one Rust engine exposing 325+ AI providers as dsh model routes.

> 中文简介：本插件把 aimux（Rust 统一 LLM 访问层，325+ 提供商）接入 DeepSeek Harness——每个 aimux provider 都可以配置成一条 dsh 模型路由。

## Install

```sh
dsh plugin --profile web add @arcships/dsh-llm-aimux
```

Then store a credential (or export the environment variable) and pick the model:

```sh
dsh --profile web
# Models page → provider "deepseek" → paste your DEEPSEEK_API_KEY
```

Headless without the credentials store works too — aimux reads the provider's
conventional env var (`DEEPSEEK_API_KEY`, `GROQ_API_KEY`, …) directly.

## Configuration

Routes are keyed by dsh provider id; each maps to one aimux provider. The
composition entry below is only the **base layer** — users add or edit routes
through their settings (web Models page → provider card, or the `llm-aimux:`
section in `settings.yaml`) and changes apply without a restart:

```yaml
- insert:
    - id: llm-aimux
      name: '@arcships/dsh-llm-aimux'
      config:
        providers:
          deepseek:                    # dsh route id
            provider: deepseek         # aimux provider name (default: the route id)
            apiKeyEnv: DEEPSEEK_API_KEY # credential ref (default: <PROVIDER>_API_KEY)
          kimi:
            provider: moonshot         # credential ref derives as MOONSHOT_API_KEY
          groq:
            displayName: Groq
```

The same shape works in the user settings layer:

```yaml
llm-aimux:
  streamIdleTimeoutMs: 300000     # chunk-idle watchdog relayed to aimux
  providers:
    groq: {}
    relay:                        # endpoint override through a gateway/relay
      provider: deepseek
      baseUrl: https://relay.example/v1
      headers:
        X-Org: acme
```

- `provider` — an aimux provider name. aimux ships 325+ (251 of them
  OpenAI-compatible registry entries); see the
  [aimux provider docs](https://github.com/arcships/aimux/blob/master/docs/api/providers.md).
- Every route appears as a configurable provider on the Models page
  (`ctx.llm.registerConfigurableProviders`, addressed at
  `llm-aimux.providers.<route>`); added or removed routes swap atomically.
- Credentials resolve through the harness `ctx.credentials` seam when mounted;
  otherwise aimux falls back to the provider's own env var. Resolution is
  per-request, so a rotated key reaches the next call.

## Status & scope

This is a young experiment tracking a **developer-preview** harness — expect
breaking changes on both sides (dsh rc bumps, aimux pre-1.0).

Currently supported:

- Streaming chat with tool calls (raw JSON tool arguments, per the adapter contract)
- Reasoning blocks in and out
- Disjoint token usage accounting (cache read/write split out)
- Attribution headers on every outbound provider request
- Settings integration: `llm-aimux` user-settings section, per-route Models
  page cards, and hot route swaps (`registration.replace`) on section changes
- Model metadata merging (aimux RFC-0027 host role): runtime `/models`
  discovery + the community catalogue (`getModelSpecs`), feeding Models-page
  cards, `resolveModel` context windows / output caps / reasoning efforts,
  and endpoint interrogation for stored routes
- Per-route endpoint overrides (`baseUrl`, `headers`) for relays and gateways
- Streaming chunk-idle watchdog (`streamIdleTimeoutMs`, default 300 s)

Retry policy: aimux always sends exactly one attempt (`max_retries: 0`) — the
dsh agent layer owns the retry budget, matching llm-pi-ai's treatment.

Not yet supported:

- Image input (dsh attachment references are not resolved to bytes yet) — fails
  closed with `UNSUPPORTED`
- Subscription/OAuth channels (aimux RFC-0018 keeps those integrator-side)
- Endpoint interrogation for *draft* (not-yet-stored) routes — arbitrary
  baseURL drafts cannot go through the aimux registry and answer with nothing

Route conflicts: routes owned here cannot overlap with the built-in
`llm-pi-ai` routes (dsh rejects duplicate adapters). If you configure both,
give the aimux entry a distinct `route` id.

## Development

```sh
npm install
npm run typecheck
npm test
```

The adapter is a thin shell over `src/translate.ts` (pure, synchronous,
fully unit-tested without the native binding). `@arcships/aimux` ships
prebuilt platform binaries via npm optional dependencies — no build scripts,
so `dsh plugin add` works without pnpm `allowBuilds` flags.

## License

[MIT](LICENSE)
