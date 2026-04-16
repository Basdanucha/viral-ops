# Deep Research Strategy

<!-- ANCHOR:overview -->
## 1. OVERVIEW

### Purpose
Find the best open-source base app to fork as the foundation for viral-ops (AI-driven viral content lifecycle SaaS), including the UI stack for its dashboard.

### Usage
- **Init:** Populated from research topic, README.md, and research/notes-initial.md
- **Per iteration:** Agent reads Next Focus, writes iteration evidence, reducer refreshes machine-owned sections
- **Mutability:** Mutable -- analyst-owned sections remain stable, machine-owned sections rewritten by reducer

---

<!-- /ANCHOR:overview -->
<!-- ANCHOR:topic -->
## 2. TOPIC
Find the best open-source base app to fork as the foundation for viral-ops, including UI stack for the dashboard.

viral-ops is a SaaS-style platform where AI drives the full viral lifecycle: trend intelligence, viral scoring, content lab, multi-platform distribution, affiliate monetization, and a feedback loop. Built solo-use first, multi-tenant-ready foundation.

---

<!-- /ANCHOR:topic -->
<!-- ANCHOR:key-questions -->
## 3. KEY QUESTIONS (remaining)
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

<!-- /ANCHOR:key-questions -->
<!-- ANCHOR:non-goals -->
## 4. NON-GOALS
- NOT evaluating video generation tools (already covered in notes-initial.md)
- NOT evaluating TikTok uploaders or platform APIs (already researched)
- NOT building the orchestration layer itself (n8n already identified as candidate)
- NOT designing the Viral Brain scoring algorithm
- NOT comparing commercial SaaS products (only OSS candidates for forking)

---

<!-- /ANCHOR:non-goals -->
<!-- ANCHOR:stop-conditions -->
## 5. STOP CONDITIONS
- Top 3 candidates identified with clear pros/cons matrix
- UI stack decision has concrete recommendation with evidence
- Database/ORM choice narrowed to 1-2 options
- Background job strategy resolved
- All 8 key questions answered or ruled out as unanswerable

---

<!-- /ANCHOR:stop-conditions -->
<!-- ANCHOR:answered-questions -->
## 6. ANSWERED QUESTIONS
- Q1: What are the best OSS SaaS boilerplates/starter kits? → ANSWERED (iter 1-2): next-saas-stripe-starter (top pick for solo start) + BoxyHQ (when multi-tenant needed). Deferred to next phase.

