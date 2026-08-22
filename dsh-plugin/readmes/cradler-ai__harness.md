# Cradler Harness

[DeepSeek Harness](https://github.com/deepseek-ai/dsh) (`dsh`) — a coding agent that runs
on your own machine — with [Cradler Router](https://cradler.ai/router) already set up.
Clone it, pass your key, and the agent opens with 24 models behind it.

```sh
git clone https://github.com/cradler-ai/harness.git
cd harness
node start.js sk-cr-your-key
```

That is the whole setup. No model provider to register, no base URL to paste, no
`settings.yaml` to learn. The first run installs `dsh` from npm and opens its web UI;
later runs remember your key, so `node start.js` on its own is enough.

Get a key at [cradler.ai/dashboard/router](https://cradler.ai/dashboard/router). A `$0`
balance still reaches the free model, so the first run always produces something.

Requires [Node.js](https://nodejs.org) 22.19+ or 24+.

## The agent is dsh's — we only fill in two settings

This repository publishes no package and forks no code. It installs the official
`@deepseek-ai/dsh` release and supplies the configuration a Cradler user would otherwise
type by hand:

| What | Value |
|---|---|
| Model route | `https://router.cradler.ai/v1` as a `cradler` provider |
| Models | every model your account can reach, read live at setup — not a hardcoded list |
| Default model | the best your balance allows; the free model at `$0` |

Everything else — the agent, its tools, its UI, its updates — is upstream's.

## What it writes

| Path | What |
|---|---|
| `~/.cradler/harness/settings.yaml` | the provider block above, in a **dedicated harness home** so your existing `~/.dsh` is never touched |
| `~/.cradler/harness/key` | your key, owner-only (`0600`); `--no-save` skips it and reads `$CRADLER_ROUTER_KEY` instead |

Your key is not in `settings.yaml`: the config references the `CRADLER_ROUTER_KEY`
environment variable (`apiKeyEnv`), and the launcher passes it to `dsh` at spawn time.

Run it again any time — it re-verifies the key and refreshes the model list. A model you
picked in the web UI's settings page survives the rewrite; `--reset` starts clean.

## Where the code runs

**On your machine.** `dsh` is a local coding agent: it reads and writes your files and
runs shell commands, like any other terminal-based agent. Cradler serves only the model
requests — we never see your files, your repository, or your commands.

Two consequences worth stating plainly:

- The web UI binds `127.0.0.1` by default. **Do not put it on a public address.** `dsh`
  ships no authentication, so a non-loopback bind hands anyone on that network a shell on
  your machine. That is documented upstream, and it is why this is a local tool rather
  than a hosted service.
- Sandboxing is `dsh`'s to provide. Its process sandbox governs file effects only —
  network and process visibility are outside it — so treat the agent as you would treat
  running a script someone sent you.

## Options

```
node start.js [sk-cr-key] [options] [-- dsh args…]

--model <id>     default model (otherwise the best your balance allows)
--port <port>    web UI port (0 lets the OS pick)
--host <host>    web UI bind host (default 127.0.0.1 — read the section above first)
--home <dir>     harness home (default ~/.cradler/harness)
--reset          rewrite settings.yaml from the live catalog
--no-save        do not store the key on disk; read it from $CRADLER_ROUTER_KEY instead
--print-config   print the settings.yaml that would be written, then exit
--setup-only     configure and verify, but do not launch
```

Anything after `--` goes straight to `dsh`, so its other profiles are one flag away:

```sh
node start.js -- --profile headless "run the tests and summarise failures"
```

`node --test` runs this repository's own suite.

## Models

Whatever your Cradler Router account can reach — Claude, GPT, Gemini, DeepSeek, Grok —
through one key and one bill. Because the list is read from your account instead of
hardcoded here, a new model on the Router appears on your next run.

Billing, usage and top-ups live in the
[Router console](https://cradler.ai/dashboard/router).

## Uninstall

```sh
rm -rf ~/.cradler/harness   # config and saved key
rm -rf harness              # this clone, dsh included
```

Nothing is installed globally and nothing else is written.

## Credits

[DeepSeek Harness](https://github.com/deepseek-ai/dsh) is MIT-licensed software by
DeepSeek. All credit for the harness belongs upstream, and bugs in the agent itself
belong in their issue tracker. `dsh` is pinned here to an exact version we have tested
end to end, because it is a `0.1.0-rc` developer preview whose interfaces still move.

MIT © Cradler. See [NOTICE.md](NOTICE.md).
