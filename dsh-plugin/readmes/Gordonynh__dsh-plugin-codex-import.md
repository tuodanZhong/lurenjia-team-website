# dsh-plugin-codex-import

**English** | [中文](README.zh.md)

A [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) plugin
that imports your **OpenAI Codex** conversation history into DSH sessions —
grouped into project workspaces, resumable, searchable, forkable — from a
single slash command.

```
/codex-import
```

```
Imported 679 session(s) from /Users/you/.codex.
Scanned 681, already present 0, failed 0.
Content: 10694 turns, 81513 steps, 13580 user messages, 81513 assistant messages, 101215 tool calls.
Grouped 529 session(s) into 116 workspace(s).
Reload the interface to see the imported sessions.
```

## Install

```bash
dsh plugin --profile web add github:Gordonynh/dsh-plugin-codex-import
```

Then add it to your profile's `~/.dsh/profiles/web/cordis.patch.yml`:

```yaml
- insert:
    - id: codex-import
      name: 'dsh-plugin-codex-import'
```

Restart the harness. Verify it composed with
`dsh --profile web --dump-config | grep codex-import`.

## Usage

| Command | Effect |
|---|---|
| `/codex-import` | import every not-yet-imported Codex session |
| `/codex-import --dry-run` | report what would be imported, write nothing |
| `/codex-import --limit 20` | stop after 20 sessions |
| `/codex-import --since 30` | only sessions from the last 30 days |
| `/codex-import --project ~/work` | only sessions whose cwd is under a path |
| `/codex-import --archived` | also scan `~/.codex/archived_sessions` |

Re-running is safe: already-imported session ids are skipped, and Codex
originals are never modified.

## Configuration

```yaml
- insert:
    - id: codex-import
      name: 'dsh-plugin-codex-import'
      config:
        codexHome: '~/.codex'        # default: $CODEX_HOME, else ~/.codex
        provider: 'codex'            # recorded on imported assistant messages
        groupIntoWorkspaces: true    # attach imported sessions to workspaces
```

## How the mapping works

| Codex (`rollout-*.jsonl`) | DeepSeek Harness session events |
|---|---|
| `session_meta` | session header (id, createdAt, cwd) |
| user `message` (human) | `user/message`, `source:{kind:"user"}` |
| injected context / `developer` role | `user/message`, `source:{kind:"plugin",plugin:"codex-import"}` |
| `reasoning` | `reasoning` block on `assistant/message` |
| assistant `message` / `agent_message` | `text` block on `assistant/message` |
| `function_call` / `custom_tool_call` | `tool-call` block + `tool/call` event |
| `*_output` items | `tool/result`, call-id matched within the step |
| `web_search_call` / `tool_search_call` / `image_generation_call` | balanced `tool/call` + `tool/result` pair |
| `turn_context.model` | `AssistantMessage.source.model` |
| first human prompt | `session/title` event (no auxiliary model call) |
| `event_msg` telemetry, `ghost_snapshot`, token counts | dropped (UI duplicates) |

Codex records a flat item stream; the harness wants it bracketed into
`turn/start → (user/message | step/start … step/end)* → turn/end`. The plugin
rebuilds that structure using Codex `turn_id` stamps where present, and human
message boundaries otherwise.

**Storage is the harness's own.** Sessions are written through
`ctx.sessionPersistence.create()` / `.append()` and grouped through
`ctx.workspaceRegistry.create()` / `workspace.attachSession()`. The plugin
never touches the session directory, the zstd container, or the workspace
registry file — physical encoding, path layout, durability, and workspace
accounting all stay where they belong, so a harness format change cannot
silently desync this plugin.

Repairs applied during conversion: dangling tool calls get a synthetic error
result (`TOOL_NOT_STARTED`) so no assistant message carries an unanswered
call; orphan tool outputs are dropped; non-JSON custom-tool input is wrapped
as `{"input": …}` so `tool/call.arguments` stays parseable; images become a
text placeholder (harness image blocks need attachment-service references a
plugin cannot mint); Codex-compacted sessions import their **full
pre-compaction history**.

Sessions whose project directory no longer exists are imported but stay
ungrouped — a workspace must point at a real directory, which is the
harness's own rule.

## Verification

```bash
node test/verify.mjs        # grammar, argument parsing, mapping edges,
                            # + folds every real rollout through the harness
node test/integration.mjs   # boots real dsh-session, persistence and workspace
                            # plugins in a scratch root and imports through them
```

`verify.mjs` runs the harness's own `foldSurface` / `deriveEventMessage` — the
exact reconstruction path a resumed session uses. `integration.mjs` proves the
harness's real persistence accepts the headers and event batches this plugin
produces, and that the workspace registry accepts the resulting sessions.

On the author's machine: 679 real sessions, 196k+ reconstructed messages, zero
failures.

## Caveats

- DSH is in developer preview and pins its session format at version 0 with
  **no compatibility promise**. If a future harness refuses v0 logs, re-run
  the import — Codex originals are untouched.
- Resuming an imported session sends its history to whatever model DSH has
  configured; provider-specific replay state is not carried over.
- Requires Node ≥ 22 (the harness's own floor).

## License

Source-available under a custom license — **not** an OSI-approved open-source
license. Summary (the license texts control):

| Who | Rights |
|---|---|
| Everyone | free noncommercial use, modification, redistribution (same license, keep notices) |
| **Individuals**, worldwide | additionally: **commercial use** |
| **DeepSeek & its partner enterprises** | additionally: commercial use, **closed-source/proprietary derivatives**, sublicensing — see the [supplement](LICENSE-SUPPLEMENT-DEEPSEEK.md) |
| Other organizations | noncommercial only; commercial use requires a separate license from the author |

[LICENSE.md](LICENSE.md) · [LICENSE-SUPPLEMENT-DEEPSEEK.md](LICENSE-SUPPLEMENT-DEEPSEEK.md) · [NOTICE.md](NOTICE.md)