<!-- /ANCHOR:answered-questions -->
<!-- MACHINE-OWNED: START -->
<!-- ANCHOR:what-worked -->
## 7. WHAT WORKED
- Fetching individual GitHub repo pages provided structured, reliable data on stack, features, and community metrics. Comparing 5 candidates in one iteration gave broad coverage. (iteration 1)
- Fetching individual GitHub repo pages continued to yield structured, reliable data on architecture, features, and extensibility. Comparing candidates side-by-side with a viability matrix crystallized trade-offs effectively. (iteration 2)
- Fetching individual GitHub repo pages continues to be the most reliable research method -- structured data on stack, features, stars, activity. WebSearch for discovering additional candidates beyond the known list was essential and surfaced MoneyPrinterTurbo (55.8k stars) which was not in the initial research notes. (iteration 3)
- Fetching the raw `api/app.py` source from GitHub revealed the FastAPI application structure that was invisible from the README alone. The README is UI-focused and does not advertise the REST API — only source code inspection found it. Microsoft's TTS documentation page provided definitive Thai voice data. (iteration 4)
- Combining n8n's GitHub README (reliable structured data) with Index-TTS GitHub page gave two strong independent sources. Building the glue architecture diagram by synthesizing prior iteration findings with new n8n data produced the most valuable output — the three-service localhost diagram is the key deliverable. (iteration 5)
- WebSearch for each platform's official API docs gave comprehensive, authoritative data. The platform APIs are all well-documented by their respective companies (Google, Meta, TikTok). WebFetch on the TikTokAutoUploader GitHub page gave rich feature detail. The combination of official API research + unofficial tool assessment provides a complete picture. (iteration 6)
- WebSearch for each platform's shopping API docs returned high-quality, authoritative results. The TikTok developer blog gave clear Affiliate API capability summary. The Instagram Product Tagging API docs page was the highest-value source — it contains complete endpoint documentation with parameters, making it immediately actionable. Fetching the Lundehund GitHub repo quickly confirmed it was inadequate, saving time. (iteration 7)
- Synthesis from comprehensive prior iterations. Having 7 detailed iteration files with cited sources meant no new web research was needed for the deferred questions -- the answers were derivable from existing evidence. The progressive research.md made it easy to see what had been covered and what gaps remained. (iteration 8)
- WebSearch for platform-specific trend APIs + academic papers yielded the highest-value results. The MLLM-VAU paper discovery was the single most valuable find — it validates LLM-based hook analysis with real-world data at Meta scale. The TTS Vibes hook retention data provided concrete benchmarks that make the scoring rubric calibrated rather than arbitrary. (iteration 9)
- WebSearch for platform-specific analytics API documentation returned high-quality authoritative results. The YouTube Analytics API metrics page was the single highest-value source — it provides exact API field names that are immediately actionable for n8n HTTP Request node configuration. Combining multiple search results for A/B testing methodology provided a comprehensive picture despite no single source covering the full topic. (iteration 10)
- WebSearch for each platform's affiliate API documentation returned good overview results, even though the deep portal pages are SPAs. The TikTok developer blog (same source that worked in iteration 7) remains the most reliable source for TikTok Shop API capabilities. Combining search results from multiple independent sources (official docs, third-party guides like Involve Asia and bryanbonifacio.com, developer blog posts) built a comprehensive picture despite no single source providing full API specs. (iteration 11)
- Fetching Pixelle-Video router source code directly from GitHub raw URLs gave definitive per-request API capability data that no README or documentation page would have shown. The two WebSearch queries produced complementary results -- one for the content automation pattern (persona management) and one for the technical detection mechanisms (fingerprinting). (iteration 12)
- Progressive synthesis across 12 iterations meant the final consolidation required no new research. Each iteration built on the previous, and the research.md was kept current. The 7-layer architecture model cleanly maps both Path A and Path B. (iteration 13)

<!-- /ANCHOR:what-worked -->
<!-- ANCHOR:what-failed -->
## 8. WHAT FAILED
- Could not deeply evaluate job queue architectures or extensibility in a single landscape survey — need focused deep-dives in subsequent iterations. (iteration 1)
- Open SaaS website (opensaas.sh) returned minimal content — the site is likely a SPA that doesn't render well for scraping. Wasp docs landing page was too introductory for deep technical details on ejection/lock-in. Would need to fetch specific sub-pages (e.g., /docs/advanced/jobs). (iteration 2)
- N/A -- all research actions produced useful results this iteration. (iteration 3)
- N/A — all research actions yielded high-value results. (iteration 4)
- n8n docs site (docs.n8n.io) renders as SPA with minimal extractable content. Multiple page fetches returned navigation indexes rather than actual content. GitHub READMEs remain the most reliable web source. (iteration 5)
- N/A — all research actions yielded high-value results. The Facebook Reels search initially returned some Instagram results, but the dedicated WebFetch on the Facebook Reels Publishing docs page resolved this. (iteration 6)
- TikTok Shop Partner Center docs site is an SPA that returns minimal content via WebFetch. The actual API endpoint specifications for TikTok Shop require authenticated access to the Partner Center portal. (iteration 7)
- N/A -- this was a consolidation iteration. The deferred questions (Q2, Q4, Q6, Q8) were intentionally deferred until other decisions were made, and that sequencing turned out correct. (iteration 8)
- The Medium "complete guide" article was clickbait with no technical substance. Generic searches for "viral prediction algorithm open source" return commercial tools (PostEverywhere, Enrich Labs) rather than OSS implementations — the viral prediction space is dominated by proprietary commercial tools. (iteration 9)
- The calculatecreator.com TikTok guide returned a socket error. The Instagram Insights doc page was sparse on Reels-specific metrics — the full API reference would have been better but the key endpoint structure was confirmed. (iteration 10)
- All three e-commerce platform documentation portals (TikTok Shop Partner Center, Shopee Affiliate, Lazada Open Platform) render as JavaScript SPAs that return minimal content to automated fetches. This is consistent with iteration 7 findings and is a fundamental pattern across Southeast Asian e-commerce platforms. The Involve Asia help article for Lazada redirected to a generic help center. (iteration 11)
- Napolify blocks automated fetches (403), but the WebSearch summaries from their articles were sufficiently detailed to extract the technical fingerprinting information. The initial WebFetch on app.py only showed router mounts, not implementations -- had to discover the actual router filenames via the GitHub directory listing. (iteration 12)
- N/A -- pure synthesis iteration. (iteration 13)

