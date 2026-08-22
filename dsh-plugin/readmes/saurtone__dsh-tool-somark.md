# dsh-tool-somark

A [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) plugin that gives the model a `somark_parse` tool: parse PDFs, images, Word, and PowerPoint files into structure-preserving Markdown and JSON through the [SoMark](https://somark.tech) document-parsing API, with page and token counts.

The document read goes through `ctx.fs`, so any mounted filesystem policy applies to the read. Parsed content is returned as data and must never be executed.

## Install

```sh
# from npm (once published)
dsh plugin --profile <name> add dsh-tool-somark

# from a tarball
dsh plugin --profile <name> add ./dsh-tool-somark-0.1.0.tgz

# from git (requires the package's `prepare` build; see the harness docs)
dsh plugin --profile <name> add github:you/dsh-tool-somark
```

Then boot the profile; the `somark_parse` tool registers automatically. The plugin is also usable as a plain library dependency for programmatic parsing (`src/client.ts` exports the API client).

## Requirements

- A DeepSeek Harness profile with the base bundle (`@deepseek-ai/dsh-base`), which provides `ctx.tools` and `ctx.fs`.
- A SoMark API key. Set `SOMARK_API_KEY` in the environment or configure `apiKey` below. SoMark is an external paid service and receives the uploaded document contents.

## Config

All fields optional; defaults apply when omitted.

| Field | Default | Meaning |
| --- | --- | --- |
| `apiKey` | unset | SoMark API key `$SOMARK_API_KEY` Empty → the tool errors at execution. |
| `baseURL` | `https://somark.tech/api/v1` | API base; `/parse/async` and `/parse/async_check` append. |
| `outputFormats` | `['markdown', 'json']` | Formats requested when a call omits `outputFormats`. |
| `elementFormats` | `{ image: 'url', formula: 'latex', table: 'html', cs: 'image' }` | Partial per-element rendering-format overrides. |
| `featureConfig` | cross-page off, inline image / table image / image understanding on, header-footer off | Partial feature-switch overrides. |
| `pollIntervalMs` | `2000` | Delay between status polls. |
| `maxPollAttempts` | `1000` | Maximum polls (≈ 33 minutes at the default interval). |
| `maxFileBytes` | `209715200` | Upload cap; SoMark documents a 200 MB limit. |
| `markdownCapChars` | `200000` | Inclusive cap on the markdown characters returned in one result. |
| `jsonCapChars` | `200000` | Inclusive cap on the stringified JSON characters returned in one result. |

Example profile patch (`cordis.patch.yml` in the profile, or a `--patch` overlay):

```yaml
- id: tool-somark
  config:
    apiKey: 'sk-…'
```

Invalid element/feature/output-format values fail the plugin load with a `CONFIG_INVALID` error rather than being silently accepted.

## The tool

`somark_parse` takes a required `path` (absolute path to the document) and an optional `outputFormats` array. It returns the parsed Markdown (capped by `markdownCapChars`, flagged `truncated`), the page/token counts, and the structured JSON when requested and within `jsonCapChars` (otherwise flagged `jsonOmitted`).

Failures carry machine-routable codes on the tool result: `NO_API_KEY`, `DOCUMENT_NOT_FOUND`, `DOCUMENT_NOT_A_FILE`, `UNSUPPORTED_EXTENSION`, `FILE_TOO_LARGE`, `CONFIG_INVALID`, `SUBMIT_FAILED`, `TASK_FAILED`, `POLL_TIMEOUT`, `ABORTED`, `REQUEST_FAILED`, `INVALID_RESPONSE`.

## Development

```sh
pnpm install
pnpm test        # vitest (79 tests, 100% src coverage)
pnpm build       # tsc → lib/
pnpm pack        # tarball for dsh plugin add
```

## Known Limitations and Deferred Work

- No batch/directory parsing — one `path` per call; callers loop the tool.
- Element and feature formats are deployment config, not per-call arguments.
- No artifact persistence — the result returns content; consumers can persist via `tool/result`.
- Oversized JSON is omitted (`jsonOmitted`), not spilled.

## License

MIT
