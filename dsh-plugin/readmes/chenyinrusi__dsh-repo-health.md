# repo-health

> Read-only repository health scanners: definition drift, unwired-module reachability, prompt bloat, evidence-gate calibration, and registration completeness — as a CLI and an MCP server.

A codebase rots silently. The most damaging defects are the ones no test, type checker, or linter catches:

- a concept defined in two places where only one copy gets updated (**drift**),
- a module written but never wired up (**unreachable**),
- a fixed-injected prompt segment quietly eating the context (**bloat**),
- an extension point that exists but is never registered (**registration**).

`repo-health` is five read-only scanners that watch for exactly these. It is the extracted, generalized core of the quality-guard tooling behind a large production agent system, repackaged so any repository can run it.

## Install

```bash
pip install "dsh-repo-health"        # CLI
pip install "dsh-repo-health[mcp]"   # + MCP server
```

Requires Python 3.11+ (the `registration` scanner uses `tomllib`; the others run on 3.10+).

## Quick start

```bash
repo-health drift --root /path/to/repo           # definition drift report
repo-health reach --root /path/to/repo           # unwired-module report
repo-health prompt-bloat --root /path/to/repo    # prompt segment shares
repo-health evidence --path logs/evidence_gate.jsonl
repo-health registration --root /path/to/repo --config registration.toml
repo-health all --root /path/to/repo             # run every scanner
```

Every scanner also ships a `--selftest` that verifies the tool itself against a
synthetic fixture before it is trusted to judge your code — the predecessor of
these scanners shipped versions that produced pretty-but-wrong numbers, and
only known-answer fixtures caught them.

## The five scanners

### `drift` — multi-source definition drift

Detects the same name defined in more than one place with overlapping member
structure, and flags it when one copy changes but the other does not.

- **A class (guarded)**: same name *and* structure overlap ≥ 0.5 — watched for drift.
- **B class (not guarded)**: same name, disjoint structure — a name collision, confusing but not a data hazard.
- **Sync changes pass.** If someone diligently updates *both* copies, that is correct behavior; a guard that punishes it gets disabled.

```bash
repo-health drift --root .                      # report
repo-health drift --root . --write-baseline     # freeze a baseline
repo-health drift --root . --check              # exit 1 on drift / new pairs
```

### `reach` — unwired-module reachability

Builds the import graph and BFS-searches from startup entrypoints
(`__main__.py`, `if __name__ == "__main__"` guards, `main.py`, launch scripts).
Modules that cannot be reached are "wired but dead".

Its baseline carries *auditable reasons*: every unreachable module needs a
structured `{verdict, anchor}` entry, validated deterministically (V1–V7) so a
single wrong reason can never permanently hide code from every mechanism.

```bash
repo-health reach --root .                      # report
repo-health reach --root . --write-baseline     # freeze
repo-health reach --root . --check              # exit 1 on new unwired modules
repo-health reach --root . --audit-reasons      # validate baseline reasons
```

### `prompt-bloat` — prompt segment share baseline

Reads prompt-inspection JSONL logs (`{segments: [{name, pct, kind}]}`) and
watches the **median share** per segment, not the absolute size (absolute size
varies naturally with task complexity; share reflects structural bloat).

```bash
repo-health prompt-bloat --root . --check --json
```

### `evidence` — evidence-gate decision log calibration

Summarizes a decision log (`{passed, suggested_action, tool, issues}` JSONL) to
answer "is the gate calibrated yet?" — insufficient samples or a
false-positive-prone tool block any conclusion.

### `registration` — config-driven registration completeness

Declares your architecture's extension points in a TOML config and verifies
every defined item appears in its registry. See
[`config/registration.example.toml`](config/registration.example.toml) for an
annotated example covering agent roles, checkers, API routers, sidebar pages,
and LLM providers.

## MCP server (DeepSeek Harness & any MCP client)

```bash
pip install "dsh-repo-health[mcp]"
python -m repo_health.mcp_server
```

Exposes the scanners as read-only MCP tools (`drift_scan`, `reach_scan`,
`reach_reason_audit`, `prompt_bloat`, `evidence_calibration`, `registration`).
Register it in DeepSeek Harness's MCP settings (or any MCP client) to let an
agent diagnose its own repository. Large repositories may exceed MCP's default
tool timeout — pass narrower `root` values or raise the client timeout.

## Methodology (why this is not "yet another linter")

The scanners share a discipline learned the hard way:

1. **Watch events, not states.** "Duplicated" is a state; "one side changed and
   the other didn't" is the event that actually corrupts data.
2. **Guard must not punish correct behavior.** Sync updates pass; else the
   guard gets disabled within a week.
3. **Never freeze a baseline from insufficient samples.** A median from three
   records is not a fact — a baseline frozen from it is false confidence.
4. **Reasons must be checkable.** Free-text baseline justifications are how
   code permanently hides from every mechanism; make them `{verdict, anchor}`.
5. **Self-test the scanner before it judges anything.** Known-answer fixtures
   are the only thing that caught the predecessor's wrong-but-plausible output.

## Known limitations

- `drift` scans Python only (`.py` under the configured package dirs).
- `reach` is module-granular: a reachable module whose functions are never
  called is not reported; dynamic imports (`importlib`, plugin loaders) are
  invisible and belong in the baseline.
- `evidence` and `prompt-bloat` consume a specific JSONL schema; adapt your
  logger to emit it (examples in the docstrings).

## License

MIT © 2026 Chen (Jarry) Pan