<!-- /ANCHOR:what-failed -->
<!-- ANCHOR:exhausted-approaches -->
## 9. EXHAUSTED APPROACHES (do not retry)
### **Affiliate cart pin via Content Posting APIs**: NONE of the four platforms expose cart/product pinning through their content upload APIs — shopping/affiliate is always a separate API surface -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **Affiliate cart pin via Content Posting APIs**: NONE of the four platforms expose cart/product pinning through their content upload APIs — shopping/affiliate is always a separate API surface
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Affiliate cart pin via Content Posting APIs**: NONE of the four platforms expose cart/product pinning through their content upload APIs — shopping/affiliate is always a separate API surface

### **Affiliate cart pin via upload API on ANY platform**: All four platforms separate content publishing from commerce/shopping. Cart pin ("ปักตะกร้า") requires separate Shop API integration on each platform. This is a fundamental architectural separation, not a missing feature. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **Affiliate cart pin via upload API on ANY platform**: All four platforms separate content publishing from commerce/shopping. Cart pin ("ปักตะกร้า") requires separate Shop API integration on each platform. This is a fundamental architectural separation, not a missing feature.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Affiliate cart pin via upload API on ANY platform**: All four platforms separate content publishing from commerce/shopping. Cart pin ("ปักตะกร้า") requires separate Shop API integration on each platform. This is a fundamental architectural separation, not a missing feature.

### Building a new admin framework assessment -- ShadCN UI + Tremor covers the dashboard needs without a dedicated admin framework -- BLOCKED (iteration 8, 1 attempts)
- What was tried: Building a new admin framework assessment -- ShadCN UI + Tremor covers the dashboard needs without a dedicated admin framework
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Building a new admin framework assessment -- ShadCN UI + Tremor covers the dashboard needs without a dedicated admin framework

### **Building custom job queue in Next.js dashboard**: Not needed. n8n handles all orchestration, scheduling, retries, and background job management. This eliminates the "no job queue" gap identified in iterations 1-2 for next-saas-stripe-starter. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Building custom job queue in Next.js dashboard**: Not needed. n8n handles all orchestration, scheduling, retries, and background job management. This eliminates the "no job queue" gap identified in iterations 1-2 for next-saas-stripe-starter.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Building custom job queue in Next.js dashboard**: Not needed. n8n handles all orchestration, scheduling, retries, and background job management. This eliminates the "no job queue" gap identified in iterations 1-2 for next-saas-stripe-starter.

### Cal.com as fork base is definitively eliminated — the domain coupling is fundamental, not superficial. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: Cal.com as fork base is definitively eliminated — the domain coupling is fundamental, not superficial.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Cal.com as fork base is definitively eliminated — the domain coupling is fundamental, not superficial.

### **Cal.com/Cal.diy as fork base**: Too domain-specific (scheduling/booking), stripping would leave minimal scaffolding. Turborepo monorepo is over-engineered for solo-dev start. Better as architecture reference only. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **Cal.com/Cal.diy as fork base**: Too domain-specific (scheduling/booking), stripping would leave minimal scaffolding. Turborepo monorepo is over-engineered for solo-dev start. Better as architecture reference only.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Cal.com/Cal.diy as fork base**: Too domain-specific (scheduling/booking), stripping would leave minimal scaffolding. Turborepo monorepo is over-engineered for solo-dev start. Better as architecture reference only.

