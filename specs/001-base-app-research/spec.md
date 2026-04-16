# Spec: Base App Research for viral-ops

## Requirements
<!-- DR-SEED:REQUIREMENTS -->
Find the best open-source base app to fork as the foundation for viral-ops — a SaaS-style platform where AI drives the full viral lifecycle (trend intelligence, viral scoring, content lab, multi-platform distribution, affiliate monetization, and a feedback loop). Including UI stack selection for the ops dashboard.

Key requirements for the base app:
- Auth + billing infrastructure (multi-tenant ready)
- Dashboard UI framework for managing channels, content, analytics
- API layer (REST/tRPC/GraphQL) for pipeline integration
- Background job queue for content pipeline orchestration
- Database with multi-tenant content management support
- Extensible for video gen, upload, and affiliate tracking integrations

## Scope
<!-- DR-SEED:SCOPE -->
- Evaluate OSS SaaS boilerplates, starter kits, and admin frameworks
- Compare UI stacks (Next.js/Remix + component libraries)
- Assess database/ORM options for the content pipeline
- Recommend top 3 candidates with pros/cons matrix
- Out of scope: video gen tools, uploaders, orchestration (already researched in notes-initial.md)

## Open Questions
All questions answered. Gen 1 (27 questions, 13 iterations) + Gen 2 (10 questions, 5 iterations).

## Research Context
- **Gen 1** (architecture): `research/archive/gen1-2026-04-16/research.md` (882 lines, 13 iterations)
- **Gen 2** (version update): `research/research.md` (200 lines, 5 iterations)

<!-- BEGIN GENERATED: deep-research/spec-findings -->
## Research Findings Summary

### Gen 2: Updated Stack (replaces gen1 versions)
| Layer | Component | Version | License | Port |
|-------|-----------|---------|---------|------|
| Dashboard | **next-forge** (Turborepo monorepo) | v6.0.2 | MIT | :3000 |
| Framework | Next.js | 16.1.6 | MIT | |
| React | React | 19.2.4 | MIT | |
| Auth | **Clerk** (Better Auth as OSS fallback) | latest | Commercial/MIT | |
| ORM | Prisma | 7.4 | Apache 2.0 | |
| Database | PostgreSQL | 18.3 | PostgreSQL | |
| UI | ShadCN UI + **shadcn/ui charts** (replaces Tremor) | latest | MIT | |
| CSS | Tailwind CSS | 4.2.1 | MIT | |
| TypeScript | TypeScript | 6.0 | Apache 2.0 | |
| Package Mgr | **Bun** | 1.3.10 | MIT | |
| Runtime | Node.js | 24 LTS | MIT | |
| Orchestrator | n8n (self-hosted) | 2.16.0 | Sustainable Use | :5678 |
| Video Engine | Pixelle-Video (FastAPI, ComfyUI, Edge-TTS) | 0.1.15 | Apache 2.0 | :8000 |
| Image Gen | ComfyUI | v0.19.0 | GPL-3.0 | |
| TTS | Edge-TTS (Thai: 3 Neural voices) | v7.2.8 | LGPLv3 | |
| Upload | YouTube API v3, Meta Graph API (IG+FB), TikTokAutoUploader | varies | | |

### Key Changes from Gen 1
1. **Boilerplate**: next-saas-stripe-starter (dead) → **next-forge v6.0.2**
2. **Auth**: Auth.js v5 (dead) → **Clerk** (Better Auth as escape hatch)
3. **Charts**: Tremor (dead) → **shadcn/ui charts** (Recharts v3)
4. **Package manager**: npm → **Bun 1.3.10**
5. **Versions**: Next.js 14→16, Prisma 5→7, n8n 1→2, Tailwind 3→4, Node 18→24, PG 16→18, TS 5→6

### Migration Effort (ranked)
| Priority | Component | Effort |
|----------|-----------|--------|
| 1 | Prisma 5→7 | HIGH (2-stage: ESM, driver adapters) |
| 2 | Next.js 14→16 | MEDIUM (codemod available, next-forge handles most) |
| 3 | Tailwind 3→4 | MEDIUM (next-forge already on v4) |
| 4 | n8n 1→2 | LOW (HTTP Request nodes unchanged) |
| 5 | Pixelle-Video | NONE |

### 7-Layer Architecture (unchanged from gen1)
- **Trend Layer**: snscrape + Google Trends → BERTopic clustering → momentum ranking
- **Viral Brain**: 6-dimension LLM-as-judge scoring (Phase 1) → GBDT after ~500 videos (Phase 2)
- **Content Lab**: Sequential A/B variant testing (48h interval), 3-second retention as primary metric
- **Production**: Pixelle-Video (script→TTS→image→composite), per-channel ComfyUI workflows
- **Distribution**: 4-platform upload (YT/IG/FB official API + TikTok unofficial), staggered per channel
- **Monetization**: IG cart pin (auto), TikTok affiliate link (partial), YT/FB (manual)
- **Feedback Loop**: 3-pull ingestion (T+6h, T+48h, T+168h), GBDT retraining every 100 videos

### Architecture Validated
3-service localhost (Dashboard :3000 → n8n :5678 → Pixelle-Video :8000) fully compatible with all updated versions. No breaking incompatibilities.
<!-- END GENERATED: deep-research/spec-findings -->
