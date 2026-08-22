# FolioDrop Publish for DeepSeek Harness

Connect FolioDrop and publish user-approved agent output as a stable URL from
DeepSeek Harness. The plugin registers `foliodrop_connect` and
`foliodrop_publish`, and keeps the dedicated FolioDrop connection key in the
Harness credential seam.

## Scope

The plugin is HTML-first:

- Complete HTML is published without rewriting.
- Markdown, text, JSON, code, and SVG are converted into a portable,
  self-contained HTML page.
- The plugin does not read arbitrary local paths and does not claim to be a
  generic binary file host.
- Search indexing defaults to off and requires explicit consent.
- Every publish uses the Harness question UI for a final confirmation because
  it uploads content and creates an externally reachable URL. This still works
  when the Harness permission preset is `Full access`; that preset disables
  native tool approvals but does not suppress the plugin's explicit question.
- The publish origin is fixed to `https://foliodrop.app`; the credential is
  never sent to an operator-configured host.

## Installation

Install the tagged plugin source directly from GitHub:

```bash
dsh plugin --profile web add github:jaxxchen003/foliodrop-dsh-publish#v0.2.0
dsh --profile web --dump-config
```

The same release is also available as a pre-packed artifact:

```bash
dsh plugin --profile web add https://github.com/jaxxchen003/foliodrop-dsh-publish/releases/download/v0.2.0/foliodrop-dsh-publish-0.2.0.tgz
```

From a FolioDrop source checkout, use the local package instead:

From this repository:

```bash
dsh plugin --profile web add ./integrations/deepseek-harness
dsh --profile web --dump-config
```

When the package is also available from npm, the equivalent registry command
will be:

```bash
dsh plugin --profile web add @foliodrop/dsh-publish
```

The package ships plain ESM JavaScript, so installation does not execute a
`prepare` or other lifecycle build script.

The plugin package is distributed under the MIT License. This package-local
license does not change the license of the FolioDrop application outside this
directory.

## Connect FolioDrop

Ask the agent to connect FolioDrop, or start a publish with no configured key:

```text
Connect my FolioDrop account.
```

The plugin starts a loopback callback, registers a public OAuth client, opens a
one-time FolioDrop login/authorization URL, validates `state` and PKCE S256,
then exchanges the temporary OAuth credential for a dedicated long-lived
`DeepSeek Harness connection` key. The key is written directly to
`FOLIODROP_API_KEY` through `ctx.credentials.set` and never appears in the
conversation or tool output. FolioDrop revokes the temporary OAuth access key
and its refresh token as part of the exchange. If Harness cannot save the
long-lived key, the plugin makes a best-effort request to revoke that key too.

If the browser cannot open automatically, the Harness question shows the exact
one-time authorization link so it can be opened or copied. Reconnecting rotates
the previous DeepSeek Harness connection key.

Manual personal keys remain an advanced fallback:

```bash
export FOLIODROP_API_KEY='fd_...'
dsh --profile web
```

An environment-provided key is read-only. Remove or replace that environment
value before using automatic reconnect.

## Tool behavior

Ask the agent to publish content explicitly, for example:

```text
Publish this Markdown release note to FolioDrop as a visible work. Do not allow
search indexing. Return the share URL.
```

The tool accepts:

- `content` and `content_type`
- `title`, `description`, and optional code `language`
- `visibility` (`visible` by default or `hidden`)
- `search_indexing_consent` (`false` by default)
- optional `source_model`

Successful output includes the FolioDrop work id, slug, absolute share URL,
visibility, transformed format, byte size, and the fixed source attribution
`DeepSeek Harness`.

Before upload, the confirmation allows the user to keep the proposed settings,
switch a visible work to hidden, disable search indexing consent, or cancel.
Capacity failures offer FolioDrop upgrade and work-management recovery paths,
then retry the same approved payload once after the user confirms completion.
Paid-capability failures open the FolioDrop upgrade page and likewise wait for
an explicit “upgrade completed” confirmation before one retry.

## Error recovery

Known failures are separated into actionable categories: connection missing or
revoked, credential storage read-only, browser/callback unavailable, OAuth
registration or token exchange failure, confirmation unavailable, plan or work
capacity reached, payload too large, rate limited, FolioDrop temporarily
unavailable, network failure, and invalid server response. Errors never include
the API key or content body.

## Compatibility contract

This release is tested against DeepSeek Harness `0.1.0-rc.6`. Harness is in
developer preview, so an upgrade must re-verify all five integration seams:

- `defineTool` registration and output validation
- `ctx.credentials.resolve/set('FOLIODROP_API_KEY')`
- `ctx.userQuestions.ask(...)` for connect and publish confirmation
- loopback OAuth callback, DCR, PKCE, and token exchange
- failure closed without a question provider

The rc.6 profile installer can report missing peer warnings from
`@deepseek-ai/dsh-tools`; the release gate therefore verifies both the composed
bundle with `--dump-config` and a real runtime boot, not installation exit code
alone.

FolioDrop stores `sourcePlatform: DeepSeek Harness` on the work, so views can be
aggregated by publishing source.

## Verification

```bash
pnpm --dir integrations/deepseek-harness install --frozen-lockfile
pnpm --dir integrations/deepseek-harness test
npm pack --dry-run ./integrations/deepseek-harness
```
