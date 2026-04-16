# Iteration 13: Final Convergence Synthesis -- Definitive Complete Architecture Document

## Focus
Consolidate ALL 12 prior iterations into the definitive, complete architecture document for viral-ops. This synthesis integrates every layer: infrastructure (iter 1-8), intelligence (iter 9-11), and multi-channel identity (iter 12) into a single authoritative reference covering all 7 pipeline layers, both Path A and Path B, complete DB schema, per-layer architecture, and updated build plan.

## Findings

### Finding 1: Consolidated 7-Layer Architecture Covering Both Paths
[INFERENCE: based on iterations 1-12 synthesis]

The final architecture comprises 7 functional layers that both Path A (trend-driven) and Path B (product-driven) share from Layer 4 onward:

| Layer | Name | Path A | Path B | Service |
|-------|------|--------|--------|---------|
| 1 | Discovery | Trend scraping (snscrape, pytrends, YT API) | Product catalog scanning (TikTok Shop, Shopee, Lazada) | n8n + external APIs |
| 2 | Intelligence | Viral Brain scoring (LLM-as-judge) | Product scoring (rule-based formula) | n8n Code node + LLM |
| 3 | Content Lab | Hook variant testing (sequential A/B) | Product script template selection | n8n + Pixelle-Video |
| 4 | Production | Script -> TTS -> Image -> Video composition | Same pipeline, product images as input | Pixelle-Video :8000 |
| 5 | Distribution | 4-platform upload (TikTok, YT, IG, FB) | Same with staggered multi-channel posting | n8n + platform APIs |
| 6 | Monetization | Cart pin per platform (auto/partial/manual) | Affiliate link generation + cart pin | n8n + Shop APIs |
| 7 | Feedback | Analytics pull (T+6h, T+48h, T+168h) -> retrain | Same + product conversion tracking | n8n cron + Analytics APIs |

### Finding 2: Complete Database Schema -- 14 Tables + 1 View
[INFERENCE: based on iterations 6, 7, 10, 11, 12 schema designs consolidated]

The complete PostgreSQL schema consolidates all tables discovered across 5 iterations:

**Core content pipeline (iter 6):**
- `platform_accounts` -- Per-platform OAuth/cookie auth storage
- `content` -- Platform-agnostic video/script/metadata
- `platform_publishes` -- Per-platform publish state (1 content -> N platforms)
- `platform_analytics` -- Per-publish performance metrics
- `upload_queue` -- Scheduling + retry management
- `affiliate_links` -- Per-platform product/cart links with method tracking

**Intelligence tables (iter 9-11):**
- `trends` -- Scraped trend signals with momentum scores
- `products` -- Cross-platform product catalog with scoring
- `product_score_history` -- Score versioning for ML training

**Content Lab tables (iter 10):**
- `content_variants` -- Hook variant tracking (A/B test subjects)
- `ab_tests` -- Test pair management and winner declaration

**Multi-channel tables (iter 12):**
- `channels` -- Per-channel persona config, voice, workflow, hooks
- `channel_platform_accounts` -- M:N link (channel -> platform accounts)
- `channel_persona_history` -- Prompt versioning for performance correlation

**View:**
- `content_calendar` -- Cross-platform scheduling dashboard

### Finding 3: Updated Phase 1 MVP Build Plan -- 6 Sprints / 12 Weeks
[INFERENCE: based on iteration 8 plan expanded with intelligence layers from iterations 9-12]

The original 4-sprint plan (iter 8) covered infrastructure only. Adding intelligence layers requires 2 additional sprints:

- Sprint 1-4: Infrastructure (unchanged from iter 8) -- Fork, schema, pipeline, upload, affiliate
- Sprint 5 (Wk 9-10): Trend Layer + Viral Brain -- snscrape integration, trend pipeline, LLM scoring rubric, scoring dashboard
- Sprint 6 (Wk 11-12): Content Lab + Multi-Channel -- A/B testing workflow, channels table, persona injection, staggered posting

Phase 2 remains: GBDT retraining, Product Discovery (Path B), Index-TTS, multi-tenant.

### Finding 4: Complete Decision Record -- 15 Major Decisions
[SOURCE: iterations 1-12, all decisions with rationale]

