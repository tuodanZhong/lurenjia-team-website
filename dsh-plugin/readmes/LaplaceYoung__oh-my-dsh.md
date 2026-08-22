<p align="center">
  <strong>oh-my-dsh</strong>
</p>

<p align="center">
  <strong>Every capability the peer harnesses ship, as DSH plugins.</strong>
</p>

<p align="center">
  <a href="plugins"><img src="https://img.shields.io/badge/plugins-530-3FB950?style=flat&colorA=222222" alt="plugins"></a>
  <a href="plugins"><img src="https://img.shields.io/badge/tests-3731-3FB950?style=flat&colorA=222222" alt="tests"></a>
  <a href="e2e"><img src="https://img.shields.io/badge/e2e-2183%2F2183-3FB950?style=flat&colorA=222222" alt="e2e"></a>
  <a href="https://www.typescriptlang.org"><img src="https://img.shields.io/badge/TypeScript-3178C6?style=flat&colorA=222222&logo=typescript&logoColor=white" alt="TypeScript"></a>
  <a href="https://www.npmjs.com/package/@deepseek-ai/cordis"><img src="https://img.shields.io/badge/protocol-%40deepseek--ai%2Fcordis-orange?style=flat&colorA=222222" alt="protocol"></a>
</p>

<p align="center">
  A capability library for <a href="https://github.com/deepseek-ai/deepseek-harness">DeepSeek Harness</a> (DSH) —
  open all the way down, never touching the agent loop.
</p>

The capability surface for the DSH agent, ported from the harnesses that got it right. Every
plugin registers through a documented extension seam — never a patch to the skeleton, never a
hot-path tax.

**530** plugins · **3731** tests · **2183/2183** e2e registration checks · **6/6** live-session
checks against a real DeepSeek model.

> [!NOTE]
> oh-my-dsh is a **capability library**, not a fork. Each plugin adapts one gap from a
> peer harness (Claude Code, Oh-my-pi, kimi-code, opencode, Codex CLI, …) into a drop-in DSH
> plugin. The full gap ledger lives in [`GAP-LEDGER.md`](GAP-LEDGER.md).

## The capabilities, _adapted_.

### 01 · Deep research, wired to `ctx.web` + `ctx.llm`

`deep-research` decomposes a compound question into sub-questions, searches and fetches sources
in parallel through DSH's portable web seam, and synthesizes a cited report. Configure a
`provider` + `model` and synthesis runs through the LLM; leave them unset and a deterministic
template report still lands — every path degrades gracefully, none require a real key to test.

### 02 · Tower — multi-agent orchestration with conflict coordination

`tower` dispatches a list of instructions to a team of worker subagents that iterate one repo
concurrently. Every worker reads the shared team brief (so M1 owns the README while M2 reads it),
then a reviewer — always on the primary model — re-reads their outputs and flags conflicts.
Ported from kimi-code's `/tower` (MoonshotAI/kimi-code#2633). `fleet-orchestrator`,
`microagents`, and `specialist-agents` cover the long tail of fan-out shapes.

### 03 · Pre-write secret scanning as a monotonic guard

`secret-scanner` registers a `tools.guard` that denies `write`/`edit`/`apply_patch` calls whose
arguments carry API keys, tokens, or private keys — before any filesystem mutation, and with no
allow-override path. Conservative patterns, low false-positive. `repo-secret-audit` sweeps what's
already on disk; `git-secret-gate` watches what's about to be committed.

### 04 · Stream rules that catch the model mid-drift

`stream-rules` injects regex-matched reminders into the stream the moment the model goes
off-script — oh-my-pi's time-traveling stream rules, rebuilt on DSH's event waterfall.
`semantic-compression` shrinks context while preserving meaning; `cache-aware-compaction` and
`compact-fidelity` keep the compression honest.

### 05 · GitHub workflow over the shell seam

