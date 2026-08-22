# @2nd1st/dsh-plugin-open-app

[![npm](https://img.shields.io/npm/v/%402nd1st%2Fdsh-plugin-open-app?logo=npm&label=npm)](https://www.npmjs.com/package/@2nd1st/dsh-plugin-open-app)
[![license](https://img.shields.io/npm/l/%402nd1st%2Fdsh-plugin-open-app)](LICENSE)
[![node](https://img.shields.io/node/v/%402nd1st%2Fdsh-plugin-open-app)](package.json)
[![open-mcp-apps](https://img.shields.io/badge/open--mcp--apps-%E2%89%A5v0.5.1-8A63D2)](https://github.com/2nd1st/open-mcp-apps)

Makes every [open-mcp-apps](https://github.com/2nd1st/open-mcp-apps) app **a place you go**
inside [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`): an Apps
section in the sidebar, one container per app with its own workspace and conversation, and
inline rendering when the model opens an app mid-chat.

| | |
|---|---|
| **Package** | `@2nd1st/dsh-plugin-open-app` on npm — MIT ([LICENSE](LICENSE)) |
| **Install** | `dsh plugin --profile web add @2nd1st/dsh-plugin-open-app` — one step |
| **Requires** | `dsh` with a web profile · **pnpm** on `PATH` (`dsh plugin` manages profile dependencies through it) · a running **open-mcp-apps v0.5.1+** · Node 22+ |
| **Platform** | dsh **web** (`dsh web`) — every surface it takes is a web slot |
| **Releases** | [CHANGELOG.md](CHANGELOG.md) |

> **Developer preview.** dsh is itself a `0.1.0-rc` preview, and this plugin tracks it
> closely — including six places where it reaches into dsh through no published seam (all
> six are listed under [What it reaches into](#what-it-reaches-into-and-what-breaks-if-dsh-moves),
> with what each degrades to). Expect breaking changes between releases, and pin a version
> if you need one that holds still.

![An app container — the app in its own tab, the agent's line under it, the composer below](docs/screenshot-app-container.jpg)

## Install

```sh
# add it — this is the whole install
dsh plugin --profile web add @2nd1st/dsh-plugin-open-app

# restart; plugin metadata is cached per name for the life of the process
dsh web
```

The package declares `dsh.bundle`, so `dsh plugin add` does not only put it in the
profile's dependencies — it appends it to `dsh.profile.bundles`, and the patch it ships
becomes a layer of your profile's tree. That layer inserts two rows: `open-app` (this
plugin) and `mcp-oma` (dsh's MCP client, pointed at the same engine, so the model can open
and build apps as well as you can). Bundle layers apply *below* your profile's own
`cordis.patch.yml`, so both rows stay yours to configure or switch off.

Nothing here changes what an app is allowed to do: the engine is a local process you
started, and the rows only say where it listens.

**Upgrading from a hand-written install** (before 0.1.1 the second step was pasting an
`- insert:` block yourself): delete those blocks for `open-app` and `mcp-oma` from your
profile's `cordis.patch.yml`, and remove the old package name —

```sh
dsh plugin --profile web remove dsh-plugin-open-app
dsh plugin --profile web add @2nd1st/dsh-plugin-open-app
```

A patch `insert` always appends: two layers inserting the same id are two rows, and dsh
refuses to boot such a tree (`duplicate loader entry id: open-app`) rather than running the
plugin twice. Keep your settings as [id-targeted overrides](#configuration) instead.

## Requirements

- **`dsh` with a web profile** (`dsh web`). Every surface this plugin takes is a web slot.
- **pnpm on `PATH`.** Not something this plugin depends on: `dsh plugin` is a thin forwarder
  that runs `pnpm` in the profile directory, so this is how any dsh plugin is installed.
  Without it the install command above stops at
  `dsh: pnpm not found on PATH — install pnpm to manage profile plugins` and exits 127.
  No minimum version is stated here because none has been measured.
- **A running open-mcp-apps engine with its HTTP face up** — `node src/http.mjs`, default
  port `8787`. The engine is a separate install ([its README](https://github.com/2nd1st/open-mcp-apps#readme)):
  it gives a model persistent, interactive UI apps backed by durable data collections,
  shared with every other host talking to the same engine. This plugin is the dsh face of them.
- **Engine v0.5.1 or newer.** That release carries the three seams the panel leans on:
  `?chrome=0` (the bare widget instead of the engine's own viewer bar), `?nav=intent`
  (an app→app link becomes a message to the host instead of a navigation inside the frame),
  and the standalone viewer's root `overflow-y:auto`. Against an older engine the plugin
  still works and degrades gracefully — each case is called out under
  [Known limitations](#known-limitations).
- **Optional, for per-app inline views:** start the engine with `OMA_DYNAMIC_TOOLS=1`, which
  is what makes it publish one `open_<app>` tool per app. The universal `open_app` tool
  is always covered.

Both opt-in query parameters are additive: an engine that has not heard of either ignores
it and keeps its own behaviour. Nothing else is asked of the engine, and no dsh source is
changed — the plugin runs entirely out-of-tree.

## Configuration

Every setting is optional; the defaults match a stock local engine and the `mcp-oma` row
the bundle ships.

Configure it from your profile's own `cordis.patch.yml` by naming the bundle's row id —
never by inserting the row again. An id-targeted patch **replaces** the key it names
rather than merging into it, so write the whole `config` you want:

```yaml
- id: open-app
  config:
    # Where the engine's HTTP face listens.
    engineBase: 'http://127.0.0.1:8787'
    # The `serverName` of the engine's mcp-client entry. It decides the
    # `mcp__<serverName>__` prefix the inline tool views are keyed on.
    serverName: 'oma'
    # Where the per-app workspace directories are made. One directory per app,
    # named after it. Defaults to $DSH_HOME/storages/open-app/apps.
    appsRoot: '~/.dsh/storages/open-app/apps'
    # The container's rules, carried as a system-prompt section on every
    # request a container's agent makes. Replaces the shipped app-only
    # prompt entirely (see below for what it has to keep doing). `{app}` is
    # the app's name and `{card}` the declaration card the host half builds
    # from the engine's registry. An empty string retires the rules: the
    # containers then run as ordinary dsh sessions that happen to have an
    # app in a tab.
    containerPrompt: |
      You live in the {app} app — this conversation is its container.

      {card}

      Never call open_app, app_html or any open_* tool here; the panel beside
      this chat is already showing the app. Answer in one sentence — that line
      is what the user reads on the status bar under it.
    # The one line a brand-new container opens with, which is only there to
    # end the blank state and to draw the first receipt onto the strip. It
    # carries no rules. `{app}` is substituted. Set it to an empty string to
    # open containers silently — they then stay blank until you speak, and
    # the app waits in a row above the composer instead of in its own tab.
    installMessage: 'What is in the app right now?'
```

Pinned apps and what each app's place is made of are kept per-browser in
`localStorage`, under `dsh-plugin-open-app:pins` and `dsh-plugin-open-app:containers`
(unscoped, and staying that way — the package moved to a scope in 0.1.1, but renaming a
storage key would silently unpin every app somebody had pinned).
Only the pins are irreplaceable: the workspace registration is the durable binding, so
clearing the container map costs nothing — the next visit re-adopts the same directory,
the same workspace and the conversation already accounted under it.

## Usage

An app is a place, not a page. Opening `shopping-list` opens the shopping list *and*
the talk about it; opening it tomorrow resumes both. So each app gets a dsh
**workspace** of its own — a directory the plugin makes under its apps root, registered
with dsh — and its conversation is created inside that workspace, never in one of
yours. Inside it:

- **Apps** — the app's UI, first in the view ring, with a one-line strip under it
  saying what the agent is doing right now.
- **Chat** — this app's conversation, still there when you come back.
- **Trajectory** — unchanged.
- The composer stays docked below all of them, so you can be looking at the app and
  telling the model to change it in the same breath.

In an app container the app is the reply: you say "mark the milk as bought" and the row
ticks itself, because the widget holds its own live connection to the engine. That is
why the strip under it is not a small chat window — it is the agent's presence. It shows
the tool being called in the same glance as the change it causes, and it makes the two
things you could otherwise miss impossible to miss: a question waiting for you, and a
failure.

A container is exclusive: inside an app's session the Apps tab shows that app and
nothing else. There is no way to browse out of it, because a container you can escape
is not a container — switching apps means going to the other app's node. The directory
of apps lives in the two places that are nobody's container: the sidebar's own overlay,
and the Apps tab of an ordinary chat session.

### What it adds

| | |
| --- | --- |
| **Apps section in the sidebar** | *All apps* (the directory), *App Store* (where new ones come from), and one node per pinned app. |
| **App containers** | Clicking an app node opens that app's workspace and its own session, with the app's UI on top and its history underneath. |
| **App mode** | A container's agent gets a prompt of its own — who it is here, the app's card (what it is, the collections its rows live in, their shape, the functions it declares), what it must not call, how short a reply should be. It is a system-prompt section, assembled fresh for every request in a session that lives in an app directory, and it costs an ordinary chat session nothing. The container's session also runs on an **App mode** preset, so dsh names the mode where dsh names modes. |
| **An opening line** | A brand-new container is asked one question — "What is in the app right now?" — because a session dsh has never been spoken to gets no view ring, and because the answer is the first line of the strip under the app. |
| **Apps tab ahead of Chat** | Registered at order `-10`, so the app leads and the conversation follows. Chat and Trajectory keep their seats. |
| **The agent's presence** | A one-line strip under the app: what the agent is doing right now (the tool it is calling, the answer arriving), what it last said, and — unmissably — when it is waiting for you or has failed. It reads as speech, not as source: the line is set in dsh's own content column and the model's markdown is read out flat, since nothing here can typeset it. Click it for the whole conversation. |
| **App workspaces stay out of your way** | The directories the plugin registers are hidden from the workspace tree and the New Session picker, and New Session never lands inside an app. |
| **App → app stays inside the model** | "Open X" from the App Store opens X's own container instead of navigating the store's frame (engine `?nav=intent`). |
| **Inline app rendering** | In an ordinary chat session, when the model calls `open_app` (or a per-app `open_*` tool), the tool card becomes the running app, with an **Open in Apps** button under it that takes you into the app's own container. That seat is for ordinary chats: inside a container the same call is what the opening prompt forbids, because the panel is already showing the app. |

That last seat is the one an ordinary chat sees most: no container, no workspace of its
own — the app simply arrives where the tool call was, and the conversation goes on around
it. The **Open in Apps** pill under the frame is the way onward: the card is a live app in
somebody else's conversation, and everything you can do to it there you can also do in its
own place, with its history under it and a composer aimed at it.

![Inline app rendering — an `open_app` tool call becomes the running app, inside an ordinary chat](docs/screenshot-inline.jpg)

## Troubleshooting

Every row below is explained in full further down; this table is the index, not a second
copy of the answer.

| Symptom | What it is | Where |
|---|---|---|
| dsh refuses to boot: `duplicate loader entry id: open-app` | A hand-written `- insert:` block and the bundle's row are two rows with one id | [Install → upgrading](#install) |
| Installed, but nothing appears | Plugin metadata is cached per name for the life of the process — restart dsh | [Install](#install) |
| The app panel is empty, or the directory is | The engine is not up, or is not on `engineBase` | [Requirements](#requirements) |
| An app made mid-session has no `open_<name>` tool yet | dsh's tool table does not re-sync; the universal `open_app` covers it | [Known limitations](#known-limitations) |
| The App Store's *Open* navigates its own frame | Engine older than v0.5.1 (`?nav=intent`) | [Known limitations](#known-limitations) |
| A tall app is cut off at the fold | Engine older than v0.5.1 (viewer root `overflow-y:auto`) | [Known limitations](#known-limitations) |
| A new container has no tab ring, app sits above the composer | The session is still blank; the opening line has not gone out | [Known limitations](#known-limitations) |
| The container's agent ignores the rules | `containerPrompt: ''` retires them; the rules are a system section, not a message | [The container prompt](#the-container-prompt) |

## How it works

The package ships both halves of a dsh plugin.

**The browser half** takes five slots dsh publishes for exactly this kind of
extension: `conversation.view` for the Apps tab, `conversation.input.dock` for the same
surface before a session has a view ring, `sidebar.footer.action` for the Apps section,
`shell.overlay` for browsing, and `tool.call.toolview` for the inline takeover. Nothing
is shadowed or replaced — every seat is an additive one.

Each app is a dsh **workspace**: the host half makes `<appsRoot>/<app>/` and the browser
half registers it (`workspaces.create({path})`, which adopts an existing directory
idempotently), then creates the app's session inside it. That is not decoration. dsh's
New Session reuses a workspace's idle blank session — so a container sitting blank in
*your* workspace is exactly the session your next New Session picks up, and your fresh
chat silently becomes the app's. Giving apps their own workspace puts that reuse where
it belongs: inside the app, where reusing its own idle session is the right answer.

The app's data does not live in that directory — it lives in the engine's store, shared
with every other host talking to the same engine. The directory is where the workspace
is anchored, and where the app's exported files will land.

Every app surface is an `<iframe>` pointed at the engine's own `/view/<app>` page. That
is a requirement, not a convenience: the engine answers its `/rpc` and `/events`
endpoints only for callers whose origin is its own, so a frame that loads the engine's
URL is trusted and a `srcdoc` frame — which would inherit the dsh page's origin — is
not. Loading the real URL is also what keeps the app's live updates working: the frame
holds its own SSE connection, so a change the model writes appears in the widget
without dsh mediating anything.

**The host half** exists because the same origin rule blocks the plugin's own React
tree from reading the app registry. It publishes a small API on dsh's web server —
same-origin with the page — and forwards a **whitelist** of read-only engine tools
(`list_apps`, `app_store_list`, `get_app`) from inside the dsh process, where a server-to-server
request carries no `Origin` header at all. The whitelist is the point: these routes
have none of the engine's own protection, so everything that writes keeps going over
MCP, where the host's permission prompts are.

It also owns two things the browser cannot own at all: the app directories, and the
container prompt. The prompt has to live here because a prompt section is a host-plane
registration — dsh assembles every request out of the sections registered on its own
context — and because the card in it is engine data the browser half could only reach
cross-origin. Its dependencies say as much: `webServer` for the routes, `systemPrompt`
for the section (a hard dependency: a dsh that could not carry the rules would run
containers with none), and `agentPresets` reached optionally, since the surface that
composes an agent per session is the Web one.

## The container prompt

An app container's agent behaves like it lives somewhere, and that comes from a prompt
of its own. open-mcp-apps writes its guidance for a **chat** host, where the core verb is
`open_app`: a model with no screen of its own puts an app on the user's by calling it.
Here the screen came first, so the container prompt replaces that posture — an identity,
a bounded set of verbs, one ban, and a reply contract.

**It is a system-prompt section, not a message.** The host half registers one section
with dsh's prompt registry (`ctx.systemPrompt.section`) and dsh renders it into every
request. The section is global and decides per request whether it has anything to say:
dsh hands the assembling agent to the section (`assembleContextFor`, `dsh-agent`), the
section asks whether that agent's session is working inside one of this plugin's app
directories, and answers with the empty string when it is not — which the assembler drops
before the prompt is joined. So an ordinary chat session carries no trace of this plugin,
not even a blank line, and a container carries the rules in the request's `system` field
where they belong.

Three things follow from that, and they are the reason it stopped being the opening
message it was through the plugin's first development builds:

- **It is current.** The prompt is assembled for every request, so upgrading this plugin
  re-rules every container that already exists, on its next turn. A message in the log is
  frozen the moment it is sent.
- **It survives compaction.** Rules in the message history are summarizable; a system
  prompt is not part of the history being summarized.
- **The first turn is the user's.** A container no longer spends a model call answering
  its own installation.

It is not free of the log, and pretending otherwise would be wrong: dsh snapshots the
rendered system prompt and the tool catalog into the session as a `request/header` event
whenever they CHANGE (reasons `initial`, `resume`, `change`). That is an audit record,
not conversation — it is not part of the message history the model is sent — but it is
why the app's card is served from a cache that only ever moves forward: a card that
flickered with every engine hiccup would write a header snapshot each time.

**The blank session is what the opening line is for.** A session dsh has never been
spoken to is `blank`, and a blank session gets no view ring, no tab strip and no header:
the app has to live in a row above the composer, under the hero greeting, in a column
laid out for a chat that has not started. Everything awkward about that state comes from
one fact — the session is empty. So a fresh container is asked one question, and from
that moment it is an ordinary session with the app in its own tab. The question is also
the strip's first line: what the model answers is what the user reads under the app.

**App mode** is the same fact said in dsh's own vocabulary. A container's session is put
on an `app-mode` agent preset while it is still blank (dsh accepts a preset only then),
which is what the new-session chip and the session header report. The preset is a copy of
whatever preset your deployment defaults to, made once through dsh's own authoring path
the first time this plugin boots — a container is an ordinary agent with an app in front
of it, and hand-writing a composition would quietly take away tools it has today. It is a
label, and nothing load-bearing hangs on it: the rules are keyed on the app directory, so
switching a container back to Standard mode changes what the header says and nothing else.
Delete the preset and the next boot copies it back from the current default; a deployment
that composes no preset roster at all (the TUI) simply has no label to show.

One default cannot be copied that way. A preset is composed once per process, and dsh's
`cordis` preset (创造模式) registers Host Cordis inspect providers into a *process-global*
registry — so a duplicate of it throws `already registered` and can never mount, because
the original is always mounted first: it is what the session was created on. When that is
your default, the first container to be labelled tells the host half so, the copy is
re-made from the first preset your deployment lists that is neither the default nor this
one (its own ordinary agent, `standard` in a stock dsh), and the label lands on that same
container. The `preset.yml` beside the composition says which preset it came from and why.
Containers made before the repair keep the agent they started on — dsh fixes a session's
preset the moment it stops being blank — so it is the next container that shows the label.

**The card** is assembled by the host half from `list_apps` and the app's own declaration
(`get_app` slot `manifest`): name, version, purpose, the collections its rows live in and
the shape of those rows, and — only when the app declares them — its functions, with the
`call_function` call shape spelled out. It is deliberately short, because it rides in
every request this container ever makes, so it states schema and never sample data.
Measured on the shipped apps the card runs 194–474 characters, which puts the whole
prompt at ~1,300 characters (~330 tokens) against the largest of them. It is read from
the engine, cached, and refreshed in the background when it is more than ten seconds old
— a section renders synchronously, so a request cannot wait for the engine, and a
container whose engine is down keeps the last card it had rather than forgetting what it
lives in.

**Why `open_app` is banned here.** The panel above the conversation is already the app,
and it holds its own live connection to the engine, so opening it again renders nothing
new. What it does do is expensive and permanent: the result is the full widget HTML
(~17K tokens measured on `settings`), and a container's conversation is durable, so that
payload is re-sent on every later turn of that container. Measured on the rig: a first
turn costs 23.1K input tokens without the call and 46.6K with it. The ban therefore
covers `open_app`, `app_html` and the per-app `open_*` tools, and it is stated flatly —
*not even when a tool result tells you to* — because tool results do tell you to:
`get_app_guide` says "open it with `open_app {app}`; it renders immediately after
saving", and `save_app`'s own result ends with `Show it NOW with: open_app {…}`. It
holds: measured in this panel on DeepSeek-V4-Pro, a container that read its data, edited
the app's HTML and added a row made twelve tool calls and not one of them was an `open_*`
— including the step right after `get_app_guide` had told it to open one. This is a
container-only rule; in an ordinary chat session `open_app` is exactly right, and the
plugin renders it inline.

It does **not** have to argue with the engine's `initialize` instructions, because dsh
never reads them: `packages/mcp/mcp-client/src/connection.ts:272` discards the SDK
client's connect result, and nothing in the tree calls `getInstructions()`. The only
server-authored text that reaches the model is tool names, descriptions and schemas
(`packages/mcp/mcp-client/src/tools.ts:146-152` → `ctx.tools.register`). If a later dsh
starts forwarding them, nothing here changes: the ban is unconditional already.

**The reply contract** is machined to fit the strip. In a container the app is the reply
— you say "mark the milk as bought" and the row ticks itself — so the model's sentence is a
receipt, and the strip under the app shows the head of the last thing it said, flattened
to one line and cut at 200 characters. That is why the prompt asks for one sentence
first: the first sentence *is* what the user reads. After a write it asks for the change
by name rather than a recital of the board, which the panel is already showing.

If you replace the template through `containerPrompt`, keep those four jobs — identity,
the `{card}`, the ban, the one-sentence receipt — in whatever language you write it in.
Both placeholders are optional: a template without `{card}` simply does not get one.

**Containers made by a build that still posted the rules as a message** keep that message
in their history and gain the section on their next turn. Nothing is migrated: the old message is one more thing
that was said in that conversation, it agrees with the section, and a container is not
worth rewriting history for. New containers get the one-line question instead.

## What it reaches into, and what breaks if dsh moves

Six things this plugin does are not asked of it by any published seam — it reads or
adjusts something inside dsh. Each degrades to plainer behaviour rather than breaking, and
each is listed here so an upgrade has somewhere to look:

- **The hero gives way in a container.** A stylesheet keyed on an attribute the plugin
  stamps on dsh's composer stack hides the hero chrome and lets the app fill the column.
  It selects structurally (`> :not([data-slot])`) because dsh's class names are
  content-hashed. If the stack's shape changes the rules stop matching and the blank
  container looks like an ordinary blank session with an app in a row above the composer.
  Only reachable in the state where the opening line did not go out.
- **App workspaces are filtered out of dsh's own projection.** The plugin wraps
  `workspaces.list.getSnapshot`, so the sidebar tree, the New Session picker and dsh's
  own "most recent workspace" all stop seeing them. One app workspace survives the
  filter — the one whose blank session you are looking at — because ConversationRoot
  disables the composer of a blank session whose workspace it cannot find. (Measured:
  with that exemption removed the input reads "Choose a workspace to start" and Send is
  disabled.)
- **New Session is re-aimed.** `workspaces.startSession` is wrapped so that an implicit
  New Session standing inside a container goes to your own most recent workspace instead
  of the app's. A New Session started from a workspace row still goes exactly where the
  row says.
- **Two tabs are pressed rather than selected.** View selection lives in a store the
  chat entry owns, with no service verb: the Apps tab is found by its label, and Chat as
  the first tab that is not ours.
- **The app pane is measured, because a `conversation.view` gets no box to fill.** Its
  height is the scrollport minus the composer seat, read off the two attributes dsh puts
  on them (`data-conversation-scroll`, `data-composer-seat`) and re-read on every pass —
  the nodes are dsh's and get replaced, and an observer left on a detached one freezes
  the height at a window size that is no longer there. The invariant is that the app pane
  is never taller than the room: a column with something to scroll is a column a chat
  scrolls to the bottom, which slides the app out of sight. If neither attribute is
  found the pane keeps its 320px starting height and the panel is small, not broken.
- **The agent's line sits in dsh's content column.** The strip's rule and its
  alert tint span the panel; the row of text inside them is capped at
  `--dsh-composer-card-max-width` (the variable dsh declares on the conversation root —
  `calc(748px + 32px)` today) and centred, so the agent speaks in the same column as the
  composer and every chat message. A dsh that stops publishing the variable falls back to
  780px; one that changes it moves our row with everything else.

## Known limitations

- **The opening line is one model call per app.** See above; `installMessage: ''` opts
  out, at the cost of the blank-session layout and of the strip's first receipt. The
  rules are unaffected — they are a system section, and `containerPrompt: ''` is what
  retires those.
- **A container that never got its opening line has no tab ring.** dsh renders no
  view until a session has its first message. Until then the app renders in a row of its
  own above the composer (`conversation.input.dock`) — live and interactive, never
  covering the input — and moves into the Apps tab the instant the ring appears.
- **An app's conversations are hidden from the session tree, not just its workspace.**
  Hiding the workspace alone would drop its sessions into the Ungrouped bucket, so they
  are hidden with it (through dsh's own archived-session set, in this client's
  projection only — nothing is archived on the host). They are still reachable the way
  they are meant to be: through the app.
- **The App Store's "open" needs an engine that knows `?nav=intent`** (v0.5.1+). An older
  engine ignores the parameter, and the store's links navigate its own frame instead of
  entering the other app's container.
- **An app taller than the panel needs an engine that keeps its viewer scrollable.**
  The panel gives every app the same height, and an app whose document is taller than
  that has to scroll inside it. Seven of the shipped apps declare
  `html,body{overflow:hidden}` — correct advice to a host that sizes the frame from the
  app, and in a fixed frame it means the wheel does nothing (measured: habit-streaks at
  1712×537, document 1127px, nothing in the tree scrollable, 590px unreachable). The
  engine's viewer (v0.5.1+) sets `overflow-y:auto` on the root of a standalone page,
  which costs nothing when the app fits — on an older engine those apps are clipped at
  the fold, in a browser tab exactly as in this panel.
- **A sandboxed app's links are not intercepted.** Apps installed `--sandboxed` run in
  the runner's own child document; the click interception lives in the document the
  engine serves. Every app the AI writes, and everything from the App Store, is local
  and covered.
- **The Apps section sits at the foot of the sidebar, not above the workspace list.**
  The sidebar shell offers plugins exactly one hole (`sidebar.footer.action`, below the
  workspace region); the region itself is a single-occupant slot that dsh's own
  workspace browser fills, and registering a second entry there would shadow it rather
  than sit beside it.
- **Chat stays dsh's default view.** The Apps tab sorts first, but a session with no
  stored preference opens on Chat — the fallback is a constant inside ui-conversation.
  Entering through an app node selects the Apps tab explicitly, and so does the handover
  when a container's first message lands.
- **A per-app `open_<name>` tool for an app made mid-session needs a dsh restart — and the
  plugin is no longer the reason.** Keyed slots take no wildcards, so the plugin asks the
  engine which `open_*` tools it publishes and registers each one; it now re-asks whenever
  the directory is opened or a card shows an app it has not heard of, so its key set is
  never older than the app list beside it. What does not move is dsh's own tool table: the
  engine registers the new tool when `save_app` runs (with `OMA_DYNAMIC_TOOLS=1`) and dsh's
  MCP client re-syncs on `notifications/tools/list_changed`, but the engine's `/mcp` face is
  stateless — `createMcpHandler` builds a fresh engine per request — so there is no live
  session to send that notification on. Measured on the rig: an app created in turn 1 was
  still missing from the model's tools in turn 2 (*"There is no tool named
  open_mood_tracker"*), and the session log carries exactly one `request/header` for the
  whole session, so the catalog never changed. None of this reaches the user, because the
  universal `open_app` covers every app the moment it exists — it is what the model called
  in every rig run, including the step straight after `save_app`.
- **Tool results arrive flattened.** dsh keeps only the rendered text of an MCP result,
  so the app name is recovered from the call's arguments (or the tool name) rather than
  from `structuredContent`.

## Development

Point the same command at a checkout instead of the registry — pnpm links it, so edits are
live on the next dsh restart:

```sh
dsh plugin --profile web add /path/to/dsh-plugin-open-app
```

A linked plugin is resolved from its real path, so the profile's own `node_modules` is not
on its resolution path. That is why `lib/index.js` imports nothing but Node builtins, and
why it hand-checks its config instead of declaring a schema.

The package is two files: `lib/index.js` (the host half — routes, app directories, the
prompt section) and `lib/client.js` (the browser half — the five slots). `cordis.patch.yml`
is the bundle layer `dsh plugin add` appends to your profile.

## License

MIT — see [LICENSE](LICENSE).