All 15 architectural decisions documented with alternatives considered and rationale:
1. SaaS boilerplate: next-saas-stripe-starter (7 candidates evaluated)
2. Video engine: Pixelle-Video (5 candidates evaluated)
3. Orchestrator: n8n self-hosted (4 options considered)
4. Thai TTS: Edge-TTS Phase 1 / Index-TTS Phase 2+
5. TikTok upload: TikTokAutoUploader Phase 1 / Official API Phase 2
6. UI components: ShadCN UI + Tremor
7. DB/ORM: Prisma + PostgreSQL
8. Shopping APIs: Direct HTTP via n8n (all OSS wrappers inadequate)
9. GPU strategy: Split pipeline (CPU local + cloud GPU)
10. Trend scraping: snscrape + pytrends + YT API (TikTok Research API blocked)
11. Viral scoring: LLM-as-judge Phase 1 / GBDT Phase 2
12. A/B testing: Sequential variant testing (no platform offers native A/B)
13. Analytics ingestion: 3-pull schedule (T+6h, T+48h, T+168h)
14. Product discovery: TikTok Shop + Shopee + Lazada APIs
15. Multi-channel: Single n8n pipeline with dynamic channel config injection

### Finding 5: Complete Risk Assessment -- 8 Risks Across All Layers
[INFERENCE: based on risks identified in iterations 1-12]

| Risk | Severity | Layer | Mitigation |
|------|----------|-------|------------|
| TikTokAutoUploader ban | MEDIUM | Distribution | Rate-limit + apply for official API |
| Pixelle-Video maturity | MEDIUM-LOW | Production | Pin version + fork + HTTP API stability |
| Platform API changes | LOW-MEDIUM | Distribution/Monetization | n8n workflow editability + JSONB flexibility |
| TikTok duplicate detection | MEDIUM | Multi-Channel | 6-dimension differentiation per channel |
| Trend scraping blocking | MEDIUM | Discovery | Multiple sources + Apify fallback |
| LLM scoring inconsistency | LOW-MEDIUM | Intelligence | Calibration benchmarks + GBDT migration |
| Analytics API data delay | LOW | Feedback | 3-pull schedule already accounts for 24-48h delay |
| SE Asian e-commerce API instability | MEDIUM | Monetization (Path B) | Multi-platform redundancy |

### Finding 6: Architecture Completeness Verification
[INFERENCE: cross-referencing all 27 questions against final architecture]

All 27 research questions have been answered and their answers are reflected in the architecture:
- Q1-Q8: Infrastructure stack (Dashboard, Video Engine, Orchestrator, DB, UI, Auth, Licensing)
- Q9-Q14: Video engine selection and integration
- Q15-Q21: Multi-platform upload and shopping/affiliate APIs
- Q22-Q23: Trend Layer and Viral Brain intelligence
- Q24-Q25: Content Lab A/B testing and Feedback Loop analytics
- Q26: Product Discovery (Path B) pipeline
- Q27: Multi-channel identity and persona management

No remaining gaps found. The architecture is ready for implementation.

## Ruled Out
No new approaches ruled out -- this is a synthesis iteration.

## Dead Ends
None new. All dead ends from iterations 1-12 remain valid.

## Sources Consulted
- specs/001-base-app-research/research/iterations/iteration-001.md through iteration-012.md
- specs/001-base-app-research/research/research.md
- specs/001-base-app-research/research/deep-research-strategy.md
- specs/001-base-app-research/research/deep-research-state.jsonl

## Assessment
- New information ratio: 0.20
- Questions addressed: All 27 (Q1-Q27) -- final consolidation
- Questions answered: All 27 previously answered; this iteration consolidates them

## Reflection
- What worked and why: Progressive synthesis across 12 iterations meant the final consolidation required no new research. Each iteration built on the previous, and the research.md was kept current. The 7-layer architecture model cleanly maps both Path A and Path B.
- What did not work and why: N/A -- pure synthesis iteration.
- What I would do differently: The original 4-sprint MVP plan (iter 8) was incomplete because intelligence layers had not yet been researched. The updated 6-sprint plan better reflects the full system scope.

## Recommended Next Focus
Research is COMPLETE. Next step is implementation via spec folder creation for Sprint 1 (Fork boilerplate, Prisma schema, n8n setup, Pixelle-Video integration test).
