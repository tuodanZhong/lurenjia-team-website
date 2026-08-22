# dsh-engineering-skills

> Engineering-discipline skills distilled from a large production agent-system codebase: systematic code review, CI failure triage, shell safety, redundancy/boundary auditing, cross-repo pattern absorption, and release engineering.

Six markdown skills for AI coding agents (DeepSeek Harness, Claude Code, Codex, or any agent that reads `SKILL.md`). They are methodology-first — no code to install, no runtime, no lock-in: copy the `skills/` directory and the agent loads them.

## Skills

| Skill | What it does |
|---|---|
| [code-review-methodology](skills/code-review-methodology/SKILL.md) | 18-dimension, 3-pass code review framework: execution/integration → architecture/systems → reliability/correctness, plus multi-angle iterative review, E2E-test review angles, migration review angles, and 12+ derived rules |
| [ci-diagnosis-and-fix](skills/ci-diagnosis-and-fix/SKILL.md) | Systematic triage and repair when GitHub Actions CI turns wholesale red: find the failing run → pull the failing step's log → classify the root cause → fix → verify |
| [shell-safety](skills/shell-safety/SKILL.md) | Hard ban on interactive CLI commands (`more`/`less`/`pause`/`choice`/`start /WAIT`) that freeze headless agent sessions, with non-interactive equivalents, a mandatory timeout rule, and a pre-flight checklist |
| [redundancy-and-boundary-audit](skills/redundancy-and-boundary-audit/SKILL.md) | Repo-level duplication triage with a falsifiable sync test and A/B/C classification (true duplicate / same-name-different-concept / same-shape-different-domain), plus boundary, naming, and multi-angle verification |
| [repo-analysis](skills/repo-analysis/SKILL.md) | 5-phase cross-repository architecture audit: scan → pattern extraction (7-primitive taxonomy) → gap mapping → value judgment → structured output, with a batch flow for 5+ repos |
| [release-engineering](skills/release-engineering/SKILL.md) | End-to-end release of a Python package to GitHub + PyPI + awesome lists: name-availability checks, data-files packaging (with the glob-flattening pitfall), repo/tag/topics, twine upload, clean-venv verification, and one-repo-per-PR aggregation entries |

## Install

**From PyPI** — the pack also ships as a data-only Python package with an installer CLI:

```bash
pip install "dsh-engineering-skills"
dsh-engineering-skills list                 # see the 6 skills
dsh-engineering-skills install ~/.dsh/skills          # DeepSeek Harness user skills dir
```

The wheel contains the same `SKILL.md` files (packaged as data-files, no code
dependencies); the CLI just copies them into any agent's skills directory.

**From source / generic agents** — copy the skills into your agent's skills directory:

```bash
# DeepSeek Harness (user-level skills dir is ~/.dsh/skills, i.e. $DSH_HOME/skills)
cp -r skills/* ~/.dsh/skills/

# Claude Code
cp -r skills/* ~/.claude/skills/

# Codex
cp -r skills/* ~/.codex/skills/
```

Each skill is a self-contained `SKILL.md` with YAML frontmatter (`name`, `description`, `keywords`) — no dependencies, no build step.

## Why these skills

They come from real incidents and audits, not theory. Notable provenance:

- `shell-safety` exists because a session froze for 12 minutes on `findstr ... | more +0` waiting for a keypress that never arrived.
- `redundancy-and-boundary-audit` encodes the A/B/C duplication classification that keeps "same name" from being treated as "duplicate" — a domain model / API DTO pair is legitimate layering, and only *asymmetric change* is drift.
- `code-review-methodology` accumulates review angles only after each one caught a real bug (single-pass review finds ~30% of bugs in cross-cutting features).
- `ci-diagnosis-and-fix` documents the two failure modes that turn CI wholesale red: a nonexistent dependency version, and the old `$GITHUB_OUTPUT` syntax on newer runners.
- `release-engineering` encodes the flow proven across three same-day releases (a CLI+MCP audit tool, an MCP server, and this skill pack): PyPI name collisions, data-files path flattening, token-scope failures, and `requires-python` vs verify-venv mismatches all bit once and are now written down.

## Validation

```bash
python scripts/validate_skills.py   # checks frontmatter + body of every SKILL.md
```

## License

MIT © 2026 Chen (Jarry) Pan