### **Direct web scraping of affiliate platform partner portals**: All three platforms (TikTok Shop Partner Center, Shopee Affiliate, Lazada Open Platform) serve their API documentation as JavaScript SPAs that return minimal content to automated fetches. This is a fundamental architectural pattern across all Southeast Asian e-commerce platforms, not a temporary issue. API documentation can only be accessed through authenticated portal sessions. -- BLOCKED (iteration 11, 1 attempts)
- What was tried: **Direct web scraping of affiliate platform partner portals**: All three platforms (TikTok Shop Partner Center, Shopee Affiliate, Lazada Open Platform) serve their API documentation as JavaScript SPAs that return minimal content to automated fetches. This is a fundamental architectural pattern across all Southeast Asian e-commerce platforms, not a temporary issue. API documentation can only be accessed through authenticated portal sessions.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Direct web scraping of affiliate platform partner portals**: All three platforms (TikTok Shop Partner Center, Shopee Affiliate, Lazada Open Platform) serve their API documentation as JavaScript SPAs that return minimal content to automated fetches. This is a fundamental architectural pattern across all Southeast Asian e-commerce platforms, not a temporary issue. API documentation can only be accessed through authenticated portal sessions.

### **Documenso as fork base**: Too domain-specific (document signing), AGPL license, would require extensive gutting. Useful only as reference architecture. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Documenso as fork base**: Too domain-specific (document signing), AGPL license, would require extensive gutting. Useful only as reference architecture.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Documenso as fork base**: Too domain-specific (document signing), AGPL license, would require extensive gutting. Useful only as reference architecture.

### **drawrowfly/tiktok-scraper as production tool**: Abandoned since July 2021, will break on current TikTok web interface. Architecture reference only. -- BLOCKED (iteration 9, 1 attempts)
- What was tried: **drawrowfly/tiktok-scraper as production tool**: Abandoned since July 2021, will break on current TikTok web interface. Architecture reference only.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **drawrowfly/tiktok-scraper as production tool**: Abandoned since July 2021, will break on current TikTok web interface. Architecture reference only.

### Evaluating alternative ORMs (Drizzle, Kysely) -- Prisma comes with the boilerplate and the viral-ops schema is straightforward relational -- BLOCKED (iteration 8, 1 attempts)
- What was tried: Evaluating alternative ORMs (Drizzle, Kysely) -- Prisma comes with the boilerplate and the viral-ops schema is straightforward relational
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Evaluating alternative ORMs (Drizzle, Kysely) -- Prisma comes with the boilerplate and the viral-ops schema is straightforward relational

### **GPU as hard requirement for Phase 1** — TTS, composition, and captions can run CPU-only; RunningHub handles image gen in the cloud. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **GPU as hard requirement for Phase 1** — TTS, composition, and captions can run CPU-only; RunningHub handles image gen in the cloud.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **GPU as hard requirement for Phase 1** — TTS, composition, and captions can run CPU-only; RunningHub handles image gen in the cloud.

### **Index-TTS for immediate Thai support**: The model is primarily Chinese + English. Thai would require cross-lingual transfer with uncertain quality. This is not a viable Phase 1 path. However, this is NOT permanently blocked — Index-TTS is actively developed and may add Thai support. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Index-TTS for immediate Thai support**: The model is primarily Chinese + English. Thai would require cross-lingual transfer with uncertain quality. This is not a viable Phase 1 path. However, this is NOT permanently blocked — Index-TTS is actively developed and may add Thai support.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Index-TTS for immediate Thai support**: The model is primarily Chinese + English. Thai would require cross-lingual transfer with uncertain quality. This is not a viable Phase 1 path. However, this is NOT permanently blocked — Index-TTS is actively developed and may add Thai support.

### **Index-TTS for Thai in Phase 1**: Not viable without Thai training data. Edge-TTS (3 Thai Neural voices) is sufficient. Index-TTS is a Phase 2+ consideration if Thai voice cloning becomes a priority. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Index-TTS for Thai in Phase 1**: Not viable without Thai training data. Edge-TTS (3 Thai Neural voices) is sufficient. Index-TTS is a Phase 2+ consideration if Thai voice cloning becomes a priority.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Index-TTS for Thai in Phase 1**: Not viable without Thai training data. Edge-TTS (3 Thai Neural voices) is sufficient. Index-TTS is a Phase 2+ consideration if Thai voice cloning becomes a priority.

