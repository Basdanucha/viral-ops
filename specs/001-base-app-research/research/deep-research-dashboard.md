---
title: Deep Research Dashboard
description: Auto-generated reducer view over the research packet.
---

# Deep Research Dashboard - Session Overview

Auto-generated from JSONL state log, iteration files, findings registry, and strategy state. Never manually edited.

<!-- ANCHOR:overview -->
## 1. OVERVIEW

Reducer-generated observability surface for the active research packet.

<!-- /ANCHOR:overview -->
<!-- ANCHOR:status -->
## 2. STATUS
- Topic: Find the best open-source base app to fork as the foundation for viral-ops, including UI stack for the dashboard
- Started: 2026-04-16T12:00:00Z
- Status: INITIALIZED
- Iteration: 13 of 25
- Session ID: dr-1776310994-5288
- Parent Session: none
- Lifecycle Mode: new
- Generation: 1
- continuedFromRun: none

<!-- /ANCHOR:status -->
<!-- ANCHOR:progress -->
## 3. PROGRESS

| # | Focus | Track | Ratio | Findings | Status |
|---|-------|-------|-------|----------|--------|
| 1 | OSS SaaS boilerplate landscape survey — identify and evaluate top candidates | landscape-survey | 0.90 | 6 | complete |
| 2 | Deep-dive fork viability: BoxyHQ, Open SaaS (Wasp), next-saas-stripe-starter, Cal.com | fork-viability | 0.83 | 6 | complete |
| 3 | OSS video generation engine deep-dive: Pixelle-Video vs MoneyPrinterTurbo vs short-video-maker vs TikTok-Forge | video-gen-engine | 0.92 | 6 | complete |
| 4 | Pixelle-Video deep-dive: API architecture, Thai TTS verification, ComfyUI workflows, GPU requirements, code modularity | video-gen-engine-integration | 0.92 | 6 | complete |
| 5 | n8n integration pattern, glue architecture, Index-TTS Thai voice cloning | integration-architecture | 0.83 | 6 | complete |
| 6 | Multi-platform upload strategy (TikTok, YouTube Shorts, Instagram Reels, Facebook Reels) + multi-platform DB schema design | multi-platform-upload | 0.92 | 6 | complete |
| 7 | Affiliate/Shopping API deep-dive: cart pin (ปักตะกร้า) across TikTok, YouTube, Instagram, Facebook | affiliate-shopping-api | 0.92 | 6 | complete |
| 8 | CONVERGENCE SYNTHESIS — consolidate all 7 iterations into definitive Phase 1 architecture recommendation | convergence-synthesis | 0.35 | 6 | complete |
| 9 | Intelligence layers — Trend Layer (scraping/monitoring) + Viral Brain (scoring algorithm) | intelligence-layers | 0.92 | 6 | complete |
| 10 | Content Lab A/B testing (Q24) + Feedback Loop analytics APIs (Q25) | intelligence-layers | 0.83 | 6 | complete |
| 11 | Product Discovery (Path B) — affiliate catalog scanning, product scoring, affiliate link generation, product-first script generation | product-discovery-path-b | 0.92 | 6 | complete |
| 12 | Multi-channel identity & persona management — per-channel persona DB schema, Pixelle-Video per-request config, n8n branching, TikTok fingerprinting/penalty, LLM persona prompts | multi-channel-identity | 0.92 | 6 | complete |
| 13 | FINAL CONVERGENCE SYNTHESIS -- definitive complete architecture document covering all 7 layers, both paths, 14 tables, 15 decisions | convergence-synthesis | 0.20 | 6 | complete |

- iterationsCompleted: 13
- keyFindings: 486
- openQuestions: 19
- resolvedQuestions: 1

