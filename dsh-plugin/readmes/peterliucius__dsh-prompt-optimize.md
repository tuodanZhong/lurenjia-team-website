# dsh-prompt-optimize

DeepSeek Harness web plugin: rewrite the current composer draft through an auxiliary LLM call. Click replaces the draft only; it never sends a message or starts a turn.

## Install

```sh
dsh plugin --profile web add github:peterliucius/dsh-prompt-optimize
```

Git-hosted plugins build on install through `prepare`. pnpm ≥10 blocks that script until you allow it. The first `add` fails and prints the key; copy it into the profile's `pnpm-workspace.yaml`:

```yaml
allowBuilds:
  dsh-prompt-optimize: true
```

Then re-run the same `add`. Only allow packages whose source you trust. Pin a commit (`github:peterliucius/dsh-prompt-optimize#<sha>`) if you do not want a later push to change what runs.

A local checkout that already has `lib/` does not need `allowBuilds`:

```sh
dsh plugin --profile web add /path/to/dsh-prompt-optimize
```

Start the web profile:

```sh
dsh --profile web
```

The patch inserts one row named `dsh-prompt-optimize` (`maxInputBytes: 32768`, `maxOutputTokens: 4096`, `timeoutMs: 60000`). The same package's `dsh.client` declaration occupies `conversation.input.right`. Default web-app does not mount this plugin.

## Behavior

The sparkle button is always visible. It disables when the draft is empty after trim, contains a composer reference chip (U+FFFC), the session is removed, or the input machine is not in the plain phase.

Click captures the current draft, calls `ctx.promptOptimize.optimize` over the `promptOptimize` Typert Remote, and overwrites the composer through `inputActions.setDraft` only when the live draft still equals that capture. Failures toast; a moved draft toasts and is not replaced.

The auxiliary request frames the draft as JSON, uses a fixed rewrite instruction, enforces the configured byte and token budgets, composes timeout with caller cancellation, and sets `reasoningEffort: 'off'`. It never enqueues a user message or appends a durable session event.

Route resolution uses plugin `provider`/`model` when both are set, else the session's latest `request/header` config, else `ctx.get('agentDefaultModel')?.currentSelection()`.

## Configuration

Every field is required except the paired route override; there are no library defaults. The bundle row supplies the values below.

| Key | Contract |
|---|---|
| `maxInputBytes` | Positive UTF-8 byte ceiling for the final JSON-framed user prompt. |
| `maxOutputTokens` | Positive auxiliary generation token cap. |
| `timeoutMs` | Positive end-to-end deadline within the runtime timer limit. |
| `provider`, `model` | Optional explicit route; both or neither. |

Override them in the profile's `cordis.patch.yml` by restating the whole row `config`.

## Develop against a local harness

Tests resolve `@deepseek-ai/dsh-*` peers through a sibling [deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) checkout at `../dsharness`. Without that checkout, `pnpm test` skips.

```sh
pnpm install
pnpm test
pnpm build
```

Regenerate Typert host + remote-client artifacts after changing `@Remote` methods (requires the sibling checkout):

```sh
pnpm exec tsx scripts/generate-typert.ts
```

## License

MIT