### **Involve Asia help article for Lazada deep link specs**: Redirects to generic help center (301), original article unavailable. -- BLOCKED (iteration 11, 1 attempts)
- What was tried: **Involve Asia help article for Lazada deep link specs**: Redirects to generic help center (301), original article unavailable.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Involve Asia help article for Lazada deep link specs**: Redirects to generic help center (301), original article unavailable.

### **Lazada Open Platform docs for direct API spec extraction**: SPA at open.lazada.com returns only header. Same SPA limitation pattern. -- BLOCKED (iteration 11, 1 attempts)
- What was tried: **Lazada Open Platform docs for direct API spec extraction**: SPA at open.lazada.com returns only header. Same SPA limitation pattern.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Lazada Open Platform docs for direct API spec extraction**: SPA at open.lazada.com returns only header. Same SPA limitation pattern.

### **Lundehund/tiktok-shop-api** as viable library: Only 12 stars, 7 commits, read-only RapidAPI wrapper. Does not cover Affiliate APIs or any write operations. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **Lundehund/tiktok-shop-api** as viable library: Only 12 stars, 7 commits, read-only RapidAPI wrapper. Does not cover Affiliate APIs or any write operations.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Lundehund/tiktok-shop-api** as viable library: Only 12 stars, 7 commits, read-only RapidAPI wrapper. Does not cover Affiliate APIs or any write operations.

### **Medium "Decoding AI Virality" article**: Marketed as "complete guide" but contains no technical depth — no formulas, no academic citations, no OSS tools. Zero research value beyond confirming engagement velocity and emotional resonance as generic dimensions. -- BLOCKED (iteration 9, 1 attempts)
- What was tried: **Medium "Decoding AI Virality" article**: Marketed as "complete guide" but contains no technical depth — no formulas, no academic citations, no OSS tools. Zero research value beyond confirming engagement velocity and emotional resonance as generic dimensions.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Medium "Decoding AI Virality" article**: Marketed as "complete guide" but contains no technical depth — no formulas, no academic citations, no OSS tools. Zero research value beyond confirming engagement velocity and emotional resonance as generic dimensions.

### **Midday as fork base**: AGPL license requires commercial license, tightly coupled to financial domain. Best used as reference for Supabase + Trigger.dev architecture. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Midday as fork base**: AGPL license requires commercial license, tightly coupled to financial domain. Best used as reference for Supabase + Trigger.dev architecture.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Midday as fork base**: AGPL license requires commercial license, tightly coupled to financial domain. Best used as reference for Supabase + Trigger.dev architecture.

### **n8n docs website for detailed technical extraction**: The docs.n8n.io site renders as an SPA with minimal content in fetch responses. GitHub README and direct knowledge of n8n's well-documented API are more productive sources. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **n8n docs website for detailed technical extraction**: The docs.n8n.io site renders as an SPA with minimal content in fetch responses. GitHub README and direct knowledge of n8n's well-documented API are more productive sources.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **n8n docs website for detailed technical extraction**: The docs.n8n.io site renders as an SPA with minimal content in fetch responses. GitHub README and direct knowledge of n8n's well-documented API are more productive sources.

### **Native A/B testing on short-form platforms**: None of the three platforms (TikTok, YouTube Shorts, Instagram Reels) offer built-in A/B testing for organic short-form content. Sequential variant testing is the only viable approach. -- BLOCKED (iteration 10, 1 attempts)
- What was tried: **Native A/B testing on short-form platforms**: None of the three platforms (TikTok, YouTube Shorts, Instagram Reels) offer built-in A/B testing for organic short-form content. Sequential variant testing is the only viable approach.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Native A/B testing on short-form platforms**: None of the three platforms (TikTok, YouTube Shorts, Instagram Reels) offer built-in A/B testing for organic short-form content. Sequential variant testing is the only viable approach.

