# dsh-fetch-models-unselect-all

A "deselect all" button for the DeepSeek Harness **Settings → Models → Add
provider → custom provider → Fetch available models** dialog.

The dialog lists every model a provider advertises with one checkbox per row
and only two footer actions — Cancel and **Add selected**. This plugin adds a
**取消全选 / Deselect all** button directly left of Cancel, so a large catalog
can be cleared in one click instead of unchecking each row.

```
[取消全选]  [取消]  [添加所选]
```

## What it does

- Pure client presentation: watches the DOM for the fetch dialog (anchored on
  its unique "Add selected" action), then clones the Cancel button's classes to
  insert an identically styled "deselect all" button left of it.
- Clicking it unchecks every model checkbox and dispatches a native `change`
  event per row, keeping the dialog's React-controlled selection in sync —
  "Add selected" then adopts nothing, exactly as if each box were cleared by
  hand.
- No host code, no RPC, no settings, no session events. The observer is
  disposed with the plugin fiber; uninstalling leaves nothing behind.
- Localized: shows 「取消全选」 with a Chinese UI and "Deselect all" with an
  English UI, following the Cancel button's language.

## Install

```sh
dsh plugin --profile web add github:dsh-fetch-models-unselect-all   # or a local clone:
dsh plugin --profile web add /path/to/dsh-fetch-models-unselect-all
```

Restart `dsh web` and hard-refresh the browser after installation.

## Build

```sh
DSH_CHECKOUT=/path/to/deepseek-harness node build.mjs
```

`build.mjs` resolves the checkout's esbuild + typescript and emits
`lib/index.js` (host, no-op) + `lib/client.js` (browser bundle,
`__ModuleLoader__` format) + `lib/types/` declarations.

## Notes

The dialog has no official plugin slot, so the button is anchored on the
dialog's DOM structure ("Add selected" action + checkbox list). A future
settings-form redesign may require a small update to the anchor logic.

## License

MIT
