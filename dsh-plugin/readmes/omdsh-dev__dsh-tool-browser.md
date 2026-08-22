# Browser control configuration for DSH

English | [中文](README.zh.md)

This repository publishes a static Cordis overlay and integration guide for
`@deepseek-ai/dsh-tool-browser`. It does not distribute the tool implementation,
a DSH runtime, browser binaries, or credentials.

## Availability

**Static configuration candidate only.** An authorized read-only registry query
for `@deepseek-ai/dsh-tool-browser` returned HTTP 404, and no official renamed
package was identified. This repository can validate the overlay syntax and
documentation offline, but it cannot install the tool or claim runtime
compatibility from npm artifacts.

Perform runtime acceptance only after the official tool package becomes
available from an authoritative source. Do not substitute a similarly named
package.

## Requirements for later runtime acceptance

- A compatible DSH installation in which `@deepseek-ai/dsh-tool-browser` is
  already available to the plugin loader.
- Chrome, Edge, or Playwright Chromium installed on the target machine and
  accessible through a configured channel or executable path.
- Deployment permissions and network policy appropriate for browser access.

## Contents

```text
examples/browser-control/         Reference overlay and bilingual usage guide
scripts/verify-release.mjs        Dependency-free static release gate
README.md / README.zh.md          Behavior, configuration, and acceptance notes
SECURITY.md                       Security scope and reporting guidance
LICENSE                           BSD 3-Clause
```

## Tools

| Tool | Behavior |
|---|---|
| `browser_open` | Open the calling agent's browser page; call before other browser tools |
| `browser_navigate` | Navigate to an absolute HTTP(S) URL |
| `browser_click` / `browser_type` | Interact with the first element matching a CSS selector |
| `browser_extract` | Extract visible text from a selector or the page body |
| `browser_screenshot` | Write a PNG screenshot to the configured directory |
| `browser_list` / `browser_close` | Report browser state / close the browser page |

Browser pages are scoped to their calling agents. Do not depend on one agent
being able to observe or control another agent's page.

## Conditional configuration

After the official package becomes available, use the reference overlay in
[`examples/browser-control/browser.cordis.yml`](examples/browser-control/browser.cordis.yml),
or add the equivalent plugin row to your composition:

```yaml
- insert:
    - id: tool-browser
      name: '@deepseek-ai/dsh-tool-browser'
      config:
        headless: true
        channel: chrome
```

The checked-in overlay leaves `channel` and `executablePath` unset so the
deployment can select its browser explicitly. The following command is for
later runtime acceptance; it is not currently verified against an npm
package:

```sh
dsh --config "$PWD/examples/browser-control/browser.cordis.yml"
```

### Browser selection

Choose one supported option for the target machine:

- `channel: msedge` for Microsoft Edge;
- `channel: chrome` for Google Chrome;
- `executablePath` for a managed browser binary; or
- the Playwright Chromium default after the deployment administrator has
  installed that browser build.

### Configuration

| Key | Default | Meaning |
|---|---|---|
| `channel` / `executablePath` | unset | Browser channel / executable path |
| `headless` | `true` | Headless mode |
| `launchTimeoutMs` | `30000` | Launch timeout |
| `screenshotDir` | OS temporary directory | Screenshot output directory |
| `actionTimeoutMs` | `15000` | DOM action timeout |
| `maxExtractChars` | `100000` | Per-extract character cap |

## Verify the repository

Run the dependency-free static gate:

```sh
node scripts/verify-release.mjs
```

It strictly parses the overlay's documented YAML subset, validates its schema, verifies bilingual-document blob
IDs and relative links, confirms that no runtime implementation directory is
present, and performs a release-hygiene scan. It does not launch a browser or
access the network.
Passing this gate does not prove that an unpublished tool package can be
installed or that the documented runtime behavior is compatible with a public
release.

## Runtime acceptance

After the official package and a browser are available in the target DSH installation,
start the overlay and exercise all eight tools against a local or otherwise
approved test page. Confirm that separate agents do not share pages and that
closing an agent releases its browser page.

## Security

Browser tools can access network resources and write screenshots. Review
[`SECURITY.md`](SECURITY.md), restrict the deployment with its normal sandbox
and permission controls, and avoid browsing untrusted targets with privileged
sessions.

## License

BSD 3-Clause for this repository's documentation and configuration. The
separately supplied tool package and its dependencies retain their own licenses.
