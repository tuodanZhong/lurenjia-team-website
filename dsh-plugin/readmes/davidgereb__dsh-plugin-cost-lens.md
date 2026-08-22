# dsh-plugin-cost-lens

**Cost Lens** — DeepSeek API rates and per-session costs for dsh web.

- **Sidebar rate pill** (above Settings): current rate state (`Peak hours` /
  `Off-peak hours`; until the peak/off-peak schedule starts it shows `Peak
  hours` with the flat prices), an `Ends in: hh:mm` countdown to the next
  change, and a click-to-expand detail with `Input: $x.xxx/M · Output:
  $x.xxx/M`. The peak/off-peak windows are shown in **the browser's local
  timezone**. A small spinner shows while rates refresh; a warning dot +
  tooltip appear when the last update failed ("working with data from last
  update date").
- **Chat stats strip** (under the prompt box): `≈ $0.35 · 1.2M in · 80k out`
  for the active session.
- **Session rows + hover cards** (sidebar): a small cost next to the time
  field and a cost line in the hover card.
- **Schedule to off-peak**: long-press the send button to open a small menu
  and queue the draft for the next off-peak window start; scheduled prompts
  show above the composer (a distinct tint) with a cancel button. The host
  half keeps the queue and fires each prompt via the session's agent
  (`agent.followup`) — it works while the dsh web server is running, with no
  browser open.
- **Workspace cost totals** next to each workspace in the sidebar (sum of its
  sessions' costs).
- **Account balance** on the pill: shown in the expanded view and tooltip,
  with the last-updated time on hover; refresh interval configurable (5
  minutes default).
- **Config card** (Settings → Plugins → Configurable): rate refresh interval,
  balance refresh interval, backfill window, per-surface display toggles
  (session rows, session cards, chat stats, workspace totals), **Refresh now**,
  and **Recalculate costs** buttons — the plugin configuration page.

## Install / rebuild / revert

### From GitHub

One block — installs the plugin, registers the loader row, and applies the
served-bundle shims (session rows / hover cards and the long-press schedule
menu; they have no plugin slot, see [Shims](#shims) below):

```sh
dsh plugin --profile web add github:davidgereb/dsh-plugin-cost-lens --config.block-exotic-subdeps=false
PATCH="${DSH_HOME:-$HOME/.dsh}/profiles/web/cordis.patch.yml"
grep -q "name: dsh-plugin-cost-lens" "$PATCH" 2>/dev/null || cat >> "$PATCH" <<'EOF'

- insert:
    - id: ui-cost-lens
      name: dsh-plugin-cost-lens
EOF
node "${DSH_HOME:-$HOME/.dsh}/profiles/web/node_modules/dsh-plugin-cost-lens/scripts/patch-live-ui-workspace.mjs"
node "${DSH_HOME:-$HOME/.dsh}/profiles/web/node_modules/dsh-plugin-cost-lens/scripts/patch-live-ui-conversation.mjs"
```

Then **restart dsh web** (or just refresh the page if the host half was already
running). The shim scripts are idempotent — re-running is safe, and
`--revert` undoes them (the session-row pills and the long-press menu stop
showing if you skip this step).

> **pnpm ≥ 11 note.** The `--config.block-exotic-subdeps=false` flag lifts
> pnpm 11's default ban on git-hosted *transitive* dependencies — this
> plugin's dependency
> [`dsh-lib-context-injection`](https://github.com/davidgereb/dsh-lib-context-injection)
> is resolved that way. No config files to edit.

### From a local checkout

```sh
# 1. build
node scripts/build.js
npm install   # installs the git dependency (dsh-lib-context-injection)
node scripts/smoke-test.mjs
# 2. make the package resolvable by the profile (repeat for the lib dep)
dsh plugin --profile web link /path/to/dsh-plugin-cost-lens
dsh plugin --profile web link /path/to/dsh-lib-context-injection
# 3. register the loader row in cordis.patch.yml (see above)
# 4. apply the served-bundle shims (idempotent; --revert to undo)
node scripts/patch-live-ui-workspace.mjs
node scripts/patch-live-ui-conversation.mjs
```

Host-half (`lib/index.js`) changes require a dsh web restart; browser-bundle
changes (client.js and the shims) reach the GUI on a page refresh.

### Shims

The session-row and hover-card cost surfaces have no plugin slot, so Cost Lens
patches the served `dsh-client-ui-workspace` bundle; the long-press schedule
menu patches the served `dsh-client-ui-conversation` bundle. Apply both after
any dsh upgrade that re-serves those bundles:

```sh
node scripts/patch-live-ui-workspace.mjs            # session rows / hover cards / workspace totals
node scripts/patch-live-ui-conversation.mjs         # long-press send -> schedule menu
node scripts/patch-live-ui-workspace.mjs --revert   # remove (byte-exact)
node scripts/patch-live-ui-conversation.mjs --revert
```

### Revert

1. Remove the `ui-cost-lens` row from `cordis.patch.yml`.
2. `dsh plugin --profile web rm dsh-plugin-cost-lens`
3. Revert the shims (`node scripts/patch-live-ui-workspace.mjs --revert` and
   `node scripts/patch-live-ui-conversation.mjs --revert`).
4. Restart dsh web.

## Data model

The host half owns everything data-related:

- **Rates**: fetched from the official pricing page
  (`api-docs.deepseek.com/quick_start/pricing`), parsed into a *schedule* of
  pricing generations (the current flat table and the upcoming peak/off-peak
  table with its UTC windows), cached (TTL configurable, 1 day default),
  persisted, and served to the browser over `/cost-lens/api` (JSON RPC) and
  `/cost-lens/events` (SSE). A failed update keeps the last good data and
  marks it stale.
- **Per-session costs**: a `costLens` session-projection unit — a pure
  incremental fold that prices every `assistant/message` usage record
  (uncached input, cache-read, cache-write, output) at the rate in effect at
  that turn's timestamp, using the message's reported model. The fold state is
  persisted by the existing session-projection-cache, so costs are
  **accumulated, not recomputed per page load**; new tokens just extend the
  fold. **Recalculate costs** re-registers the unit at a bumped stateVersion,
  forcing a full refold with the current schedule (and discards stale cache
  rows).
- **Backfill**: on activation, sessions active within the backfill window
  (7 days default) are folded asynchronously in chunks. The projection
  `stateVersion` is persisted across restarts, and cache rows written at a
  stale version (after a recalc or a plugin version change) are re-folded
  automatically on activation — so per-session costs and their pills survive
  server restarts.

> **⚠️ Prices are an approximation.** The per-session numbers are computed
> from the usage fields the session log records (input / cache-read /
> cache-write / output tokens) priced at the *published* per-token rates.
> They are a good estimate for tracking spend, **not an exact bill**:
> caching in particular is not directly observable from the logs — a turn's
> reported `cacheReadTokens` is the model's own accounting, the published
> cache-hit/cache-miss split is a simplification, and DeepSeek's actual
> billing can apply discounts or rounding the published table does not
> capture. Expect the totals to be close but not identical to the API
> invoice; the rate pill's per-model prices are the published list prices,
> not what you were actually charged.

## Layout

```
dsh-plugin-cost-lens/
├── package.json              # dsh.client web plugin declaration
├── lib/                      # generated artifacts
│   ├── index.js              # host half
│   ├── client.js             # browser bundle
│   └── ui-workspace-shim.js  # shim for the served ui-workspace bundle
├── src/
│   ├── node-source.js        # host half source (single file)
│   ├── client-source.js      # browser half source (single file)
│   └── ui-workspace-shim.js  # shim source
└── scripts/
    ├── build.js              # generate lib/ from src/
    ├── patch-live-ui-workspace.mjs  # apply/revert the ui-workspace shim (byte-exact revert)
    ├── patch-live-ui-conversation.mjs  # apply/revert the ui-conversation shim
    └── smoke-test.mjs        # node logic + client registration + shim tests
```

## How it's wired

| Surface | Seat / mechanism |
|---|---|
| Sidebar rate pill | `sidebar.footer.action` list slot (id `cost-lens-rate`) |
| Chat stats strip | `conversation.composer.dock` list slot (id `cost-lens`) |
| Config card | `settings.plugin.item` list slot (id `cost-lens`) — the Configurable Plugins page |
| Session row cost | live shim in the served ui-workspace bundle (rows expose no slot) |
| Hover card cost | same shim |
| Host RPC / push | `/cost-lens/api` + `/cost-lens/events` routes (webServer) |
| Shared client store | `window.__dshCostLens__` (uSES store for React + the shim) |

## Policy source

https://api-docs.deepseek.com/quick_start/pricing — peak hours
**01:00–04:00 and 06:00–10:00 UTC**, off-peak at half the peak rates, taking
effect 2026-08-16T16:00:00Z. Before that date the flat table applies; the
indicator shows `Flat rate` and the fold prices by each turn's timestamp, so
history stays correctly billed across the transition. If DeepSeek changes the
windows/prices, the fetch picks the new schedule up (or use **Refresh rates
now**); the bundled default schedule in `src/node-source.js` is the fallback.

The parser handles both page layouts: the pre-transition page (flat table,
"will be updated to peak" + effective-date sentences, one model per table row)
and the post-transition page (peak/off-peak table only — models in a header
row, one price column per model). Once the page stops listing the flat era,
the flat generation is carried over from the bundled default (bounded by the
known transition instant), so historical turns before the switch keep their
correct flat pricing after a recalc or on fresh installs.

> **Compatibility.** Tested against **dsh `0.1.0-rc.6`** on Node.js
> **v24.19.0** (dsh web profile). Older or newer dsh releases may change the
> internals this plugin hooks into — check the changelog before upgrading.

---

> **⚠️ AI-generated, provided as-is.** This project was written with the
> assistance of an AI. It is provided **AS IS** without warranty of any kind,
> express or implied. The author cannot be held responsible for any damage,
> data loss, or misbehaviour that results from using it. Use at your own risk.
