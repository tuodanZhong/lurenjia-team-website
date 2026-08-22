# dsh-computer-use-win

Windows computer-use bundle for [DeepSeek Harness (dsh)](https://github.com/deepseek-ai/deepseek-harness): screenshots, window and UI Automation element discovery, OCR/visual observation for text-only models, mouse/keyboard control, and direct Windows Settings launch.

The macOS-first sibling is [Anionex/dsh-computer-use](https://github.com/Anionex/dsh-computer-use); this plugin fills the Windows gap.

## What It Adds

| Tool | Purpose |
| --- | --- |
| `computer_screenshot` | Capture the full screen or a specific window. Vision-capable routes receive an image; text-only routes receive a saved PNG path. |
| `computer_list_windows` | List visible top-level windows with process, pid, title, screen rectangle, and active state. |
| `computer_list_elements` | Search controls exposed through Windows UI Automation and return names, types, physical-pixel rectangles, `click=(x,y)` centers, and diagnostics when UIA cannot see inside custom UI. |
| `computer_ocr_image` | Run Windows OCR on an existing image file and return recognized text boxes with absolute coordinates. |
| `computer_ocr_window` | Capture a window and OCR it, useful for CEF/Chromium/custom-rendered apps that UIA exposes only as a shell. |
| `computer_observe_image` | Turn an existing image into a generic text-model UI map: OCR, coarse regions, clickable text centers, and heuristic visual candidates. |
| `computer_observe_window` | Capture a window and return the same UI map, useful for icon-only controls and custom-rendered apps. |
| `computer_observe_media_controls` | Observe the bottom/player area and report generic play/pause toggle state without custom pixel scripts. |
| `computer_search_in_window` | Generic search flow: locate a likely search field, click it, type a query, and press Enter. |
| `computer_locate_text` | Locate visible text in a window through OCR without moving the mouse. |
| `computer_click_text` | OCR a window, find visible text, and click the matching text center with an explicit purpose. |
| `computer_open_settings` | Open Windows Settings through the documented `ms-settings:` URI. |
| `computer_click` | Move the mouse and click at absolute screen coordinates. |
| `computer_type_text` | Type literal text through clipboard paste first, with SendInput fallback. This keeps CJK text reliable under VDI/RDP filtering. |
| `computer_press_key` | Press a key or key combination. SendKeys is primary; SendInput is used for combinations SendKeys cannot spell. |
| `computer_scroll` | Scroll the mouse wheel, optionally at given coordinates. |
| `computer_drag` | Left-button drag between two screen points. |
| `computer_move_mouse` | Move the cursor without clicking. |

Input-injecting tools are approval-gated by default. With dsh's Full access preset (`approval=never` plus `sandbox=danger-full-access`), the plugin treats the action as already authorized and does not call the approval prompt that would otherwise deterministically reject. Confined modes still fail closed when the approval policy is `never`.

## How It Works

The plugin has no native binary dependency. Every capability runs through a bounded PowerShell child process:

- Capture uses `System.Drawing.CopyFromScreen`.
- Window discovery uses Win32 `EnumWindows`, `GetWindowTextW`, `GetWindowRect`, and foreground-window APIs.
- Element discovery uses Windows UI Automation, which lets text-only models locate native/accessibility-aware controls without seeing screenshots.
- OCR uses Windows.Media.Ocr for text and coordinate extraction from screenshots or window captures when UI Automation cannot see inside custom-rendered apps.
- Visual observation combines OCR with coarse layout regions, suggested actions, media-control state, and simple icon/button heuristics so text-only models get a basic UI map instead of a raw image path.
- Pointer input uses `SetCursorPos` and `mouse_event`.
- Text input uses clipboard plus `System.Windows.Forms.SendKeys` as the reliable path under Sangfor/VDI filtering, with SendInput fallback.
- All PowerShell processes opt into DPI awareness and UTF-8 output so UIA rectangles, screenshots, and click coordinates use one physical-pixel coordinate space.

## Install

Requires the [dsh CLI](https://github.com/deepseek-ai/deepseek-harness) on Windows.

From a checkout:

```sh
git clone https://github.com/you/dsh-computer-use-win.git
dsh plugin --profile web add ./dsh-computer-use-win
```

Or install a packed tarball:

```sh
pnpm install
pnpm pack
dsh plugin --profile web add ./dsh-computer-use-win-0.6.0.tgz
```

Verify the layer, then boot:

```sh
dsh --profile web --dump-config | grep computer-use
dsh --profile web
```

## Configuration

Patch the `computer-use-win` row in your profile's `cordis.patch.yml`:

```yaml
- id: computer-use-win
  config:
    requireApproval: true
    maxScreenshotBytes: 8388608
```

Set `requireApproval: false` only for unattended tests or disposable environments.

## Known Limitations

- Windows input injection is global: clicks go to whatever is under the coordinates.
- Elevated administrator windows may ignore input from a non-elevated plugin process.
- Win-key combinations fall back to SendInput, which some VDI products filter. Prefer semantic tools such as `computer_open_settings` where possible.
- UI Automation coverage depends on the target application exposing useful accessibility metadata. CEF/Chromium/Electron/custom-rendered windows may expose only a shell pane; use `computer_observe_window`, `computer_observe_media_controls`, `computer_search_in_window`, `computer_ocr_window`, `computer_locate_text`, or `computer_click_text` for those apps.
- Text-only DeepSeek routes cannot inspect screenshot pixels directly. `computer_screenshot` returns a saved PNG path on those routes; use observation/OCR tools to turn that path/window into text, UI regions, visual candidates, and click coordinates.
- Visual observation is not a vision model. Icon/button candidates are heuristics with confidence and evidence; verify after clicking.

## Recommended Text-Only Flow

For text-only models, prefer structured observation over coordinate guessing:

```text
computer_list_windows
-> computer_list_elements(window: "target app")
-> if diagnostics say UIA is limited, computer_observe_window(window: "target app")
-> use suggestedActions directly when they match the task
-> computer_observe_media_controls for play/pause state instead of custom pixel scripts
-> computer_search_in_window(window: "target app", query: "...")
-> computer_locate_text / computer_click_text for text targets
-> computer_click with a high-confidence visual candidate for icon-only targets
-> computer_type_text / computer_press_key
-> verify with computer_list_windows, computer_list_elements, computer_observe_window, or OCR
```

Example for NetEase Cloud Music, which is CEF/custom-rendered on many systems:

```text
computer_list_windows
computer_list_elements(window: "cloudmusic")
# If the result says UIA is limited:
computer_observe_window(window: "cloudmusic")
computer_observe_media_controls(window: "cloudmusic")
# If the media state is playing and the task asks to pause first, click the returned toggle.
computer_search_in_window(window: "cloudmusic", query: "想你的夜")
```

## Discovery

DeepSeek Harness currently documents out-of-tree plugin installation through profile dependencies and recommends adding the [`dsh-plugin`](https://github.com/topics/dsh-plugin) GitHub topic for discoverability. There is no separate official plugin upload endpoint in the public dsh docs.

## License

MIT
