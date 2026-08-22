# dsh-plugin-warroom-garak

A **DeepSeek Harness** plugin that adds one model-facing tool, **`garak_scan`** — an authorized
[garak](https://github.com/NVIDIA/garak) baseline red-team sweep against a target LLM endpoint,
with a built-in authorization gate, a budget cap, and an auto-written **evidence report**.

Part of the **war-room** approach: garak owns the probes (the "weapons"); this plugin is the
orchestrator that runs them against an *authorized* target, keeps the run in the dsh session log
(auditable/replayable), and produces a compliance-ready evidence artifact.

> **v0 / developer preview.** Built against `@deepseek-ai/dsh-*` `0.1.0-rc.x` and modeled on the
> official `dsh-tool-web` plugin. Two seams are version-sensitive and may need a small fix on first
> build in your environment — both are commented in the source:
> 1. `defineTool` parameter/output schema DSL (`src/index.ts`)
> 2. garak report JSONL field names / hit detection (`src/garak.ts`)

## What it does

1. Refuses to run unless `authorization.authorized === true` with a non-empty `scope`.
2. Caps attempts per probe at `maxGenerations` (budget / circuit-breaker).
3. Spawns garak against your REST target, parses the JSONL report into per-probe hit rates.
4. Writes a one-page Markdown **evidence report** (target, scope, tool+time, per-probe table,
   overall hit rate, pointer to the raw garak report for reproduction).
5. Returns a summary + report path + metrics as the tool result (a durable session event).

## Prerequisites

- A working **DeepSeek Harness** install.
- **garak** on PATH (`pipx install garak` or `pip install garak`; verify `garak --version`).

## Build

```sh
# pin dsh-* deps to your installed dsh version first:  npm ls @deepseek-ai/dsh-tools
npm install
npm run build      # tsdown -> lib/
```

## Install into dsh

Add the plugin as an entry in your dsh profile / cordis config (the composition file that lists
plugins), then restart dsh:

```yaml
# in your dsh profile's cordis config (e.g. cordis.patch.yml / cordis.yml)
- name: 'dsh-plugin-warroom-garak'
  config:
    garakBin: 'garak'        # 'garak' (CLI on PATH), an absolute path to the garak console
                             # script (pipx/pip install), or 'python' to use `python -m garak`
    maxGenerations: 5
    reportDir: '.warroom/reports'
```

Confirm it mounted: `dsh --profile <yours> --dump-config` should list the entry, and the agent
should now have a `garak_scan` tool.

## Use (example tool call)

```jsonc
{
  "target_id": "staging-chatbot",
  "authorization": { "authorized": true, "scope": "staging API only, 2026-08", "authorized_by": "jaco" },
  "rest_config": {
    "rest": {
      "RestGenerator": {
        "uri": "http://127.0.0.1:8080/v1/chat/completions",
        "method": "post",
        "headers": { "Authorization": "Bearer $TOKEN", "Content-Type": "application/json" },
        "req_template_json_object": { "model": "target", "messages": [{ "role": "user", "content": "$INPUT" }] },
        "response_json": true,
        "response_json_field": "$.choices[0].message.content"
      }
    }
  },
  "probes": ["promptinject", "dan"],
  "generations": 3
}
```

The evidence report lands under `reportDir`. The raw garak report path is embedded for full reproduction.

## Safety

- **Authorized targets only.** The tool hard-refuses without an authorization scope.
- **No attack payloads in this repo** — garak provides the probes. This plugin only orchestrates,
  bounds, and documents. Defensive use (hardening your own / authorized systems) only.

## License

MIT. Wraps garak (Apache-2.0); built on DeepSeek Harness / Cordis (MIT).
