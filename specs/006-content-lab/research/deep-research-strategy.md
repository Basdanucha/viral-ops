# Deep Research Strategy — Content Lab (L3)

<!-- ANCHOR:overview -->
## 1. OVERVIEW

### Purpose
Persistent brain for the Content Lab deep research session. Tracks what to investigate, what worked, what failed, and where to focus next across iterations.

### Usage
- **Init:** Populated from config and prior research context
- **Per iteration:** Agent reads Next Focus, writes evidence, reducer refreshes machine-owned sections
- **Mutability:** Mutable — analyst-owned sections stable, machine-owned sections rewritten by reducer

---

<!-- /ANCHOR:overview -->
<!-- ANCHOR:topic -->
## 2. TOPIC
Content Lab (L3) — LLM script generation for viral short-form video, A/B testing variants, content-to-production handoff, Thai content patterns, platform-specific adaptation, feedback loop integration, content calendar orchestration

---

<!-- /ANCHOR:topic -->
<!-- ANCHOR:key-questions -->
## 3. KEY QUESTIONS (remaining)
- [ ] Q1: What are the best LLM prompting strategies for generating viral video scripts? (structured prompting, chain-of-thought, few-shot, fine-tuning vs prompt engineering, model selection — GPT-4o-mini vs Claude vs DeepSeek for Thai)
- [ ] Q2: What script structures and formats work best for Thai short-form viral content? (hook patterns, timing templates 15/30/60s, cultural humor elements, viral script anatomy)
- [ ] Q3: How should A/B testing work for video content variants before production? (variant dimensions, statistical framework, minimum sample sizes, pre-production vs post-production testing)
- [ ] Q4: How to efficiently generate multiple content variants from a single trend signal? (hook variations, tone shifts, CTA styles, format adaptations, variant count per trend)
- [ ] Q5: How should L1 trend data and L2 viral scores feed into script generation prompts? (context injection format, scoring thresholds as gates, trend freshness validation before generation)
- [ ] Q6: What format/metadata should scripts include for seamless handoff to L4 production pipeline? (shot lists, B-roll suggestions, timing markers, TTS directives, visual cues, asset references)
- [ ] Q7: How should scripts be adapted for different platforms? (TikTok vs YouTube Shorts vs IG Reels format differences, optimal lengths per platform, platform-specific hooks and CTAs)
- [ ] Q8: How to integrate script generation with the Thai voice pipeline (spec 003) for automated voice-over? (script format for TTS, pronunciation hints, pacing markers, PyThaiNLP preprocessing)
- [ ] Q9: How to evaluate script quality before sending to production? (automated quality gates, LLM self-evaluation, scoring rubrics, reject/revise thresholds)
- [ ] Q10: How should performance data from L7 feedback loop influence future script generation? (prompt tuning, template selection, few-shot example curation from top performers, reinforcement signals)
- [ ] Q11: How to orchestrate content generation cadence via n8n? (daily production volume, batch generation scheduling, content calendar, queue management, n8n workflow design)
- [ ] Q12: What output formats should scripts support and how does format selection interact with trend/niche data? (talking head, voiceover+B-roll, text overlay, green screen, format-to-niche mapping)