### **Native platform A/B testing for organic short-form video**: This is a fundamental platform limitation, not a missing feature. None of the platforms have incentive to add this because their recommendation algorithms control distribution, making controlled experiments impossible for organic content. -- BLOCKED (iteration 10, 1 attempts)
- What was tried: **Native platform A/B testing for organic short-form video**: This is a fundamental platform limitation, not a missing feature. None of the platforms have incentive to add this because their recommendation algorithms control distribution, making controlled experiments impossible for organic content.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Native platform A/B testing for organic short-form video**: This is a fundamental platform limitation, not a missing feature. None of the platforms have incentive to add this because their recommendation algorithms control distribution, making controlled experiments impossible for organic content.

### **"Need to build FastAPI wrapper" assumption** — Pixelle-Video already has one. The MoneyPrinterTurbo API pattern reference is less critical than assumed. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **"Need to build FastAPI wrapper" assumption** — Pixelle-Video already has one. The MoneyPrinterTurbo API pattern reference is less critical than assumed.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **"Need to build FastAPI wrapper" assumption** — Pixelle-Video already has one. The MoneyPrinterTurbo API pattern reference is less critical than assumed.

### **OSS wrapper libraries for Shopping APIs**: The available OSS libraries (Lundehund, ipfans, EcomPHP) are all either too immature, wrong language, or read-only. Direct HTTP API calls via n8n is the correct approach for all platforms. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **OSS wrapper libraries for Shopping APIs**: The available OSS libraries (Lundehund, ipfans, EcomPHP) are all either too immature, wrong language, or read-only. Direct HTTP API calls via n8n is the correct approach for all platforms.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **OSS wrapper libraries for Shopping APIs**: The available OSS libraries (Lundehund, ipfans, EcomPHP) are all either too immature, wrong language, or read-only. Direct HTTP API calls via n8n is the correct approach for all platforms.

### **Pixelle-Video LLM endpoint for direct system prompt injection**: The `/api/llm/chat` endpoint does NOT expose a `system_prompt` parameter. Persona prompts must be prepended to the `prompt` field at the n8n orchestration layer. This is a workaround, not a limitation -- the LLM still receives the full persona context. -- BLOCKED (iteration 12, 1 attempts)
- What was tried: **Pixelle-Video LLM endpoint for direct system prompt injection**: The `/api/llm/chat` endpoint does NOT expose a `system_prompt` parameter. Persona prompts must be prepended to the `prompt` field at the n8n orchestration layer. This is a workaround, not a limitation -- the LLM still receives the full persona context.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Pixelle-Video LLM endpoint for direct system prompt injection**: The `/api/llm/chat` endpoint does NOT expose a `system_prompt` parameter. Persona prompts must be prepended to the `prompt` field at the n8n orchestration layer. This is a workaround, not a limitation -- the LLM still receives the full persona context.

### **Real-time analytics ingestion**: All platforms have 24-48h data delay, making real-time feedback impossible. Minimum practical polling interval is every 6 hours. -- BLOCKED (iteration 10, 1 attempts)
- What was tried: **Real-time analytics ingestion**: All platforms have 24-48h data delay, making real-time feedback impossible. Minimum practical polling interval is every 6 hours.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Real-time analytics ingestion**: All platforms have 24-48h data delay, making real-time feedback impossible. Minimum practical polling interval is every 6 hours.

### **Reddit-style generators (RedditReels, FullyAutomatedRedditVideoMakerBot)**: Too narrow (Reddit story format), not generalizable to viral-ops content types. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Reddit-style generators (RedditReels, FullyAutomatedRedditVideoMakerBot)**: Too narrow (Reddit story format), not generalizable to viral-ops content types.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Reddit-style generators (RedditReels, FullyAutomatedRedditVideoMakerBot)**: Too narrow (Reddit story format), not generalizable to viral-ops content types.

