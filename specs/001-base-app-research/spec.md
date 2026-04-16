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
All 27 research questions answered across 13 iterations. No open questions remain.

## Research Context
Deep research **complete**. Canonical findings in `research/research.md` (882 lines).

<!-- BEGIN GENERATED: deep-research/spec-findings -->
## Research Findings Summary (13 iterations, 27 questions)

### Definitive Stack Decision
| Layer | Component | License | Port |
|-------|-----------|---------|------|
| Dashboard | next-saas-stripe-starter (Next.js 14, Auth.js v5, Prisma+PG, ShadCN+Tremor) | MIT | :3000 |
| Orchestrator | n8n (self-hosted) | Sustainable Use | :5678 |
| Video Engine | Pixelle-Video (FastAPI, ComfyUI, Edge-TTS) | Apache 2.0 | :8000 |
| Upload | YouTube API v3, Meta Graph API (IG+FB), TikTokAutoUploader | varies | - |
| Shopping | IG Product Tagging (auto), TikTok Shop Affiliate (partial), YT/FB (manual) | - | - |

### 7-Layer Architecture
- **Trend Layer**: snscrape + Google Trends → BERTopic clustering → momentum ranking
- **Viral Brain**: 6-dimension LLM-as-judge scoring (Phase 1) → GBDT after ~500 videos (Phase 2)
- **Content Lab**: Sequential A/B variant testing (48h interval), 3-second retention as primary metric
- **Production**: Pixelle-Video (script→TTS→image→composite), per-channel ComfyUI workflows
- **Distribution**: 4-platform upload (YT/IG/FB official API + TikTok unofficial), staggered per channel
- **Monetization**: IG cart pin (auto), TikTok affiliate link (partial), YT/FB (manual)
- **Feedback Loop**: 3-pull ingestion (T+6h, T+48h, T+168h), GBDT retraining every 100 videos

### Multi-Channel Identity (Core)
- Per-channel: TTS voice, ComfyUI workflow, LLM persona prompt, hook preferences, brand rules
- TikTok 4-layer duplicate detection → script, voice, visual style, music, posting time MUST differ
- Single n8n pipeline with dynamic channel config injection

### Database
14 tables + 1 view: channels, channel_platform_accounts, channel_persona_history, platform_accounts, content, content_variants, ab_tests, platform_publishes, platform_analytics, upload_queue, affiliate_links, trends, products, product_score_history + content_calendar view

### Build Plan
6 sprints / 12 weeks: Foundation → Content Pipeline → Upload+Distribution → Affiliate+Analytics → Intelligence Layers → Multi-Channel+Polish

### Key Risks
1. TikTokAutoUploader ban risk (MEDIUM) — apply official API in parallel
2. Pixelle-Video maturity pre-1.0 (MEDIUM-LOW) — pin version, fork if needed
3. Platform API changes (LOW-MEDIUM) — n8n workflows easy to update
<!-- END GENERATED: deep-research/spec-findings -->
