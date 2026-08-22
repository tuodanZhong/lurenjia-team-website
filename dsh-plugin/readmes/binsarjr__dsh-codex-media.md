# dsh-codex-media

[![dsh-plugin](https://img.shields.io/badge/dsh--plugin-%E2%9C%93-5B4CF0?style=flat-square)](https://github.com/topics/dsh-plugin)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D22-339933?style=flat-square&logo=nodedotjs&logoColor=white)](package.json)
[![Zero dependencies](https://img.shields.io/badge/dependencies-0-green)](package.json)

Image and document analysis tools for agent harnesses, powered by a **local
[OpenAI Codex CLI](https://github.com/openai/codex)** — with zero runtime
dependencies (Node 22+ built-ins only). Two tools, one engine:

- **`analyze_image`** — describe a local image or answer a question about it
  (PNG, JPEG, WebP, GIF). The image is attached natively via
  `codex exec --image`.
- **`analyze_document`** — analyze a local document (PDF, Office, RTF, or
  text formats) or answer a focused question about it. The model reads the
  file and returns only the answer, so binary documents never flood the
  agent's context with extracted text.
- **`generate_image`** — generate an image from a text prompt and save it to
  a local file. Defaults to a **Hermes Agent** oneshot (authenticated through
  your existing ChatGPT/Codex login — no API key), with the OpenAI Images
  API as the deterministic alternative.

## Why this exists

Text-only models (like DeepSeek) cannot receive images through a model's
native attachment channel — DeepSeek Harness rejects the message with
*"The current model does not support images"*. The robust pattern is to
deliver **file paths** instead, and let a separate tool analyze the file.
`dsh-codex-media` is the analysis half of that pattern: it only ever reads
paths, so it works with text-only models, vision models, and remote
browsers alike. The upload half is delegated to
[dsh-drop-to-path](https://github.com/loudMore/dsh-drop-to-path) — this
package deliberately ships **no upload machinery of its own**.

The engine design follows the same model-routing idea as evonic's
[native document analysis](https://github.com/anvie/evonic/pull/108):
validate first, try configured models in fallback order, return only the
answer, and treat document contents as untrusted data.

## Transports

Three transports behind one call interface:

| Transport | Mechanism | Credential | Best for |
| --- | --- | --- | --- |
| `cli` *(default for analyze)* | Spawn `codex exec --json`, parse the JSONL event stream | Codex CLI's own auth (ChatGPT login or `OPENAI_API_KEY`) | Quick start when the CLI is already authenticated |
| `hermes` *(default for generate)* | Spawn `hermes -z` (Hermes Agent oneshot); Hermes reads/generates with its own tools and vision routing | [Hermes Agent](https://github.com/NousResearch/hermes-agent) auth (works with the OpenAI Codex provider / ChatGPT login) | Reading and generation without an API key |
| `api-compatible` | Direct HTTP `chat/completions`; documents travel as a native `file` content block, images as the standard `image_url` block | `CODEX_ANALYSIS_API_KEY` + `CODEX_ANALYSIS_BASE_URL` | Standalone operation against any OpenAI-compatible endpoint |
| `api-responses` | Official OpenAI Responses API; documents as `input_file`, images as `input_image` | `CODEX_ANALYSIS_API_KEY` + `CODEX_ANALYSIS_BASE_URL` | Official OpenAI API with native file inputs |

The HTTP transports are the standalone path: the file is read locally,
base64-encoded, and sent to the model API directly — no CLI binary, no
sub-agent, one HTTP round-trip. The CLI transport stays available because it
inherits the CLI's auth and per-call `--sandbox read-only`.

## Requirements

- Node.js >= 22
- One of:
  - OpenAI Codex CLI on `PATH` (`codex`), authenticated
    ([install guide](https://developers.openai.com/codex/getting-started)),
    for the `cli` transport; or
  - An API key and endpoint for the HTTP transports
    (`CODEX_ANALYSIS_API_KEY`, optional `CODEX_ANALYSIS_BASE_URL`).
- A vision-capable model for `analyze_image`, and a document-capable model
  for native `analyze_document` calls.

## Quick start

```sh
# 1. Generate the two sample fixtures (no dependencies needed)
npm run fixtures

# 2. Offline wire-shape tests for the HTTP transports (no credentials)
npm test

# 3. Smoke-test the engine directly (uses your local Codex CLI)
npm run smoke:image      # "Describe this chart in two sentences."
npm run smoke:document   # "What is the invoice number and the total amount?"

# 3b. ...or through a direct API transport
CODEX_ANALYSIS_TRANSPORT=api-compatible \
CODEX_ANALYSIS_API_KEY=$OPENAI_API_KEY \
CODEX_ANALYSIS_DOCUMENT_MODELS=gpt-5.2-codex \
  npm run smoke:document

# 4. Start the MCP server over stdio
npm run mcp
```

## Integration with DeepSeek Harness

**Prerequisite: [dsh-drop-to-path](https://github.com/loudMore/dsh-drop-to-path)** (MIT).
That plugin owns the drop/upload UX: you drop or paste an image or file into
the composer, it uploads the bytes to the host, saves them into the active
workspace's `.drops/` directory, and appends the resulting **workspace paths**
to your message when you send. `dsh-codex-media` deliberately ships **no
upload machinery of its own** — it only reads paths, so the combination works
for text-only models, vision models, and remote browsers (file → upload →
host disk → path) alike.

```sh
# 1. install the drop/upload plugin first
dsh plugin --profile web add github:loudMore/dsh-drop-to-path

# 2. install this bundle (tools only: analyze_image, analyze_document)
dsh plugin --profile web add github:binsarjr/dsh-codex-media

# 3. restart `dsh web` and refresh the page
```

### The flow

```
drop/paste image or file into the composer (any model, any browser)
  → dsh-drop-to-path uploads the bytes to the host
  → host saves the file into <workspace>/.drops/
  → paths are appended to your message when you send (native chips stay clean)
  → the agent receives the workspace paths in one message with your text
  → the agent calls analyze_image / analyze_document with those paths
  → only the answer returns to the conversation
```

The bundle row mounts `src/dsh-plugin.mjs` (host-only, no client half), so
the tools survive restarts and need no per-session approval.

**Alternative: MCP row** — the included `src/mcp-server.mjs` also mounts
through dsh's built-in MCP client (see `cordis.example.yml`) if you prefer
`mcp__codex__`-namespaced tools or cross-harness portability. Paths produced
by dsh-drop-to-path work there too.

## Configuration (environment variables)

| Variable | Default | Meaning |
| --- | --- | --- |
| `CODEX_ANALYSIS_TRANSPORT` | `cli` | `cli`, `api-compatible`, or `api-responses` |
| `CODEX_ANALYSIS_CODEX_BIN` | `codex` | Codex executable (CLI transport) |
| `CODEX_ANALYSIS_API_KEY` | *(empty)* | API key for the HTTP transports (falls back to `OPENAI_API_KEY`) |
| `CODEX_ANALYSIS_BASE_URL` | `https://api.openai.com/v1` | Endpoint base for the HTTP transports |
| `CODEX_ANALYSIS_TIMEOUT_MS` | `300000` | Per-call wall-clock budget |
| `CODEX_ANALYSIS_IMAGE_MODELS` | *(empty)* | Comma-separated vision model fallback order; empty = Codex default on `cli`, an error on HTTP transports |
| `CODEX_ANALYSIS_DOCUMENT_MODELS` | *(empty)* | Same, for documents |
| `CODEX_ANALYSIS_GENERATION_TRANSPORT` | *(empty)* | Generation transport override; defaults to `hermes` (fallback: `CODEX_ANALYSIS_TRANSPORT`) |
| `CODEX_ANALYSIS_GENERATION_MODEL` | *(empty)* | Generation model override. Hermes transport: its own default (chat model / `gpt-image-2-medium` backend); API transports default to `gpt-image-1` |
| `CODEX_ANALYSIS_HERMES_BIN` | `hermes` | Hermes Agent executable |
| `CODEX_ANALYSIS_MAX_IMAGE_BYTES` | `20971520` | Image size cap |
| `CODEX_ANALYSIS_MAX_DOCUMENT_BYTES` | `52428800` | Document size cap |

## Behavior & safety

- **Validation before every call**: kind, non-empty path/question, extension
  allowlist, regular-file check, size cap, and a PDF magic-byte signature
  check. Requests are rejected with a clear error instead of reaching the
  model.
- **Fallback routing**: models are tried in order until one succeeds; when
  all fail, the tool error lists each attempt's failure and stderr tail.
- **Bounded calls**: every run is bounded by a timeout that kills the CLI
  process tree or aborts the HTTP request.
- **CLI transport is sandboxed**: `codex exec` runs with `--sandbox read-only`
  and `--skip-git-repo-check`; generation via the `cli` transport uses
  `--sandbox workspace-write` (it must write the output file) and needs
  `OPENAI_API_KEY`.
- **Generation without a key**: the `hermes` transport authenticates through
  the Hermes Agent's own provider config (e.g. `image_gen.provider:
  openai-codex` for the ChatGPT/Codex login), so image generation works with
  no `OPENAI_API_KEY` at all.
- **Only the answer returns**: the engine extracts the final assistant text
  (from Codex's JSONL stream, the chat completion, or the Responses output);
  token usage and the chosen model travel in structured metadata, not in the
  model-facing text.
- **Document contents are untrusted data**: the engine never parses the
  document itself, and the analysis prompt instructs the model to ignore
  instructions found inside the file — the same hardening as evonic's native
  document analysis.

## Repository layout

```
src/engine.mjs          Core engine: validation, transports, parsing, fallbacks
src/api-client.mjs      Direct HTTP transports (chat/completions + Responses API)
src/mcp-server.mjs      Zero-dependency MCP server (stdio, JSON-RPC 2.0)
src/dsh-plugin.mjs      DeepSeek Harness native bundle plugin (host-only)
scripts/make-fixtures.mjs  Generates test fixtures with Node built-ins only
scripts/mock-api-test.mjs  Offline wire-shape tests for the HTTP transports
scripts/smoke.mjs       CLI smoke test for the engine
test/fixtures/          sample-chart.png, sample-invoice.pdf
cordis.patch.yml        dsh profile bundle manifest
cordis.example.yml      Alternative MCP composition rows
```

## Roadmap

- Capability-based model routing configuration (per-model `vision` /
  `document` flags with a fallback chain), like evonic's System Settings.
- `analyze_image` with multiple images in one call.
- Streaming results for long analyses.
- MCP *resources* so clients can list recently analyzed files.

## License

[MIT](./LICENSE)
