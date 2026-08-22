# OpenHarness Find Plugin

A DeepSeek Harness plugin that discovers, installs, and upgrades plugins from
the curated [OpenHarness Plugins](https://github.com/MicroSpotlight/openharness-plugins) catalog.

The plugin contributes three surfaces:

- `openharness_find_plugins`, a read-only model tool for catalog search.
- **Discover**, a Web UI tab under **Settings → Plugins** with search, filters,
  plugin details, confirmation, operation status, cancellation, and activation state.
- `/openharness-find/v1`, a same-origin Host API that owns Catalog validation,
  installed-state detection, and profile mutations.

The browser submits only a plugin name, version, Catalog revision, and
`install`/`upgrade` intent. The Host rereads the Catalog and derives either an
exact npm version or a GitHub repository pinned to a 40-character commit. It
never accepts a package spec, URL, command, profile, or working directory from
the browser.

Profile mutations run through a Runtime Adapter. The default adapter reuses the
active DSH entry with `shell: false`; OpenHarness can provide a managed adapter
for its packaged runtime and Supervisor. Operations are asynchronous and use a
single mutation lock, process-tree cancellation, a bounded timeout and output,
profile metadata snapshots, post-install verification, and controlled rollback.

Installed and upgrade state requires an exact distribution package match, or a
canonical name corroborated by the normalized repository. Conflicts and bare
names remain `conflict` or `unknown`, and never enable installation. Semantic
versions distinguish installed, upgrade available, and a newer local version.

The Client obtains environment capabilities, Catalog data, installed state, and
operation state exclusively from the same-origin Host API. If that API is not
available or returns an invalid response, the Client reports an error and does
not call another Catalog or installation endpoint. Every profile mutation goes
through the Host validation, locking, and rollback path.

The default DSH Runtime Adapter reports a successful client-only install as
requiring a page reload. A plugin with Host components requires a Host restart;
a managed OpenHarness adapter may perform activation or restart directly.

## Install from a checkout

Build the package, then add it to the DSH Web profile:

```sh
pnpm install
pnpm build
dsh plugin --profile web add .
```

Catalog Git revisions include the built `lib` files and do not run lifecycle
build scripts during installation. This keeps pnpm's build allowlist closed in
the user's DSH profile. Release builds do not include source maps.

Alternatively, test without changing a profile:

```sh
dsh web --patch ./cordis.patch.yml
```

## Development

```sh
pnpm install
pnpm typecheck
pnpm test
pnpm build
```

The default catalog endpoint is:

```text
https://microspotlight.github.io/openharness-plugins/catalog/v1/catalog.json
```

The Host API exposes:

```text
GET  /openharness-find/v1/environment
GET  /openharness-find/v1/catalog
GET  /openharness-find/v1/installed
POST /openharness-find/v1/operations
GET  /openharness-find/v1/operations/current
GET  /openharness-find/v1/operations/{id}
POST /openharness-find/v1/operations/{id}/cancel
POST /openharness-find/v1/restart
```

Mutation routes require a direct loopback connection and an `Origin` matching
`Host`. Forwarded requests are rejected.

## Supported Runtime

The initial release targets DeepSeek Harness `0.1.0-rc.6`. DSH is in developer
preview, so compatibility is intentionally pinned and tested rather than
assumed across release candidates.

## License

Apache License 2.0.