### **Separate n8n workflows per channel**: Maintenance overhead scales linearly with channel count. A single universal pipeline with dynamic config injection is the standard pattern for multi-brand automation. -- BLOCKED (iteration 12, 1 attempts)
- What was tried: **Separate n8n workflows per channel**: Maintenance overhead scales linearly with channel count. A single universal pipeline with dynamic config injection is the standard pattern for multi-brand automation.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Separate n8n workflows per channel**: Maintenance overhead scales linearly with channel count. A single universal pipeline with dynamic config injection is the standard pattern for multi-brand automation.

### **Shopee Affiliate portal for direct API spec extraction**: SPA at affiliate.shopee.co.th/api returns only page title. Requires login for full documentation. -- BLOCKED (iteration 11, 1 attempts)
- What was tried: **Shopee Affiliate portal for direct API spec extraction**: SPA at affiliate.shopee.co.th/api returns only page title. Requires login for full documentation.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Shopee Affiliate portal for direct API spec extraction**: SPA at affiliate.shopee.co.th/api returns only page title. Requires login for full documentation.

### **short-video-maker as primary engine**: Windows NOT supported, English-only TTS, stock footage only. Value limited to MCP pattern reference. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **short-video-maker as primary engine**: Windows NOT supported, English-only TTS, stock footage only. Value limited to MCP pattern reference.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **short-video-maker as primary engine**: Windows NOT supported, English-only TTS, stock footage only. Value limited to MCP pattern reference.

### **short-video-maker for Windows deployment**: Explicitly unsupported, whisper.cpp fails on Windows. Fundamental platform limitation, not a configuration issue. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **short-video-maker for Windows deployment**: Explicitly unsupported, whisper.cpp fails on Windows. Fundamental platform limitation, not a configuration issue.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **short-video-maker for Windows deployment**: Explicitly unsupported, whisper.cpp fails on Windows. Fundamental platform limitation, not a configuration issue.

### **Single unified upload API (upload-post.com)**: Paid service, not OSS — already ruled out in prior iterations, confirmed not viable for our stack -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **Single unified upload API (upload-post.com)**: Paid service, not OSS — already ruled out in prior iterations, confirmed not viable for our stack
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single unified upload API (upload-post.com)**: Paid service, not OSS — already ruled out in prior iterations, confirmed not viable for our stack

### **Swipe-away rate via YouTube API**: Visible in YouTube Studio UI but not available via the Analytics API. -- BLOCKED (iteration 10, 1 attempts)
- What was tried: **Swipe-away rate via YouTube API**: Visible in YouTube Studio UI but not available via the Analytics API.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Swipe-away rate via YouTube API**: Visible in YouTube Studio UI but not available via the Analytics API.

### **TikTok-Forge as primary engine**: Too immature (72 stars, 4 commits), no TTS docs, tight n8n coupling. Value limited to architecture reference. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **TikTok-Forge as primary engine**: Too immature (72 stars, 4 commits), no TTS docs, tight n8n coupling. Value limited to architecture reference.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **TikTok-Forge as primary engine**: Too immature (72 stars, 4 commits), no TTS docs, tight n8n coupling. Value limited to architecture reference.

### **TikTok-Forge for production use**: 4 commits total, no community, no documentation depth. Would require building from near-scratch. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **TikTok-Forge for production use**: 4 commits total, no community, no documentation depth. Would require building from near-scratch.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **TikTok-Forge for production use**: 4 commits total, no community, no documentation depth. Would require building from near-scratch.

### **TikTok official API for scheduling**: No `scheduled_publish_time` parameter — scheduling must be handled by n8n + upload queue -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **TikTok official API for scheduling**: No `scheduled_publish_time` parameter — scheduling must be handled by n8n + upload queue
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **TikTok official API for scheduling**: No `scheduled_publish_time` parameter — scheduling must be handled by n8n + upload queue

### **TikTok Research API for commercial use**: Requires academic/institutional affiliation, explicitly prohibits commercial applications. Not viable for viral-ops. -- BLOCKED (iteration 9, 1 attempts)
- What was tried: **TikTok Research API for commercial use**: Requires academic/institutional affiliation, explicitly prohibits commercial applications. Not viable for viral-ops.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **TikTok Research API for commercial use**: Requires academic/institutional affiliation, explicitly prohibits commercial applications. Not viable for viral-ops.

