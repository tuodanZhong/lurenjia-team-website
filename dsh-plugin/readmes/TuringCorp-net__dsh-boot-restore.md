# dsh-boot-restore

DSH plugin: **auto-resume the last active (duty) session after service restart**, so scheduled tasks keep running unattended — no browser needed.

## Why

DSH's schedule subsystem delivers reminders only to a **live** session (session-local by design). A session becomes live when a browser opens it. After any service restart (daily auto-update, crash, reboot), every session is cold until a human opens the browser — scheduled tasks (hourly digests, health checks, maintenance) silently stop during that window.

This plugin closes that gap: on service start, it calls `ctx.agents.resume()` to bring the configured session back to live, restoring schedule delivery and the agent loop without any client connection.

## Install

1. Copy `index.cjs` to a stable path (e.g. `~/.dsh/plugins/dsh-boot-restore/index.cjs`).
2. Create config `~/.dsh/boot-restore.json`:
   ```json
   { "sessionId": "session-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" }
   ```
3. Mount in your web profile overlay (`~/.dsh/profiles/web/cordis.patch.yml`):
   ```yaml
   - insert:
       - id: boot-restore
         name: '/absolute/path/to/index.cjs'
   ```
4. Restart the service: `sudo systemctl restart harness.service`.

Logs (success / failure / retries) go to `~/.dsh/boot-restore.log`.

## How it works

```
service start → plugin apply (inject: agents) → setTimeout 10s
  → ctx.agents.resume({ resumeSessionId, agentOptions: { agentPreset } })
  → session live → schedule delivery resumes → tasks run unattended
```

- **Why 10s + retries**: avoids the cordis `ready` event race (the plugin may activate after `ready` already fired; `ctx.ready` access during activation throws — never touch un-injected proxy properties).
- **Why explicit `agentPreset`**: since rc.7, resume without an explicit preset fails prompt assembly (`{{model}}` has no value, section `deployment:persona`). Pass the session's preset id (check your session header or settings).
- **Idempotent**: if the browser attaches first, resume skips ("already live").
- **Failure-tolerant**: corrupt log / missing session → log and continue, never blocks boot.

## Version history

| Version | Change |
|---|---|
| v0.6 | resume with explicit `agentPreset` (rc.7 assembly fix) |
| v0.5 | "already live" recognized as success (no useless retries) |
| v0.4 | `inject: ['agents']` + setTimeout retries; fixed v0.3 crash (accessing `ctx.ready` throws "without inject") |
| v0.1 | initial prototype via `ctx.on('ready')` — subject to a ready-event timing race |

## Compatibility

- rc.6: works (v0.1+); preset auto-applied from session header.
- rc.7+: requires v0.6 (explicit `agentPreset`).

## License

MIT
