<div align="center">

# viral-ops

**SaaS-style platform where AI drives the full viral lifecycle — trend intelligence, viral scoring, content lab, multi-platform distribution, and a feedback loop that gets smarter every post.**

*Trend signals → viral scoring → hook variants → clips → multi-platform post → affiliate-aware monetization → learn → repeat.*

🔍 Trend Layer · 🔥 Viral Brain · 🧪 Content Lab · 🛒 Product Discovery · 🎬 Production · 📱 Distribution · 🧠 Monetization · 🔁 Feedback Loop · 📺 Multi-Channel

</div>

---

## Status

🚧 **Research phase** — scaffold complete, stack TBD.

Framework installed and verified. Next step: compare OSS candidates via `/research` skill, then scaffold the first feature with `/spec_kit:complete`.

## Goal

A SaaS-shaped platform — built solo-use first, foundation stays multi-tenant-ready.

Most AI-video tools stop at "generate a clip and post it." viral-ops is built around the insight that *generation is the cheap part* — the leverage is in **predicting what will go viral** and **learning from what actually did**. That's the bet.

### Architecture — two entry paths, one shared backbone

Two ways content enters the pipeline depending on channel mode, then they converge into the same production → distribution → feedback backbone.

```
  PATH A — Trend-driven (viral-only / mixed channels)
  ─────────────────────────────────────────────────────
  [Trend Layer]        → scrape + cluster signals per niche
         ↓
  [Viral Brain] 🔥     → score idea (hook strength, curiosity gap,
                         novelty, retention prediction) + hook variants
         ↓
  [Content Lab] 🧪     → idea variants + A/B hook testing
         ↓
         ↓─────────────────────────┐
                                   │
  PATH B — Product-driven (cart-focused / mixed channels)
  ───────────────────────────────────────────────────────
  [Find Product] 🛒    → scan affiliate catalog per niche (TikTok Shop,
                         Shopee, Lazada, etc.)
         ↓
  [Score Product]      → commission × relevance × trend-fit × conversion
                         history → rank candidates
         ↓
  [Generate Affiliate  → per-platform cart link / deep link with
   Link]                 UTM tracking
         ↓
  [Generate Idea +     → product-first script writing (hook around
   Script]               the product, not generic trend)
         ↓
         ↓─────────────────────────┤
                                   │
         ┌─────────────────────────┘
         ▼
  [Production]          → video gen (script → visuals → TTS → composite,
                          per-channel style)
         ↓
  [Distribution]        → multi-platform post (TT / YT Shorts /
                          IG Reels / FB Reels)
         ↓
  [Monetization] 🧠     → pin cart (if applicable), conversion tracking,
                          attribute clicks/sales per clip
         ↓
  [Feedback Loop] 🔁    → performance ingestion (views, retention, CTR,
                          conversions) → re-train Viral Brain scoring
                          AND Product Scoring
         ↑_________________________________________________________│
```

**Why two paths?** Viral-only channels need to win attention first (trend → hook → content). Cart-focused channels need to sell (product → angle → content). Same machinery, different starting question.

### The secret sauce

**Viral Brain + Feedback Loop.** Without them it's just another AI video generator. With them, every post makes the system a little better at predicting the next one.

### 2 approval gates (human-in-the-loop)

- **Gate 1 — Idea:** auto-schedule top-N (trusted niches) OR manual pick (new territory)
- **Gate 2 — Post:** auto-approve (trusted channels) OR manual review (experimental)

### Multi-channel management

Each channel has its own niche, style, target platforms, schedule, approval mode, and **monetization mode**:

- **Viral-only** — grow audience, no cart
- **Cart-focused** — every clip pins a product
- **Mixed** — viral content with cart on selected clips

Trusted channels run on autopilot; experimental ones stay in manual review.

Start: use it myself for a few channels. Later: open to others with auth + billing once the Viral Brain has real performance data to train on.

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