<!-- /ANCHOR:progress -->
<!-- ANCHOR:questions -->
## 4. QUESTIONS
- Answered: 1/20
- [x] Q1: What are the best OSS SaaS boilerplates/starter kits? → ANSWERED (iter 1-2): next-saas-stripe-starter (top pick for solo start) + BoxyHQ (when multi-tenant needed). Deferred to next phase.
- [ ] Q2: Which UI framework + component library best fits a data-heavy, real-time dashboard? (DEFERRED — revisit after video gen engine decided)
- [ ] Q3: How well do the top candidates support the viral-ops pipeline architecture? (DEFERRED)
- [ ] Q4: Database and ORM trade-offs? (DEFERRED)
- [ ] Q5: Extensibility for video gen, upload, affiliate? (PARTIALLY — depends on video gen engine choice)
- [ ] Q6: Admin/dashboard frameworks? (DEFERRED)
- [ ] Q7: Background job orchestration? (DEFERRED)
- [ ] Q8: Licensing, community health? (DEFERRED — re-evaluate for video gen candidates)
- [ ] Q9: Which OSS video gen engine best covers the full pipeline (script → visuals → TTS → captions → composite) for viral-ops?
- [ ] Q10: How modular are the candidates — can you swap TTS engine, image gen model, composition backend?
- [ ] Q11: Do candidates have API/headless mode for integration with a dashboard/orchestrator?
- [ ] Q12: Multi-language TTS support — especially Thai or pluggable TTS engines?
- [ ] Q13: Active maintenance status (2026) and Windows compatibility?
- [ ] Q14: Are there additional OSS video gen engines beyond Pixelle-Video, short-video-maker, and TikTok-Forge?
- [ ] Q22: TREND LAYER — How to scrape/monitor trending content per platform? APIs (TikTok Creative Center, YT Trending, IG Explore), OSS tools (pentos, exolyt), trend clustering?
- [ ] Q23: VIRAL BRAIN — What algorithms/models/papers exist for viral scoring? Hook strength, curiosity gap, retention prediction? OSS implementations?
- [ ] Q24: CONTENT LAB — How does A/B testing work for short-form video? Variant generation strategies? Hook testing methodology?
- [ ] Q25: FEEDBACK LOOP — How to pull analytics per platform (TikTok Analytics API, YT Analytics, IG Insights)? How to feed data back to re-train scoring?
- [ ] Q26: PRODUCT DISCOVERY (Path B) — How to scan affiliate catalogs? TikTok Shop product search API? Product relevance scoring?
- [ ] Q27: MULTI-CHANNEL IDENTITY — Per-channel persona (voice, style, hooks, ComfyUI workflow), DB schema, Pixelle-Video config, n8n branching, brand consistency rules?

<!-- /ANCHOR:questions -->
<!-- ANCHOR:trend -->
## 5. TREND
- Last 3 ratios: 0.92 -> 0.92 -> 0.20
- Stuck count: 0
- Guard violations: none recorded by the reducer pass
- convergenceScore: 0.20
- coverageBySources: {"affiliate.shopee.co.th":2,"agencyanalytics.com":1,"aiforautomation.io":1,"almcorp.com":1,"api2cart.com":2,"apify.com":3,"arxiv.org":2,"autofaceless.ai":2,"bryanbonifacio.com":1,"code":4,"data365.co":1,"developers.facebook.com":6,"developers.google.com":4,"developers.tiktok.com":4,"docs.n8n.io":4,"driveeditor.com":2,"feedonomics.com":1,"fluxnote.io":2,"github.com":32,"help.involve.asia":1,"houseofmarketers.com":2,"influenceflow.io":1,"insights.ttsvibes.com":2,"joinbrands.com":2,"learn.microsoft.com":2,"medium.com":2,"miraflow.ai":2,"napolify.com":4,"open.lazada.com":2,"opensaas.sh":1,"other":11,"partner.tiktokshop.com":2,"raw.githubusercontent.com":10,"scrapfly.io":1,"seller.shopee.co.th":1,"snscrape.com":2,"support.google.com":2,"virvid.ai":1,"wasp.sh":2,"www.atomwriter.com":2,"www.getphyllo.com":3,"www.mirra.my":2}

