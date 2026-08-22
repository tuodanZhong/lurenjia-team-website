# DSH Plugin Market

> A verified-first plugin store DeepSeek Harness can actually use.

[![DeepSeek Harness](https://img.shields.io/badge/DeepSeek%20Harness-0.1.0--rc.6-black)](https://deepseek.com/harness/)
[![Plugin](https://img.shields.io/badge/DSH-plugin-blueviolet)](https://github.com/topics/dsh-plugins)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

`dsh-plugin-market` adds a floating verified plugin store to DeepSeek Harness Web. It opens with a local curated directory, supports Chinese and English search, can discover GitHub leads, checks whether a repository looks installable, opens GitHub, and copies pinned install commands for built-in verified entries.

![DSH Plugin Market screenshot](docs/screenshot.png)

## Why This Exists

DeepSeek Harness says everything is a plugin. Great. But the ecosystem is already noisy: topics, awesome lists, random forks, half-working experiments, and hidden gems are all mixed together.

This plugin gives you a safer store inside DSH:

- Browse 12 verified plugins without leaving the app, including market, manager, skin, workflow, runtime, and developer entries.
- Search the directory in Chinese or English.
- Paste an exact `owner/repo` or GitHub repository URL when search indexing is slow.
- Use GitHub search only as lead discovery.
- See Chinese summaries, stars, language, update time, and descriptions at a glance.
- Copy a `dsh plugin --profile web add github:owner/repo#commit` command for built-in verified entries.
- Run a quick installability check for `package.json`, `dsh.bundle.patch`, patch files, and Web client entry points.
- Stay safe: no automatic remote install, no API key access, no hidden writes.

## Features

- Verified directory first: no network request is needed to show usable plugins.
- Chinese search expansion: words like `皮肤`, `市场`, `沙箱`, `会话`, `模板` map to relevant English tags.
- The panel does not auto-search on open; this avoids immediate failures when `api.github.com` is blocked or rate-limited.
- GitHub discovery is explicit: click `搜 GitHub` to search remote leads.
- Built-in verified entries are pinned to a checked Git commit.
- GitHub leads are checked; they can be shown as installable, but they are marked as not commit-pinned.
- Direct repository lookup without the GitHub Search API: `2160039878-cyber/dsh-plugin-market` or `https://github.com/2160039878-cyber/dsh-plugin-market`.
- Sort by stars, update time, or forks.
- Open matching repositories on GitHub.
- Check whether a repository looks like a real DSH bundle.
- Copy pinned install commands for built-in verified entries.
- Works as a DSH Web client plugin.
- No build step.
- No dependencies.
- No token storage.

## Registry

The built-in directory lives in [`registry/plugins.json`](registry/plugins.json). Entries are intentionally conservative: a repository must expose a root `package.json`, declare `dsh.bundle.patch`, have the referenced patch file available, and record a 40-character verified commit. As of v0.4.0 it includes 12 checked repositories, with skin/theme plugins such as `dancingmemory/dskin`, `KinGao294/dsh-skin`, and `luoyan96/dsh-catnap-studio`.

Built-in install commands are pinned:

```powershell
dsh plugin --profile web add github:owner/repo#verified_commit_sha
```

## Design References

This project follows the public DSH plugin ecosystem's practical patterns without copying third-party code:

- [`dsh-plugin-installer`](https://github.com/Toukaiteio/dsh-plugin-installer) separates discovery from install action;
- [`dsh-market`](https://github.com/dsh-market/dsh-market) makes browsing faster with category-first navigation;
- [`dsh-skin`](https://github.com/KinGao294/dsh-skin) shows why theme plugins need a first-class `skin` category instead of being buried in free-text search.

Check the registry locally:

```powershell
npm run check
```

## Install

```powershell
dsh plugin --profile web add github:2160039878-cyber/dsh-plugin-market
dsh web
```

Open `http://127.0.0.1:3080/` and look for the `插件市场` button in the top-right corner.

## Local Development

```powershell
git clone https://github.com/2160039878-cyber/dsh-plugin-market.git
cd dsh-plugin-market
npm run check
dsh plugin --profile web add file:$PWD
dsh web
```

## Rollback

```powershell
dsh plugin --profile web remove dsh-plugin-market
```

## Safety Model

This project is a browser-side helper. It reads public GitHub repository search results through the GitHub Search API and renders them in DSH Web.

It does not:

- read DSH API keys;
- install remote code automatically;
- write to your DSH profile by itself;
- call private GitHub APIs;
- persist repository lists locally.

## Status

v0.4.0. Directory-first, includes verified skin/theme plugins, category filters, and pinned install commands.

Planned only if needed:

- installed-plugin detection;
- richer registry review workflow;
- better category filters;
- GitHub rate-limit status;
- one-click install behind explicit confirmation.

## Historical Versions

Historical source snapshots are kept in [`archive/`](archive/) in addition to Git tags and GitHub releases.

- [`archive/v0.3.1`](archive/v0.3.1): one-click category filters for the verified directory.
- [`archive/v0.3.1.zip`](archive/v0.3.1.zip): the same snapshot as a zip package.
- [`archive/v0.3.0`](archive/v0.3.0): verified-first registry with 12 checked DSH plugins.
- [`archive/v0.3.0.zip`](archive/v0.3.0.zip): the same snapshot as a zip package.
- [`archive/v0.2.3`](archive/v0.2.3): checked candidates fallback when no plugins pass.
- [`archive/v0.2.3.zip`](archive/v0.2.3.zip): the same snapshot as a zip package.
- [`archive/v0.2.2`](archive/v0.2.2): no automatic GitHub search on panel open.
- [`archive/v0.2.2.zip`](archive/v0.2.2.zip): the same snapshot as a zip package.
- [`archive/v0.2.1`](archive/v0.2.1): strict DSH plugin filtering by default.
- [`archive/v0.2.1.zip`](archive/v0.2.1.zip): the same snapshot as a zip package.
- [`archive/v0.2.0`](archive/v0.2.0): direct repository lookup and plugin health checks.
- [`archive/v0.2.0.zip`](archive/v0.2.0.zip): the same snapshot as a zip package.
- [`archive/v0.1.0`](archive/v0.1.0): first public MVP, search + copy install command.
- [`archive/v0.1.0.zip`](archive/v0.1.0.zip): the same snapshot as a zip package.

## License

MIT
