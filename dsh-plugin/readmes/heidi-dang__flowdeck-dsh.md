# flowdeck-dsh

Native DeepSeek Harness integration, Cordis bundle, runtime broker, and execution host for FlowDeck.

## Architecture

```
FlowDeck (orchestration runtime)
  https://github.com/heidi-dang/FlowDeck
        │
        │ host-neutral public APIs
        ▼
flowdeck-dsh (THIS REPOSITORY — DSH adapter)
  https://github.com/heidi-dang/flowdeck-dsh
        │
        │ native DSH bundle / Cordis integration
        ▼
DeepSeek Harness (execution host)
  https://github.com/heidi-dang/deepseek-harness
```

### Ownership boundaries

**FlowDeck owns:**
Heidi orchestration, planning, task decomposition, DAG scheduling, workstreams,
adaptive concurrency, worktree management, leases, budgets, token reservations,
runtime routing decisions, runtime performance learning, governance decisions,
verification, evidence, integration, recovery, learning, scheduler state.

**DeepSeek Harness owns:**
User conversation, model-visible history, sessions, session log, agent loop,
LLM providers, model selection, subagent infrastructure, tools, commands, jobs,
permissions, filesystem, shell/terminal runtime, UI transport.

**This package owns:**
DSH bundle packaging, Cordis integration, DSH host adapters, DshWorkstreamExecutor,
Heidi ↔ DSH bridge, runtime broker integration, global model-lock enforcement,
FDX DSH tool bridge, DSH governance hooks, FlowDeck DSH commands,
DSH Web projections/events, DSH headless integration, conformance tests.

## Installation

### Web profile
```sh
dsh plugin --profile web add @heidi-dang/flowdeck-dsh
```

### Headless profile
```sh
dsh plugin --profile headless add @heidi-dang/flowdeck-dsh
```

## Package

The npm package declares the DSH bundle contract:
```json
{
  "dsh": {
    "bundle": {
      "patch": "./cordis.patch.yml"
    }
  }
}
```

DSH's plugin system reads this declaration and layers `cordis.patch.yml` into
the profile composition automatically after `dsh plugin add`.

## Development

```sh
npm install
npm run typecheck
npm test
npm run build
```

## Implementation Status

See [docs/flowdeck-dsh/IMPLEMENTATION_STATUS.md](docs/flowdeck-dsh/IMPLEMENTATION_STATUS.md).

## License

MIT — see [LICENSE](LICENSE).