<!-- /ANCHOR:trend -->
<!-- ANCHOR:dead-ends -->
## 6. DEAD ENDS
- **Documenso as fork base**: Too domain-specific (document signing), AGPL license, would require extensive gutting. Useful only as reference architecture. (iteration 1)
- **Midday as fork base**: AGPL license requires commercial license, tightly coupled to financial domain. Best used as reference for Supabase + Trigger.dev architecture. (iteration 1)
- Cal.com as fork base is definitively eliminated — the domain coupling is fundamental, not superficial. (iteration 2)
- **Cal.com/Cal.diy as fork base**: Too domain-specific (scheduling/booking), stripping would leave minimal scaffolding. Turborepo monorepo is over-engineered for solo-dev start. Better as architecture reference only. (iteration 2)
- **Reddit-style generators (RedditReels, FullyAutomatedRedditVideoMakerBot)**: Too narrow (Reddit story format), not generalizable to viral-ops content types. (iteration 3)
- **short-video-maker as primary engine**: Windows NOT supported, English-only TTS, stock footage only. Value limited to MCP pattern reference. (iteration 3)
- **short-video-maker for Windows deployment**: Explicitly unsupported, whisper.cpp fails on Windows. Fundamental platform limitation, not a configuration issue. (iteration 3)
- **TikTok-Forge as primary engine**: Too immature (72 stars, 4 commits), no TTS docs, tight n8n coupling. Value limited to architecture reference. (iteration 3)
- **TikTok-Forge for production use**: 4 commits total, no community, no documentation depth. Would require building from near-scratch. (iteration 3)
- **GPU as hard requirement for Phase 1** — TTS, composition, and captions can run CPU-only; RunningHub handles image gen in the cloud. (iteration 4)
- **"Need to build FastAPI wrapper" assumption** — Pixelle-Video already has one. The MoneyPrinterTurbo API pattern reference is less critical than assumed. (iteration 4)
- **Building custom job queue in Next.js dashboard**: Not needed. n8n handles all orchestration, scheduling, retries, and background job management. This eliminates the "no job queue" gap identified in iterations 1-2 for next-saas-stripe-starter. (iteration 5)
- **Index-TTS for immediate Thai support**: The model is primarily Chinese + English. Thai would require cross-lingual transfer with uncertain quality. This is not a viable Phase 1 path. However, this is NOT permanently blocked — Index-TTS is actively developed and may add Thai support. (iteration 5)
- **Index-TTS for Thai in Phase 1**: Not viable without Thai training data. Edge-TTS (3 Thai Neural voices) is sufficient. Index-TTS is a Phase 2+ consideration if Thai voice cloning becomes a priority. (iteration 5)
- **n8n docs website for detailed technical extraction**: The docs.n8n.io site renders as an SPA with minimal content in fetch responses. GitHub README and direct knowledge of n8n's well-documented API are more productive sources. (iteration 5)
- **Affiliate cart pin via Content Posting APIs**: NONE of the four platforms expose cart/product pinning through their content upload APIs — shopping/affiliate is always a separate API surface (iteration 6)
- **Affiliate cart pin via upload API on ANY platform**: All four platforms separate content publishing from commerce/shopping. Cart pin ("ปักตะกร้า") requires separate Shop API integration on each platform. This is a fundamental architectural separation, not a missing feature. (iteration 6)
- **Single unified upload API (upload-post.com)**: Paid service, not OSS — already ruled out in prior iterations, confirmed not viable for our stack (iteration 6)
- **TikTok official API for scheduling**: No `scheduled_publish_time` parameter — scheduling must be handled by n8n + upload queue (iteration 6)
- **Lundehund/tiktok-shop-api** as viable library: Only 12 stars, 7 commits, read-only RapidAPI wrapper. Does not cover Affiliate APIs or any write operations. (iteration 7)
- **OSS wrapper libraries for Shopping APIs**: The available OSS libraries (Lundehund, ipfans, EcomPHP) are all either too immature, wrong language, or read-only. Direct HTTP API calls via n8n is the correct approach for all platforms. (iteration 7)
- **Unified cart pin approach across all platforms**: Each platform has fundamentally different levels of API support (full, partial, none). Architecture must handle all three modes. (iteration 7)
- **YouTube Shopping via API for Phase 1**: No API exists for programmatic product tagging in YouTube videos/Shorts. Must be manual. (iteration 7)
- Building a new admin framework assessment -- ShadCN UI + Tremor covers the dashboard needs without a dedicated admin framework (iteration 8)
- Evaluating alternative ORMs (Drizzle, Kysely) -- Prisma comes with the boilerplate and the viral-ops schema is straightforward relational (iteration 8)
- **drawrowfly/tiktok-scraper as production tool**: Abandoned since July 2021, will break on current TikTok web interface. Architecture reference only. (iteration 9)
- **Medium "Decoding AI Virality" article**: Marketed as "complete guide" but contains no technical depth — no formulas, no academic citations, no OSS tools. Zero research value beyond confirming engagement velocity and emotional resonance as generic dimensions. (iteration 9)
- **TikTok Research API for commercial use**: Requires academic/institutional affiliation, explicitly prohibits commercial applications. Not viable for viral-ops. (iteration 9)
- **Native A/B testing on short-form platforms**: None of the three platforms (TikTok, YouTube Shorts, Instagram Reels) offer built-in A/B testing for organic short-form content. Sequential variant testing is the only viable approach. (iteration 10)
- **Native platform A/B testing for organic short-form video**: This is a fundamental platform limitation, not a missing feature. None of the platforms have incentive to add this because their recommendation algorithms control distribution, making controlled experiments impossible for organic content. (iteration 10)
- **Real-time analytics ingestion**: All platforms have 24-48h data delay, making real-time feedback impossible. Minimum practical polling interval is every 6 hours. (iteration 10)
- **Swipe-away rate via YouTube API**: Visible in YouTube Studio UI but not available via the Analytics API. (iteration 10)
- **Direct web scraping of affiliate platform partner portals**: All three platforms (TikTok Shop Partner Center, Shopee Affiliate, Lazada Open Platform) serve their API documentation as JavaScript SPAs that return minimal content to automated fetches. This is a fundamental architectural pattern across all Southeast Asian e-commerce platforms, not a temporary issue. API documentation can only be accessed through authenticated portal sessions. (iteration 11)
- **Involve Asia help article for Lazada deep link specs**: Redirects to generic help center (301), original article unavailable. (iteration 11)
- **Lazada Open Platform docs for direct API spec extraction**: SPA at open.lazada.com returns only header. Same SPA limitation pattern. (iteration 11)
- **Shopee Affiliate portal for direct API spec extraction**: SPA at affiliate.shopee.co.th/api returns only page title. Requires login for full documentation. (iteration 11)
- **TikTok Shop Partner Center docs for direct API spec extraction**: SPA renders minimal content via WebFetch. Requires authenticated login for full endpoint documentation. Same pattern as iteration 7. (iteration 11)
- **Pixelle-Video LLM endpoint for direct system prompt injection**: The `/api/llm/chat` endpoint does NOT expose a `system_prompt` parameter. Persona prompts must be prepended to the `prompt` field at the n8n orchestration layer. This is a workaround, not a limitation -- the LLM still receives the full persona context. (iteration 12)
- **Separate n8n workflows per channel**: Maintenance overhead scales linearly with channel count. A single universal pipeline with dynamic config injection is the standard pattern for multi-brand automation. (iteration 12)

<!-- /ANCHOR:dead-ends -->
<!-- ANCHOR:next-focus -->
## 7. NEXT FOCUS
Research is COMPLETE. Next step is implementation via spec folder creation for Sprint 1 (Fork boilerplate, Prisma schema, n8n setup, Pixelle-Video integration test).

<!-- /ANCHOR:next-focus -->
<!-- ANCHOR:active-risks -->
## 8. ACTIVE RISKS
- None active beyond normal research uncertainty.

<!-- /ANCHOR:active-risks -->
<!-- ANCHOR:blocked-stops -->
## 9. BLOCKED STOPS
No blocked-stop events recorded.

<!-- /ANCHOR:blocked-stops -->
<!-- ANCHOR:graph-convergence -->
## 10. GRAPH CONVERGENCE
- graphConvergenceScore: 0.00
- graphDecision: [Not recorded]
- graphBlockers: none recorded

<!-- /ANCHOR:graph-convergence -->