`github-workflow` wraps the `gh` CLI (`issue create/list`, `pr list`) through `ctx.shell`
(`resolve → run`), with a `child_process` fallback for standalone use. Structured `--json` output
parsed on the way back. `pr-description` and `pr-review-bot` take it from triage to review.

### 06 · Lineage & kanban projections

`branch-tree` renders fork lineage (parent→children, ancestry, fork points) and `task-board`
projects a parallel-task kanban (columns, blocked reasons, dependency tree) — both cycle-safe.
Data lives in-session; persistence is a consumer step.

### 07 · Sessions, _the whole lifecycle_

Twenty-four `session-*` plugins cover the arc no single harness owns end to end: `session-snapshot`
and `session-rewind` for checkpoint rollback, `session-share` for cloud links, `session-search` /
`session-retrieval` / `session-semantics` for getting old work back, `session-rbac` for who may
touch what, `session-replay` and `session-export` for audit. opencode's share model, Codex's
rollout vocabulary, and Claude Code's checkpoint — reconciled in one namespace.

### 08 · Approvals with a vocabulary

Six `approval-*` plugins turn permission prompts into policy: `approval-vocabulary` remembers
once/always/reject per tool (Codex CLI's `/approvals`), `approval-queue` and `approval-persist`
make decisions durable and reviewable, `approval-diff` and `approval-binding` tie each decision to
the exact change it approved, `approval-grace` adds expiring trust. `autonomy-tier` sets the ceiling.

### 09 · Memory that survives the session

`memory-writeback` lands Claude Code's `CLAUDE.md` loop; `episodic-memory`, `procedural-memory`,
and `graph-memory` store what happened, what works, and how things connect; `memory-consolidation`
and `memory-promotion` move what repeats from raw recall into durable knowledge. Project-scoped by
default — what the agent learns about this repo stays with this repo.

### 10 · MCP, bridged _and governed_

Seven `mcp-*` plugins: `mcp-bridge` speaks the protocol, `mcp-registry` catalogs servers,
`mcp-trust` and `mcp-poison` decide what's allowed to answer, `mcp-capabilities` negotiates
surface, `mcp-browser` drives a browser server, `mcp-extension-ecosystem` keeps the whole thing
discoverable. The ecosystem without the supply-chain blind spot.

### 11 · A browser fleet, seven plugins deep

`browser-driver` at the wheel, then one plugin per concern: `browser-session`, `browser-a11y`,
`browser-form-fill`, `browser-network`, `browser-scraper`, `browser-visual-assert`. Not one
omni-tool — the same browser capability decomposed into seams you can mount independently.

### 12 · Red team, built in

`jailbreak-detector` and `injection-guard` watch the prompt stream, `sandbox-escape` and
`sandbox-intent` watch the tool surface, `adversarial-eval` and `redteam-orchestrator` run the
attacks on a schedule, `malicious-package-guard` and `supply-chain` watch what gets installed.
Security as plugins, not as a phase.

### 13 · Observability: traces, metrics, cost

`otel-genai-traces` and `otel-genai-metrics` emit OpenTelemetry GenAI semantic conventions;
`trace-waterfall-webui` and `trace-viewer` render them; `token-stats`, `cost-command`, and
`cache-hit-meter` answer "what did this session burn, and where". `perf-baseline` and
`perf-regression-detector` guard the harness itself.

### 14 · The discipline itself: seams, not surgery

Every plugin registers as a side effect (`ctx.effect()` / `ctx.on()`), declares its services via
`inject`, and splits capability into the **three-part seam**: `interface` (typed contract),
`implementation` (backend), `consumer` (model-facing tool). No agent-loop edits, no hot-path
allocation, no hardcoded knobs.

## Install

```bash
git clone https://github.com/LaplaceYoung/oh-my-dsh.git
cd oh-my-dsh
pnpm install
```

Plugins are ESM packages under `plugins/<name>` (`@oh-my-dsh/<name>`). Mount them in a DSH
`cordis.yml` composition:

```yaml
- id: omd-deep-research
  name: '@oh-my-dsh/deep-research'
  config:
    provider: deepseek-official
    model: deepseek-v4-flash
```

## Quick start

```bash
# 1. All tests + typecheck
pnpm test
pnpm typecheck

# 2. Registration verification — boots DSH, mounts 530 plugins, asserts 2183 checks
bash e2e/run-e2e.sh

# 3. Real session — full agent stack + all plugins + one real DeepSeek turn
DEEPSEEK_API_KEY=… node --import tsx e2e/run-real-session.mjs e2e/dsh-src
```

## Architecture

DSH is an all-plugin harness: the agent loop itself is a plugin, and new behavior lands through
documented seams — never by editing the skeleton.

| seam | purpose |
| --- | --- |
| `ctx.tools` | model-facing tools (`register` / `guard` / `restrict`) |
| `ctx.shell` · `ctx.fs` | shell + filesystem providers |
| `ctx.subagents` | child agents (`spawn` / `fork` / `acp` / `codex` / `claude-code`) |
| `ctx.workflows` | scripted multi-agent orchestration |
| `ctx.llm` · `ctx.web` | model routing + search/fetch |
| `ctx.sessionPersistence` · `ctx.sessionQuery` | durable sessions + query |
| event waterfall | `agent/pre-step`, `tools/pre-execute`, `session/event`, … |

### Discipline

- **Registration is a side effect** — `ctx.effect()` / `ctx.on()`; `register()` returns a disposer.
- **Three-part seam** — interface / implementation / consumer.
- **Explicit > implicit** — defaults live in `resolve(request): Spec`, not `?? default`.
- **Performance** — registration is light, hot paths stay allocation-free, listeners `next()`.

## The catalog, by domain

524 plugins in one namespace. Representative slices:

| domain | count | plugins |
| --- | ---: | --- |
| Sessions | 24 | `session-snapshot`, `session-rewind`, `session-share`, `session-rbac`, `session-replay`, … |
| Web UI | 19 | `webui-plugin-manager`, `webui-smart-diff`, `webui-usage-cost-dashboard`, `webui-virtualized-session`, … |
| Agent & orchestration | 12 | `tower`, `agent-hub`, `agent-teams`, `fleet-orchestrator`, `microagents`, `plan-mode`, … |
| Task management | 10 | `task-board`, `task-dependency-dag`, `task-queue`, `task-predict`, `task-results-inbox`, … |
| Prompt & model routing | 9 | `prompt-rewriter`, `prompt-optimizer`, `provider-router`, `provider-fallback`, `model-routing-policy`, … |
| Context control | 9 | `context-usage`, `context-inject`, `context-add-dir`, `context-pin`, `context-pruner`, … |
| Knowledge | 9 | `knowledge-spaces`, `knowledge-graph-curator`, `knowledge-recommender`, `knowledge-versioning`, … |
| Browser | 8 | `browser-driver`, `browser-a11y`, `browser-form-fill`, `browser-network`, `browser-visual-assert`, `url-summarize`, … |
| MCP | 7 | `mcp-bridge`, `mcp-registry`, `mcp-trust`, `mcp-poison`, `mcp-capabilities`, … |
| Review | 12 | `review-checklist`, `review-feedback`, `review-thread`, `pr-review-bot`, `diff-review`, `code-metrics`, `import-graph`, `dead-code`, `symbol-index`, `code-format`, … |
| Approval & policy | 6 | `approval-vocabulary`, `approval-queue`, `approval-diff`, `approval-grace`, `autonomy-tier`, … |
| Memory | 12 | `memory-writeback`, `episodic-memory`, `procedural-memory`, `graph-memory`, `project-memory`, … |
| Observability | 11 | `otel-genai-traces`, `otel-genai-metrics`, `trace-waterfall-webui`, `token-stats`, `cost-command`, `doctor`, … |
| Git & GitHub | 24 | `github-workflow`, `git-auto-commit`, `git-hooks`, `git-hygiene`, `git-secret-gate`, `git-surgery`, `git-blame`, `git-churn`, `git-submodule`, `git-remote`, `git-log`, `git-diff`, `git-config`, `git-status`, `git-branch`, `git-tag`, `git-switch`, `git-pull`, `git-push`, `git-merge`, `git-fetch`, `git-rebase`, `git-restore`, `git-revert` |
| Security & red team | 13 | `secret-scanner`, `jailbreak-detector`, `injection-guard`, `sandbox-escape`, `adversarial-eval`, `output-guard`, `license-checker`, `dependency-audit`, … |
| DevOps & infra | 22 | `docker`, `k8s`, `terraform`, `sqlite`, `redis`, `helm`, `psql`, `aws`, `npm-scripts`, `mysql`, `gcp`, `checksum`, `systemctl`, `azure`, `brew`, `journalctl`, `openssl`, `make`, `apt`, `ssh-keygen`, `df-du`, `gpg` |
| Audio & voice | 6 | `audio-transcribe`, `audio-tts-exec`, `voice-input`, `voice-session-ui`, … |
| Evaluation | 6 | `evals`, `eval-suite-registry`, `eval-case-mining`, `eval-dataset-manager`, `eval-report-clustering`, … |
| Documents & data | 15 | `pdf-parser`, `epub-reader`, `sheet-reader`, `csv-kit`, `ocr-extractor`, `word-reader`, `diagram`, `json-query`, `regex-tester`, `semver-compare`, `base64`, `uuid`, `file-diff`, … |

Everything under [`plugins/`](plugins) — every gap traced in [`GAP-LEDGER.md`](GAP-LEDGER.md).

## Peer harnesses

| project | ported capability surface |
| --- | --- |
| [Oh-my-pi](https://github.com/can1357/oh-my-pi) | deep research, orchestrator prompt, expert subagents, skills injection, stream rules, semantic compression, Agent Hub (`/agent`) |
| [Claude Code](https://code.claude.com/) | memory writeback, hooks, `CLAUDE.md`, checkpoint, rewind (`/rewind`), plan mode (`/plan`), computer use (`/computer`), subagent delegation (`/subagent`), code review (`/review`), MCP listing (`/mcp`), release notes (`/release-notes`), `/init`, `/memory`, `/add-dir` |
| [kimi-code](https://github.com/MoonshotAI/kimi-code) | `/tower` multi-agent orchestration, secondary-model routing, revisit + cleanup |
| [opencode](https://github.com/sst/opencode) | session model, MCP ecosystem, editor integration |
| [Codex CLI](https://github.com/openai/codex) | approval vocabulary, session snapshot, rollout/canary, `apply_patch` |

> Full mapping in [`GAP-LEDGER.md`](GAP-LEDGER.md) — 25 rounds, every gap traced to its source
> and state.

## Status
- [x] 530 plugins — typecheck 0 errors, 3731 tests green
- [x] e2e registration — 2183/2183 checks (530 plugins mounted in a live DSH composition)
- [x] real session — full agent stack + real DeepSeek turn passes 6/6

---

## Development

```bash
pnpm install          # workspace deps
pnpm test             # vitest across all plugins
pnpm typecheck        # tsc -b across all plugins
bash e2e/run-e2e.sh   # live DSH boot + registration surface + LLM smoke
```

Plugin conventions live in [`AGENTS.md`](AGENTS.md); seam contracts in
[`docs/seams-reference.md`](docs/seams-reference.md); the performance budget in
[`docs/performance.md`](docs/performance.md).

---

_made for harnesses that stay open_

- [GitHub](https://github.com/LaplaceYoung/oh-my-dsh)
- [Gap ledger](GAP-LEDGER.md)
- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)