<!-- /ANCHOR:key-questions -->
<!-- ANCHOR:non-goals -->
## 4. NON-GOALS
- NOT researching video editing/rendering tools (that's L4 Production — spec 002/003)
- NOT researching upload/distribution mechanics (that's L5 — spec 004)
- NOT researching trend discovery/scoring algorithms (that's L1+L2 — spec 005)
- NOT researching monetization strategies (that's L6 — future spec)
- NOT building or coding anything — research only

---

<!-- /ANCHOR:non-goals -->
<!-- ANCHOR:stop-conditions -->
## 5. STOP CONDITIONS
- All 12 key questions answered with actionable findings
- Script generation architecture is clear enough to produce a plan.md
- A/B testing framework is defined with statistical approach
- Integration points with L1/L2 (input) and L4 (output) are specified
- Thai-specific content patterns are documented with examples

---

<!-- /ANCHOR:stop-conditions -->
<!-- ANCHOR:answered-questions -->
## 6. ANSWERED QUESTIONS
[None yet]

<!-- /ANCHOR:answered-questions -->
<!-- MACHINE-OWNED: START -->
<!-- ANCHOR:what-worked -->
## 7. WHAT WORKED
- Starting from the rich spec 005 research base was highly productive. The prior L1+L2 research already documented hook categories, Thai slang, viral content characteristics, and LLM-as-judge patterns. This allowed iteration 1 to synthesize and extend rather than start from scratch. The Anthropic prompting docs provided authoritative backing for the multi-stage chain, XML structuring, and few-shot calibration recommendations. (iteration 1)
- Combining web search for quantitative engagement benchmarks with the existing spec 005 rubric framework produced a complete testing architecture. The arxiv paper on hook analysis (MLLM-VAU) provided academic validation that hook features are the strongest performance predictors, supporting our decision to make hooks the primary variant dimension. Thompson Sampling literature was well-established and directly applicable to content optimization. (iteration 2)
- The combination of Anthropic's prompt engineering docs (authoritative on context injection patterns) and Eugene Yan's LLM evaluator research (comprehensive synthesis of evaluation best practices) provided strong dual-source coverage. Building on spec 005's existing 6-dimension rubric was efficient -- reusing L2 infrastructure for L3 quality gating reduces implementation complexity. The three-gate freshness validation emerged naturally from combining spec 005's lifecycle model with practical pipeline concerns. (iteration 3)
- The StudioBinder AV template provided the foundational two-column model that translated naturally into the JSON handoff schema. Combining this with the 601media AI filmmaking pipeline article (which showed how modern automated pipelines decompose scripts into shot-level metadata) produced a schema that bridges traditional video production conventions with automated pipeline needs. The OpusClip 2026 strategy article provided quantitative platform data (80% silent viewing, 2-second hook window) that directly informed schema design decisions (mandatory captions, platform-specific hook timing). Building on prior iterations (4-beat structure from iter 1, variant model from iter 2, cost analysis from iter 3) was highly efficient. (iteration 4)
- Cross-referencing the actual ElevenLabs API documentation against the iteration 4 handoff schema revealed a critical design correction -- ElevenLabs uses pronunciation dictionaries, not inline SSML. This produced a more robust engine-agnostic directive model. The spec 005 feedback loop design (PSI/KL, Spearman, retraining triggers) translated naturally into L3-specific feedback channels, with the key insight being that L3 needs four distinct channels operating at different frequencies to match the different time constants of each feedback signal. (iteration 5)
- Synthesizing across five prior iterations (prompt chain, variant expansion, quality gates, handoff schema, feedback loop) with n8n workflow patterns from spec 004/005 produced a comprehensive orchestration design. The approach of building the L3 workflow topology from known n8n patterns (cron-poll, sub-workflow isolation, event trigger) was efficient because these patterns were already validated in the upstream layers. For Q12, combining multiple web sources on video format performance with Thai cultural content knowledge from earlier iterations produced a practical format-to-niche mapping with clear automation tiers. (iteration 6)
- Systematic cross-referencing of each Q1/Q2 finding against specific downstream requirements from Q3-Q12 was productive. The structured validation checks (8 specific cross-references + 1 contradiction scan) ensured thorough coverage. The 4-beat structure proved to be a remarkably robust architectural foundation that every subsequent iteration built upon without friction. The cost model consistency check confirmed that the pipeline economics hold end-to-end. (iteration 7)

<!-- /ANCHOR:what-worked -->
<!-- ANCHOR:what-failed -->
## 8. WHAT FAILED
- OpenAI platform docs returned 403 (auth required for new docs site). YouTube video content extraction returned only footer/nav metadata (WebFetch cannot extract video transcripts). The creator economy article returned 404 (URL likely changed or was removed). (iteration 1)
- The BlogBurst article on Thompson Sampling for social media returned 404 (likely removed or restructured). The first web search returned mostly marketing guides rather than technical testing frameworks -- had to refine to include specific statistical terms (Bayesian, Thompson) to find actionable sources. (iteration 2)
- OpenAI Structured Outputs docs returned 403 (consistent with iteration 1 failure -- their docs site now requires authentication). This is a known dead end for WebFetch-based research. (iteration 3)
- The spec 004 research.md file was not found at the expected path, so platform specs came from the strategy.md known context section (which already summarized spec 004 findings). This was sufficient but prevented deeper cross-referencing with upload API constraints. (iteration 4)
- The ElevenLabs docs listing page required a second fetch to the specific endpoint page. The initial fetch returned only endpoint names without parameters. (iteration 5)
- The n8n concurrency control documentation page rendered as navigation-only without the actual content; however, enough n8n batch processing knowledge was available from the alternative source and prior spec research to complete the design. (iteration 6)
- N/A -- all validation checks completed successfully. No external research was needed because the iteration files contained sufficient detail for internal consistency verification. (iteration 7)

<!-- /ANCHOR:what-failed -->
<!-- ANCHOR:exhausted-approaches -->
## 9. EXHAUSTED APPROACHES (do not retry)
### **Classical frequentist A/B testing for content variants**: Requires 30,000+ observations per variant for statistical significance at 95% confidence. Short-form video content rarely achieves this sample size per variant within the Thai trend lifecycle (24-48h). Thompson Sampling with Bayesian updates is strictly superior for this use case. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **Classical frequentist A/B testing for content variants**: Requires 30,000+ observations per variant for statistical significance at 95% confidence. Short-form video content rarely achieves this sample size per variant within the Thai trend lifecycle (24-48h). Thompson Sampling with Bayesian updates is strictly superior for this use case.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Classical frequentist A/B testing for content variants**: Requires 30,000+ observations per variant for statistical significance at 95% confidence. Short-form video content rarely achieves this sample size per variant within the Thai trend lifecycle (24-48h). Thompson Sampling with Bayesian updates is strictly superior for this use case.

### **Format as a full matrix dimension (3x3x6 = 54 variants)**: Would produce 54 variants per trend, making production cost and time prohibitive. Format is better allocated within the existing 9-variant matrix. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **Format as a full matrix dimension (3x3x6 = 54 variants)**: Would produce 54 variants per trend, making production cost and time prohibitive. Format is better allocated within the existing 9-variant matrix.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Format as a full matrix dimension (3x3x6 = 54 variants)**: Would produce 54 variants per trend, making production cost and time prohibitive. Format is better allocated within the existing 9-variant matrix.

### **Full 6-dimension evaluation for every draft**: Running Layer 2 on scripts that fail Layer 1 structural checks wastes API calls. Layer 1 (structural) should gate Layer 2 (quality) to save cost. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Full 6-dimension evaluation for every draft**: Running Layer 2 on scripts that fail Layer 1 structural checks wastes API calls. Layer 1 (structural) should gate Layer 2 (quality) to save cost.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Full 6-dimension evaluation for every draft**: Running Layer 2 on scripts that fail Layer 1 structural checks wastes API calls. Layer 1 (structural) should gate Layer 2 (quality) to save cost.

### **Generating platform-specific scripts from scratch**: Wasteful when 70-80% of content (core narrative, B-roll, TTS settings) is shared across platforms. Adaptation from a base script is strictly more efficient. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Generating platform-specific scripts from scratch**: Wasteful when 70-80% of content (core narrative, B-roll, TTS settings) is shared across platforms. Adaptation from a base script is strictly more efficient.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Generating platform-specific scripts from scratch**: Wasteful when 70-80% of content (core narrative, B-roll, TTS settings) is shared across platforms. Adaptation from a base script is strictly more efficient.

### **Generic creative writing role prompts**: Thai market requires Thai-specific cultural expertise baked into the system prompt. Generic "creative writer" underperforms vs. Thai-specific role. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Generic creative writing role prompts**: Thai market requires Thai-specific cultural expertise baked into the system prompt. Generic "creative writer" underperforms vs. Thai-specific role.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Generic creative writing role prompts**: Thai market requires Thai-specific cultural expertise baked into the system prompt. Generic "creative writer" underperforms vs. Thai-specific role.

### **Including raw caption timing in L3 handoff**: L3 does not produce audio, so caption timing cannot be determined until L4 generates TTS. L3 provides text; L4 handles timing alignment. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **Including raw caption timing in L3 handoff**: L3 does not produce audio, so caption timing cannot be determined until L4 generates TTS. L3 provides text; L4 handles timing alignment.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Including raw caption timing in L3 handoff**: L3 does not produce audio, so caption timing cannot be determined until L4 generates TTS. L3 provides text; L4 handles timing alignment.

### **Inline SSML in L3 handoff for all engines**: ElevenLabs does not support SSML. Engine-agnostic directives with L4 translation are strictly better. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Inline SSML in L3 handoff for all engines**: ElevenLabs does not support SSML. Engine-agnostic directives with L4 translation are strictly better.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Inline SSML in L3 handoff for all engines**: ElevenLabs does not support SSML. Engine-agnostic directives with L4 translation are strictly better.

### **L3-side PyThaiNLP preprocessing**: Would interfere with quality gate text evaluation. L4 handles all TTS preprocessing. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **L3-side PyThaiNLP preprocessing**: Would interfere with quality gate text evaluation. L4 handles all TTS preprocessing.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **L3-side PyThaiNLP preprocessing**: Would interfere with quality gate text evaluation. L4 handles all TTS preprocessing.

### **OpenAI Structured Outputs docs**: Returned 403 (authenticated access required). Docs site requires login since restructuring. Not accessible via WebFetch. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **OpenAI Structured Outputs docs**: Returned 403 (authenticated access required). Docs site requires login since restructuring. Not accessible via WebFetch.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **OpenAI Structured Outputs docs**: Returned 403 (authenticated access required). Docs site requires login since restructuring. Not accessible via WebFetch.

### **Real-time calendar adjustment during generation cycles**: Over-engineering; daily calendar scheduling with P0 bypass for SURGING trends is sufficient. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **Real-time calendar adjustment during generation cycles**: Over-engineering; daily calendar scheduling with P0 bypass for SURGING trends is sufficient.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Real-time calendar adjustment during generation cycles**: Over-engineering; daily calendar scheduling with P0 bypass for SURGING trends is sufficient.

### **Real-time per-video prompt tuning**: Individual video performance is too noisy; aggregate signals across cohorts are required for reliable tuning. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Real-time per-video prompt tuning**: Individual video performance is too noisy; aggregate signals across cohorts are required for reliable tuning.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Real-time per-video prompt tuning**: Individual video performance is too noisy; aggregate signals across cohorts are required for reliable tuning.

### **Single-layer evaluation (self-evaluation only)**: LLM self-enhancement bias of 10-25% makes self-evaluation alone unreliable. Two-layer approach with different model families is strictly better. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: **Single-layer evaluation (self-evaluation only)**: LLM self-enhancement bias of 10-25% makes self-evaluation alone unreliable. Two-layer approach with different model families is strictly better.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single-layer evaluation (self-evaluation only)**: LLM self-enhancement bias of 10-25% makes self-evaluation alone unreliable. Two-layer approach with different model families is strictly better.

### **Single monolithic L3 workflow**: Would violate n8n's sub-workflow isolation principle and prevent retry of individual failed trends. The 5-workflow topology cleanly separates concerns. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **Single monolithic L3 workflow**: Would violate n8n's sub-workflow isolation principle and prevent retry of individual failed trends. The 5-workflow topology cleanly separates concerns.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single monolithic L3 workflow**: Would violate n8n's sub-workflow isolation principle and prevent retry of individual failed trends. The 5-workflow topology cleanly separates concerns.

### **Single-prompt script generation**: Multi-stage chain is clearly superior for quality and variant control. A single prompt trying to generate hooks, body, visual cues, and TTS markers simultaneously produces inconsistent results. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: **Single-prompt script generation**: Multi-stage chain is clearly superior for quality and variant control. A single prompt trying to generate hooks, body, visual cues, and TTS markers simultaneously produces inconsistent results.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Single-prompt script generation**: Multi-stage chain is clearly superior for quality and variant control. A single prompt trying to generate hooks, body, visual cues, and TTS markers simultaneously produces inconsistent results.

### **Testing all 7 variant dimensions simultaneously**: A full factorial design across 7 dimensions would produce hundreds of combinations. The 3x3 matrix (concepts x hooks) tests the two highest-impact dimensions while keeping production manageable. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: **Testing all 7 variant dimensions simultaneously**: A full factorial design across 7 dimensions would produce hundreds of combinations. The 3x3 matrix (concepts x hooks) tests the two highest-impact dimensions while keeping production manageable.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Testing all 7 variant dimensions simultaneously**: A full factorial design across 7 dimensions would produce hundreds of combinations. The 3x3 matrix (concepts x hooks) tests the two highest-impact dimensions while keeping production manageable.

<!-- /ANCHOR:exhausted-approaches -->
<!-- ANCHOR:ruled-out-directions -->
## 10. RULED OUT DIRECTIONS
- **Generic creative writing role prompts**: Thai market requires Thai-specific cultural expertise baked into the system prompt. Generic "creative writer" underperforms vs. Thai-specific role. (iteration 1)
- **Single-prompt script generation**: Multi-stage chain is clearly superior for quality and variant control. A single prompt trying to generate hooks, body, visual cues, and TTS markers simultaneously produces inconsistent results. (iteration 1)
- **Classical frequentist A/B testing for content variants**: Requires 30,000+ observations per variant for statistical significance at 95% confidence. Short-form video content rarely achieves this sample size per variant within the Thai trend lifecycle (24-48h). Thompson Sampling with Bayesian updates is strictly superior for this use case. (iteration 2)
- **Testing all 7 variant dimensions simultaneously**: A full factorial design across 7 dimensions would produce hundreds of combinations. The 3x3 matrix (concepts x hooks) tests the two highest-impact dimensions while keeping production manageable. (iteration 2)
- **Full 6-dimension evaluation for every draft**: Running Layer 2 on scripts that fail Layer 1 structural checks wastes API calls. Layer 1 (structural) should gate Layer 2 (quality) to save cost. (iteration 3)
- **OpenAI Structured Outputs docs**: Returned 403 (authenticated access required). Docs site requires login since restructuring. Not accessible via WebFetch. (iteration 3)
- **Single-layer evaluation (self-evaluation only)**: LLM self-enhancement bias of 10-25% makes self-evaluation alone unreliable. Two-layer approach with different model families is strictly better. (iteration 3)
- **Generating platform-specific scripts from scratch**: Wasteful when 70-80% of content (core narrative, B-roll, TTS settings) is shared across platforms. Adaptation from a base script is strictly more efficient. (iteration 4)
- **Including raw caption timing in L3 handoff**: L3 does not produce audio, so caption timing cannot be determined until L4 generates TTS. L3 provides text; L4 handles timing alignment. (iteration 4)
- **Inline SSML in L3 handoff for all engines**: ElevenLabs does not support SSML. Engine-agnostic directives with L4 translation are strictly better. (iteration 5)
- **L3-side PyThaiNLP preprocessing**: Would interfere with quality gate text evaluation. L4 handles all TTS preprocessing. (iteration 5)
- **Real-time per-video prompt tuning**: Individual video performance is too noisy; aggregate signals across cohorts are required for reliable tuning. (iteration 5)
- **Format as a full matrix dimension (3x3x6 = 54 variants)**: Would produce 54 variants per trend, making production cost and time prohibitive. Format is better allocated within the existing 9-variant matrix. (iteration 6)
- **Real-time calendar adjustment during generation cycles**: Over-engineering; daily calendar scheduling with P0 bypass for SURGING trends is sufficient. (iteration 6)
- **Single monolithic L3 workflow**: Would violate n8n's sub-workflow isolation principle and prevent retry of individual failed trends. The 5-workflow topology cleanly separates concerns. (iteration 6)

<!-- /ANCHOR:ruled-out-directions -->
<!-- ANCHOR:next-focus -->
## 11. NEXT FOCUS
All 12 questions are now answered and validated. The research corpus is internally consistent with: - 1 design refinement identified: Stage 5 (TTS Adaptation) should be conditional on format.requires_voiceover - 1 documentation inconsistency: research.md Section 6 TTS fields should reference Section 8's corrected schema - 1 potential risk noted: quality gate pass rate floor mechanism for Phase 0 The findings are sufficient to produce a plan.md for L3 Content Lab implementation. Recommended next step: final synthesis pass to consolidate research.md, then transition to plan.md creation.

<!-- /ANCHOR:next-focus -->
<!-- MACHINE-OWNED: END -->
<!-- ANCHOR:known-context -->
## 12. KNOWN CONTEXT

### From spec 005 (L1 Trend + L2 Viral Brain):
- Trend signals from: pytrends-modern (Google Trends TH), TikTok Creative Center + Apify, YouTube Data API v3
- Viral scoring: 1-5 categorical scale, 6 dimensions (Hook Strength 0.25, Emotional Trigger 0.20, Storytelling 0.15, Visual Potential 0.15, CTA 0.15, Audio Fit 0.10)
- Composite score: content_quality(0.40) + trend_freshness(0.35) + niche_fit(0.15) + timing(0.10)
- Hook generation: 7 categories (question, statistic, controversy, emotion, curiosity, relatable, shock), 3-5 variants per trend
- Model: GPT-4o-mini primary, DeepSeek fallback for Thai
- Thai trend lifecycle: 24-48h (faster than global 72-120h), peak hours 19-22 ICT

### From spec 003 (Thai Voice & Script Pipeline):
- TTS ranking: ElevenLabs > OpenAI > Google > Edge-TTS > F5-TTS-THAI
- PyThaiNLP mandatory for Thai text processing (han_solo engine)
- 60+ Thai particles documented
- Phased approach: Phase 0 basic TTS, Phase 1 voice cloning

### From spec 004 (Platform Upload):
- Content specs per platform: TikTok (3-60s, 9:16, 4GB max), YouTube Shorts (15-60s), IG Reels (3-90s)
- Staggered posting: TikTok T+0 → IG T+20min → YT T+40min → FB T+60min

### From spec 001 (Base App):
- n8n orchestration center, Next.js dashboard, Prisma DB
- Three-service localhost: Dashboard (:3000) → n8n (:5678) → Pixelle-Video (:8000)

---

<!-- /ANCHOR:known-context -->
<!-- ANCHOR:research-boundaries -->
## 13. RESEARCH BOUNDARIES
- Max iterations: 20
- Convergence threshold: 0.05
- Per-iteration budget: 12 tool calls, 10 minutes
- Progressive synthesis: true
- research/research.md ownership: workflow-owned canonical synthesis output
- Machine-owned sections: reducer controls Sections 3, 6, 7-11
- Canonical pause sentinel: research/.deep-research-pause
- Current generation: 1
- Started: 2026-04-17T20:00:00Z
<!-- /ANCHOR:research-boundaries -->
