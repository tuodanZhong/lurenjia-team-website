# dsh-kanban-mcp

> Filesystem-driven four-lane kanban board (todo / doing / blocked / done) exposed as a read-only MCP server and a Python API. Works with DeepSeek Harness and any MCP client.

A kanban board is just a directory tree of markdown cards:

```
<base_dir>/YYYY/YYYY-MM/YYYY-MM-DD/{todo,doing,blocked,done}/YYYYMMDD-HHMMSS__agent__slug__status.md
```

That design is the whole point: the board survives restarts, is diffable in git, needs no database, and can be inspected by any file tool. This package manages those files and exposes the board to agents over MCP.

## Install

```bash
pip install "dsh-kanban-mcp"          # Python API
pip install "dsh-kanban-mcp[mcp]"     # + MCP server (fastmcp)
```

Requires Python 3.10+.

## Run the MCP server

```bash
python -m kanban_mcp          # stdio transport
# or: kanban-mcp
```

Register it in **DeepSeek Harness** (MCP settings — the built-in MCP client) or any MCP client. The tools take an optional `base_dir` argument (default `.agent/kanban`) so one server can point at any board.

## Tools (read-only)

| Tool | Description |
|---|---|
| `kanban_board` | Full four-lane board with card details (agent, work_item, purpose, status, outcome, priority, timestamps) |
| `kanban_status` | Per-lane card counts + total |
| `kanban_doing` | Cards currently in progress |
| `kanban_blocked` | Blocked cards |
| `kanban_done_today` | Cards completed today |

All tools are read-only. Card **creation / update / movement** is available through the `KanbanManager` Python API (see below); write tools are planned but not yet exposed over MCP.

## Python API

```python
from kanban_mcp import KanbanManager, LaneStatus

kanban = KanbanManager(base_dir=".agent/kanban")

card = kanban.create_doing_card(
    agent="coder",
    work_item="build-api",
    purpose="Build the REST API endpoint",
)
kanban.update_card(card, outcome="GET /users implemented")
kanban.move_to_done("coder", "build-api", "API endpoint complete")

board = kanban.get_board()      # full board
stats = kanban.stats()          # per-lane counts
blocked = kanban.get_blocked_cards()
```

Writes go through an atomic temp-file + `os.replace`, so a concurrent reader never sees a half-written card.

## Why files instead of a database

- **Git-diffable** — card changes are reviewable like code.
- **Survives restarts** — no daemon, no lock, no migration.
- **Inspectable** — any file tool can read a card directly.
- **Portable** — `cp -r` the directory and you have a new board.

## Development

```bash
pip install -e ".[dev]"
pytest
```

## License

MIT © 2026 Chen (Jarry) Pan
