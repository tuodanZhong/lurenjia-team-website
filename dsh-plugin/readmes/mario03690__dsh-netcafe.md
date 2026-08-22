# dsh-netcafe

[![China: reachable](https://ainetcafe.com/badge/china/ainetcafe.com)](https://ainetcafe.com/watch-cn?s=badge-own)

A [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) **bundle** that adds
[AI NetCafé](https://ainetcafe.com)'s hosted outcome tools to your `dsh` profile in one install.

It is a thin configuration layer — it ships no tool code of its own. All it does is insert one
pre-configured `@deepseek-ai/dsh-mcp-client` row pointing at a remote MCP server, so you don't have
to hand-write the YAML. If you'd rather write those six lines yourself,
[the config is documented here](https://ainetcafe.com/mcp.html) and you don't need this package.

## What you get

Tools register as `mcp__netcafe__<name>`. **Start with `what_can_you_do`** — describe your task in
any language and it returns exactly which tools here do it, with ready-to-run calls (deterministic,
free, never rate-limited). The main endpoint exposes the curated core set; a few worth naming:

| Tool | What it does |
|---|---|
| `extract_invoices` | A batch of up to 20 invoices → one ledger-ready table. Every row is checked **in code** — net + tax must equal gross — and the batch total is re-added independently, so a row the model misread is flagged with the exact difference instead of quietly landing in your books. Mixed currencies get no batch total on purpose: adding them would be an accounting error. |
| `extract_statement` | Bank/credit statement PDF → structured transactions, **with an arithmetic reconciliation check** (opening + credits − debits = closing). If it doesn't balance, it says so and points at the row where the running total first breaks, instead of handing you clean-looking wrong data. |
| `extract_tables` | Tables out of PDFs, with schema alignment — give it a target column set and heterogeneous documents come back on the same columns. Rows it isn't sure about are flagged, not guessed. |
| `transpile_sql` | SQL between dialects (mysql, postgres, bigquery, snowflake, clickhouse, doris, starrocks, …). Deterministic — a real parser, not a model — so the same input always gives the same output, and syntax errors come back with line and column. |
| `create_task` (watch_reachability) | Subscribe a URL to **daily China-reachability checks for 30 days** — notified only on state change. Pair it with the live README badge: `![China](https://ainetcafe.com/badge/china/<host>)`, refreshed daily. Weekly public report: <https://ainetcafe.com/lab/china-weekly> |
| `china_reachability` | Whether a URL is reachable **from a real mainland-China network vantage point**, with latency, HTTP status and the IP that China's DNS resolves to. The server genuinely sits on a China Mobile backbone; this is not a guess from an overseas VPS. |
| `check_resume` | Whether an ATS can actually parse a résumé (text extractable, contacts findable, multi-column layouts, tables). Rule-based and reproducible — same file, same score tomorrow. |
| `remember` / `recall` | Cross-session memory. Keyed to your AllRouter key or an anonymous workspace token, so a later session — or a different machine — picks up where you left off. |
| `create_task` | Hand a recurring job to a hosted runner (watch a page, re-run a question on a schedule). It runs on our servers and notifies you only when the result actually changes, so nothing has to stay open on your side. |

Full list: <https://ainetcafe.com/tools>

## Or install just one pack

Each pack is also a standalone repo — install exactly one capability set, pay the context cost of nothing else:
[dsh-china-facts](https://github.com/mario03690/dsh-china-facts) ·
[dsh-watch](https://github.com/mario03690/dsh-watch) ·
[dsh-memory](https://github.com/mario03690/dsh-memory) ·
[dsh-docflow](https://github.com/mario03690/dsh-docflow) ·
[dsh-tables](https://github.com/mario03690/dsh-tables) ·
[dsh-imagegen](https://github.com/mario03690/dsh-imagegen) (image gen, free trial) ·
[dsh-adversarial-review](https://github.com/mario03690/dsh-adversarial-review) ·
[dsh-product-planning](https://github.com/mario03690/dsh-product-planning) ·
[dsh-code-review](https://github.com/mario03690/dsh-code-review)


One `dsh` profile rarely needs both spreadsheet cleanup and the Chinese lunar calendar, and every
tool description costs tokens on every session. So the same tools are also served as four focused
endpoints — pick one and you only pay the context cost of what you actually use.

| Pack | Endpoint | What it is |
|---|---|---|
| Tables | `/mcp/table` | **Reconciliation that refuses to guess.** Match a bank statement against a ledger with no shared reference — one invoice paid in instalments, one payment covering several invoices. Ambiguous splits are reported, never forced. Reads and writes real `.xlsx` (dates restored, leading zeros kept). Also: entity dedupe, table diff, messy-CSV cleanup. |
| Dev kit | `/mcp/dev` | JSON↔YAML, validate JSON, line diff, regex test, JWT decode, SQL dialect transpile, timezone and unit conversion. |
| Doc flow | `/mcp/docs` | Markdown → PDF / Word / PowerPoint / EPUB / HTML, and PDFs merged, split, rotated, watermarked. |
| China facts | `/mcp/cn` | Mainland reachability from a real China backbone, statutory holidays **including make-up workdays**, offline ID and mobile-number validation, lunar calendar. |

### Making a one-off check permanent

Every tool above is a single call and free. What is not free is having something **keep
running after your session ends** — re-checking a page, re-running a reconciliation each
month, watching whether an endpoint is still reachable from mainland China — and telling
you only when the answer **changes**.

```
create_task(kind="reachability", input="https://your-api.com")
```

That needs a workspace token (`?w=ws_...` on the MCP URL). The difference is not the
capability; it is who keeps it alive between your sessions.

To use one instead of the full catalogue, comment out the `mcp-netcafe` row in
`cordis.patch.yml` and uncomment the pack you want — the rows are already there.

All four are listed in the [official MCP registry](https://registry.modelcontextprotocol.io) as
`com.ainetcafe/netcafe-tables`, `-devkit`, `-docflow` and `-china`.

**Nothing in these four packs calls a language model or a third-party API.** They compute locally on
our own servers, so results are deterministic and repeatable, and they cannot break because someone
else changed their API. Anything involving counts or money returns its own arithmetic proof — and
says so plainly when the numbers do not reconcile, instead of handing back a table nobody can check.

## Install

```sh
dsh plugin --profile <your-profile> add dsh-netcafe
```

`@deepseek-ai/dsh-mcp-client` is a **peer dependency** — it ships with dsh, so in a normal install
you already have it. If your profile doesn't, add it explicitly:

```sh
dsh plugin --profile <your-profile> add @deepseek-ai/dsh-mcp-client
```

## Uninstall

```sh
dsh plugin --profile <your-profile> remove dsh-netcafe
```

That removes the bundle's layer; no state is left behind on your machine. Anything you stored with
`remember` lives on the server against your key — call `forget` first if you want it gone.

## Supported versions

- Built against `@deepseek-ai/dsh-mcp-client@0.0.1-rc.1`; **dsh v0.1 developer preview (released
  2026-08-13, Cordis v4) uses the same MCP client config shape**, which is the only surface this
  bundle touches. If a later preview changes it, open an issue — same-day fix.
- **dsh is in developer preview and its maintainers explicitly warn about compatibility-breaking
  changes.** This bundle deliberately depends only on the MCP client's config shape — the narrowest
  surface available — but if dsh renames or restructures that plugin, this will break until updated.
  Open an issue and it'll be fixed.
- The MCP server itself speaks protocol `2025-06-18` over Streamable HTTP and is versioned
  independently of dsh.

## Cost, quota and privacy

- **Free anonymous quota, no signup.** Every response reports the exact USD it cost.
- When the free quota runs out, the response tells you how to continue — either an
  [AllRouter](https://allrouter.ai) key in an `Authorization` header (billed to you at direct token
  rates), or a per-call x402 payment. Nothing silently fails.
- Documents you send are processed in memory and not retained. Memory you store with `remember` is
  kept against your key until you `forget` it.
- The URL in the bundled config carries `?s=dsh-plugin`. That is a **channel tag** so we can tell
  which distribution path actually gets used — it identifies the path, not you. Drop it by writing
  your own config row if you'd rather not send it.

## Disclosure

Built and maintained by the people who run ainetcafe.com — this is our own service, not a neutral
third-party integration. The tools have a free tier and paid usage beyond it.

## License

MIT

## Compatibility & permissions (at a glance)

| Signal | This plugin |
| --- | --- |
| **Runtime** | dsh v0.1 developer preview (2026-08-13, Cordis v4). Touches only the MCP client config shape — the narrowest surface available. Verified against a live endpoint on 2026-08-17. |
| **What runs locally** | Nothing. Ships one `cordis.patch.yml` row; there is no tool code, no build step and no lifecycle script in this package. |
| **Filesystem access** | None. |
| **Shell / process access** | None. |
| **Network access** | Outbound HTTPS to `ainetcafe.com` only, from the MCP client that dsh already ships. |
| **Credentials** | None required. No signup, no API key for the free tier. An optional AllRouter key, if you supply one, is sent by dsh as a request header and is never stored by us. |
| **Data retention** | Documents and prompts are processed in memory and not retained. |
| **Dependencies** | One peer dependency: `@deepseek-ai/dsh-mcp-client` (ships with dsh). |
| **License** | MIT (see `LICENSE`). |
| **Publisher** | The team that runs [ainetcafe.com](https://ainetcafe.com) — our own hosted service, free tier plus paid usage. Issues get a same-day reply. |

> A directory listing is not a security review. Read `cordis.patch.yml` — it is short enough to read in full in under a minute.