### **TikTok Shop Partner Center docs for direct API spec extraction**: SPA renders minimal content via WebFetch. Requires authenticated login for full endpoint documentation. Same pattern as iteration 7. -- BLOCKED (iteration 11, 1 attempts)
- What was tried: **TikTok Shop Partner Center docs for direct API spec extraction**: SPA renders minimal content via WebFetch. Requires authenticated login for full endpoint documentation. Same pattern as iteration 7.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **TikTok Shop Partner Center docs for direct API spec extraction**: SPA renders minimal content via WebFetch. Requires authenticated login for full endpoint documentation. Same pattern as iteration 7.

### **Unified cart pin approach across all platforms**: Each platform has fundamentally different levels of API support (full, partial, none). Architecture must handle all three modes. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **Unified cart pin approach across all platforms**: Each platform has fundamentally different levels of API support (full, partial, none). Architecture must handle all three modes.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Unified cart pin approach across all platforms**: Each platform has fundamentally different levels of API support (full, partial, none). Architecture must handle all three modes.

### **YouTube Shopping via API for Phase 1**: No API exists for programmatic product tagging in YouTube videos/Shorts. Must be manual. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **YouTube Shopping via API for Phase 1**: No API exists for programmatic product tagging in YouTube videos/Shorts. Must be manual.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **YouTube Shopping via API for Phase 1**: No API exists for programmatic product tagging in YouTube videos/Shorts. Must be manual.

<!-- /ANCHOR:exhausted-approaches -->
<!-- ANCHOR:ruled-out-directions -->
## 10. RULED OUT DIRECTIONS
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

<!-- /ANCHOR:ruled-out-directions -->
<!-- ANCHOR:next-focus -->
## 11. NEXT FOCUS
Research is COMPLETE. Next step is implementation via spec folder creation for Sprint 1 (Fork boilerplate, Prisma schema, n8n setup, Pixelle-Video integration test).

<!-- /ANCHOR:next-focus -->
<!-- MACHINE-OWNED: END -->
<!-- ANCHOR:known-context -->
## 12. KNOWN CONTEXT

### From README.md
- viral-ops: SaaS platform for AI-driven viral content lifecycle
- Two entry paths: Trend-driven (Path A) and Product-driven (Path B) converging into shared Production -> Distribution -> Feedback backbone
- Multi-channel management with viral-only, cart-focused, and mixed modes
- Start solo-use, foundation multi-tenant-ready
- Stack TBD, research phase

### From research/notes-initial.md
- Video gen leads: short-video-maker (MIT, Remotion+Whisper+Kokoro), Pixelle-Video (Apache 2.0, ComfyUI), TikTok-Forge (MIT, Remotion+n8n+OpenAI+Postgres+MinIO)
- Orchestration: n8n identified as candidate for orchestrator layer
- Upload: per-platform APIs or upload-post.com
- Affiliate: tiktok-shop-api (Python), ipfans/tiktok (Go)
- UI tooling: getdesign.md, impeccable.style
- Pattern: Topic -> Script (LLM) -> Visuals -> TTS -> Captions -> Composition -> Upload -> Affiliate pin
- Open questions from notes: self-host vs API video gen, n8n vs custom orchestration, upload strategy, voice engine, Thai language support, affiliate pin API surface

### Key insight
The base app research should find a SaaS shell that can host all these pipeline components. The video gen, uploaders, and orchestration tools are already identified -- what's missing is the "chassis" app that provides auth, dashboard, API layer, job queue, and multi-tenant foundation.

---

<!-- /ANCHOR:known-context -->
<!-- ANCHOR:research-boundaries -->
## 13. RESEARCH BOUNDARIES
- Max iterations: 25
- Convergence threshold: 0.05
- Per-iteration budget: 12 tool calls, 10 minutes
- Progressive synthesis: true
- research/research.md ownership: workflow-owned canonical synthesis output
- Machine-owned sections: reducer controls Sections 3, 6, 7-11
- Canonical pause sentinel: research/.deep-research-pause
- Current generation: 1
- Started: 2026-04-16T12:00:00Z
<!-- /ANCHOR:research-boundaries -->
