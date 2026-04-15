<div align="center">

# viral-ops

**SaaS-style platform to run viral short-form content across multiple channels — trends in, clips out, carts pinned where it pays.**

*Research trends → propose ideas → generate clips → your call or auto-approve → post to TT/YT/IG/FB, with optional affiliate cart per channel.*

🔍 Trend Research · 💡 Idea Queue · 🎬 Video Gen · ✅ Approval Gates · 📱 Multi-Platform · 🛒 Optional Affiliate · 📺 Multi-Channel

</div>

---

## Status

🚧 **Research phase** — scaffold complete, stack TBD.

Framework installed and verified. Next step: compare OSS candidates via `/research` skill, then scaffold the first feature with `/spec_kit:complete`.

## Goal

A SaaS-shaped platform — built solo-use first, foundation stays multi-tenant-ready.

**5-stage pipeline with 2 approval gates:**

1. **Trend research** — auto-scan trending content per channel niche
2. **Idea queue** 🚦 — AI proposes ranked ideas → *manual pick* or *auto-schedule top-N*
3. **Video generation** — script → visuals → TTS → composite (per-channel style)
4. **Approval gate** 🚦 — *auto-approve* (trusted channels) or *manual review* (new channels)
5. **Multi-platform post** — TikTok / YouTube Shorts / IG Reels / FB Reels, with *optional* affiliate cart pin ("ปักตะกร้า") depending on channel mode

**Multi-channel management** — each channel has its own niche, style, target platforms, schedule, approval mode, and **monetization mode**:
- **Viral-only** — grow audience, no cart
- **Cart-focused** — every clip pins a product
- **Mixed** — viral content with cart on selected clips

Trusted channels run on autopilot; experimental ones stay in manual review.

Start: use it myself for a few channels. Later: open to others with auth + billing once the core is battle-tested.

## Stack

TBD — see [`research/notes-initial.md`](research/notes-initial.md) for starting links from the exploration phase. Final decision will be captured in a spec folder after the `/research` flow completes.

## Structure

```
viral-ops/
├── .opencode/           # spec-kit-autopilot framework (skills, agents, commands, MCP servers)
├── .claude/             # Claude Code config (symlinked to .opencode/)
├── .codex/ .gemini/     # Multi-runtime support
├── .mcp.json            # 4 MCP servers (sequential_thinking, spec_kit_memory, cocoindex_code, code_mode)
├── .utcp_config.json    # Code Mode external tools (GitHub, Figma, ClickUp, Chrome DevTools, etc.)
├── .env                 # API keys (gitignored)
├── AGENTS.md CLAUDE.md  # Framework instructions (Universal Template)
├── src/                 # Project code (TBD — after research)
├── specs/               # Spec folders from /spec_kit:complete
├── research/            # Cloned OSS repos for comparison
└── docs/
    └── FRAMEWORK_README.md  # Original spec-kit-autopilot framework README
```

## Setup Status

| Component | Status |
|---|---|
| 4 MCP servers (Sequential Thinking, Spec Kit Memory, Code Mode, CocoIndex) | ✅ built + tested |
| 21 Skills (auto-discoverable) | ✅ via `.claude/skills` symlink |
| 10 Agents (context, debug, deep-research, deep-review, improve-agent, improve-prompt, orchestrate, review, ultra-think, write) | ✅ in `.claude/agents` |
| CocoIndex semantic search | ✅ initialized (sentence-transformers, local) |
| Spec Kit Memory (hf-local embeddings, sqlite-vec) | ✅ vector dim 768 |
| Code Mode + 6 external manuals (159 tools) | ✅ GitHub 26 tools active |
| `.env` with GitHub PAT (from `gh auth token`) | ✅ gitignored |
| Windows setup fixes (Dev Mode symlinks, long paths, VS Build Tools) | ✅ applied |

## First Use

```bash
cd D:/Dev/Projects/viral-ops
claude
```

In Claude Code:

```
/mcp                                          # verify 4 MCP servers connected
/research create viral-ops stack comparison   # start research phase
```

## Framework

This project is built on **[spec-kit-autopilot](https://github.com/Basdanucha/spec-kit-autopilot)** — an AI coding framework with persistent memory, spec-kit documentation, and 12 autonomous agents. The framework provides the infrastructure (MCP servers, skills, agents, gates); viral-ops provides the project-specific goal, specs, and source.

Framework documentation preserved at [`docs/FRAMEWORK_README.md`](docs/FRAMEWORK_README.md).

## License

MIT — see [`LICENSE`](LICENSE). Based on [spec-kit-autopilot](https://github.com/Basdanucha/spec-kit-autopilot), itself a Windows-patched derivative of [opencode--spec-kit-skilled-agent-orchestration](https://github.com/MichelKerkmeester/opencode--spec-kit-skilled-agent-orchestration) by Michel Kerkmeester. Original copyright + permission notice preserved per MIT terms.
