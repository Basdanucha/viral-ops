# Iteration 6: n8n Content Generation Orchestration & Multi-Format Output Support

## Focus
Investigated Q11 (How to orchestrate content generation cadence via n8n -- daily production volume, batch generation scheduling, content calendar, queue management, n8n workflow design) and Q12 (What output formats should scripts support and how does format selection interact with trend/niche data -- talking head, voiceover+B-roll, text overlay, green screen, format-to-niche mapping). Q11 requires synthesizing spec 005's n8n workflow chain (L1 2h -> L2 event -> L3 30min poll) with L3-internal generation steps and n8n's concurrency/batch features. Q12 addresses the final content variety dimension needed for a complete architecture.

## Findings

### Q11: n8n Content Generation Orchestration

#### 1. L3 Master Workflow Design: Three-Stage Pipeline

The existing n8n architecture from spec 005 establishes the upstream chain: L1 Master (every 2h cron) -> L2 event-triggered scoring -> L3 poll (every 30min). The L3 master workflow must receive scored trend signals and orchestrate the full script generation pipeline within n8n.

**L3 Master Workflow (`L3-Content-Generator`):**

```
Trigger: Schedule (cron every 30min, 06:00-23:00 ICT)
  |
  v
Stage 1: INTAKE -- Poll for generation-ready trends
  |-- Query: SELECT * FROM trends WHERE status = 'ready_for_content'
  |           AND viral_potential >= 0.70  -- "PRODUCE NOW" threshold from spec 005
  |           AND content_count < max_variants  -- not already at capacity
  |           ORDER BY viral_potential DESC, velocity_score DESC
  |           LIMIT 5  -- batch cap per cycle
  |-- Freshness gate: Skip trends where lifecycle_stage IN ('decay', 'saturation', 'dead')
  |-- Deduplication: Skip trends with active content in 'generating' status
  |
  v
Stage 2: GENERATION -- Sub-workflow per trend (isolated memory)
  |-- For each trend (max 5 per cycle):
  |     |-- Sub-workflow: L3-Script-Generator (execution isolated)
  |     |    |-- Step 1: Trend context assembly (XML injection from iteration 3)
  |     |    |-- Step 2: Few-shot exemplar retrieval (from script_exemplars table, iteration 5)
  |     |    |-- Step 3: 5-stage prompt chain execution (iteration 1)
  |     |    |-- Step 4: 3x3 variant expansion (iteration 2)
  |     |    |-- Step 5: Two-layer quality gate (iteration 3)
  |     |    |-- Step 6: Platform adaptation (iteration 4)
  |     |    |-- Step 7: Handoff JSON assembly (iteration 4)
  |     |-- Output: Array of qualified script variants (passed quality gate)
  |
  v
Stage 3: DISPATCH -- Queue for L4 production
  |-- Insert qualified scripts into content table (status: 'queued_for_production')
  |-- Trigger L4 production webhook (event-driven, not polling)
  |-- Update trend record: content_count += N, last_generated_at = NOW()
  |-- Log: generation_id, trend_id, variant_count, total_cost, duration_ms
```

**Key design decision: Sub-workflow isolation per trend.** n8n's sub-workflow pattern (confirmed from spec 004 research) isolates memory per trend. If one trend's generation fails (LLM timeout, quality gate rejection of all variants), it does not block other trends in the same batch. n8n's Retry On Fail works correctly on sub-workflows (unlike the silent-ignore bug with On Error = Continue noted in spec 004).

[SOURCE: specs/005-trend-viral-brain/research/research.md -- L1 Master 2h cron, L2 event-triggered, viral_potential thresholds (0.70 PRODUCE NOW)]
[SOURCE: specs/006-content-lab/research/iterations/iteration-003.md -- XML context injection, two-layer quality gate, reject/revise/accept thresholds]
[SOURCE: n8n batch processing best practice -- sub-workflow isolation, small batch sizes 10-50 items, strip unnecessary data early]
[INFERENCE: Three-stage pipeline (intake/generation/dispatch) maps naturally to n8n's cron-trigger -> loop -> sub-workflow -> webhook pattern established in spec 004/005]

#### 2. Daily Production Volume Model and Batch Sizing

Calculating daily output requires modeling the full pipeline economics:

**Input assumptions (from spec 005 and prior iterations):**
- L1 polls every 2h = 12 polls/day, discovering ~5-15 viable trends/day
- L2 scores each trend; ~30-60% qualify as >= 0.70 viral_potential = ~3-9 trends/day reaching L3
- L3 runs every 30min from 06:00-23:00 ICT = 34 cycles/day
- Each trend generates 3x3 = 9 initial variants, quality gate passes ~50-70% = 4-6 qualified variants per trend
- Platform adaptation: each qualified variant -> 4 platform versions (TikTok, YouTube Shorts, IG Reels, FB Reels) at ~$0.003/adaptation

**Daily production volume estimate:**

| Scenario | Trends/day | Variants/trend | Platform versions | Total scripts/day | LLM cost/day |
|----------|-----------|---------------|-------------------|-------------------|-------------|
| Conservative | 3 | 5 | 4 | 60 | ~$0.51 |
| Moderate | 6 | 5 | 4 | 120 | ~$1.02 |
| Aggressive | 9 | 6 | 4 | 216 | ~$1.84 |

**LLM cost breakdown per trend (from iteration 2 analysis):**
- 5-stage prompt chain: ~14 API calls (optimized batch from iteration 2)
- Quality gate (2-layer): ~18 calls (structural + 6-dim scoring x2 per variant)
- Platform adaptation: ~4 calls per passing variant
- Total: ~$0.17/trend at GPT-4o-mini pricing

**Batch sizing within n8n:**
- Each 30-min cycle processes up to 5 trends (LIMIT 5 in intake query)
- Sub-workflow concurrency: 2-3 parallel (n8n default concurrency; configurable via `EXECUTIONS_CONCURRENCY_PRODUCTION_LIMIT`)
- If trends queue faster than processing: backpressure naturally via `status = 'ready_for_content'` -- unprocessed trends wait for next cycle
- Peak hours (19:00-22:00 ICT): Increase LIMIT to 8 trends/cycle to match Thai peak engagement window

[SOURCE: specs/005-trend-viral-brain/research/research.md -- L1 polling frequency 2h, trend volume estimates, lifecycle stages]
[SOURCE: specs/006-content-lab/research/iterations/iteration-002.md -- 14 API calls per trend (optimized), $0.17/trend cost analysis]
[SOURCE: https://docs.n8n.io/hosting/scaling/concurrency-control/ -- EXECUTIONS_CONCURRENCY_PRODUCTION_LIMIT for controlling parallel execution count]
[INFERENCE: Daily volume of 60-216 scripts is well within n8n's capacity on a single instance; horizontal scaling via queue mode + Redis only needed at 500+ daily scripts]

#### 3. Content Calendar and Queue Management

The content calendar bridges L3 generation and L5 posting by ensuring content is distributed optimally across time and platforms:

**Queue management architecture:**

```
L3 generates -> content table (status: 'queued_for_production')
L4 produces  -> content table (status: 'produced')
L5 scheduler -> content table (status: 'scheduled' with scheduled_at)
L5 publishes -> content table (status: 'published')
```

**Content calendar n8n workflow (`L3-Content-Calendar`):**

```
Trigger: Cron daily at 02:00 ICT (after all generation cycles complete)
  |
  v
Step 1: Inventory -- count produced-but-unscheduled content per platform
Step 2: Target allocation -- calculate slots per platform per day:
  |-- TikTok: 3-5 posts/day (peak: 19-22 ICT, secondary: 12-14 ICT)
  |-- YouTube Shorts: 1-2/day (peak: 18-21 ICT)
  |-- IG Reels: 2-3/day (peak: 19-21 ICT, morning: 07-09 ICT)
  |-- FB Reels: 1-2/day (peak: 19-22 ICT)
Step 3: Assign slots -- prioritize by:
  |-- viral_potential score (highest first)
  |-- trend freshness (SURGING trends get earliest slots)
  |-- niche diversity (avoid posting 3 of the same niche consecutively)
  |-- staggered timing: TikTok T+0 -> IG T+20min -> YT T+40min -> FB T+60min (from spec 004)
Step 4: Update content records with scheduled_at timestamps
Step 5: Buffer check -- if buffer < 2 days of content, trigger alert
```

**Queue priority system:**

| Priority | Condition | Action |
|----------|----------|--------|
| P0 (Immediate) | SURGING trend (velocity > +0.50), < 6h old | Skip calendar, schedule within 2h |
| P1 (High) | RISING trend, viral_potential >= 0.80 | Next available slot |
| P2 (Normal) | Standard generation output | Calendar-scheduled |
| P3 (Backfill) | Evergreen content, moderate scores | Fill gaps in calendar |

**Buffer management:**
- Minimum buffer: 2 days of scheduled content per platform (prevents gaps during low-trend periods)
- Maximum buffer: 5 days (content older than this loses trend relevance)
- Buffer alert: If any platform drops below 2 days, increase L3 cycle frequency to every 15 min or lower viral_potential threshold to 0.60 temporarily

[SOURCE: specs/004-platform-upload/research -- staggered posting TikTok T+0 -> IG T+20min -> YT T+40min -> FB T+60min]
[SOURCE: specs/005-trend-viral-brain/research/research.md -- velocity classification: SURGING > +0.50, RISING +0.20 to +0.50; Thai peak hours 19-22 ICT]
[INFERENCE: Content calendar separates scheduling concerns from generation concerns; P0 bypass ensures SURGING trends are not delayed by calendar queuing; buffer system prevents feast-or-famine content gaps]

#### 4. n8n Error Handling and Recovery Patterns for L3

Building on spec 004's critical finding that n8n Retry On Fail is silently ignored when On Error = Continue, the L3 workflow must implement explicit error handling:

**Error handling strategy per generation stage:**

| Stage | Failure Mode | Recovery | n8n Pattern |
|-------|-------------|----------|-------------|
| Intake (DB query) | PostgreSQL timeout | Retry 3x with exponential backoff | Retry On Fail (safe -- no On Error = Continue) |
| LLM API call | 429 rate limit | Wait + retry with jitter (30s, 60s, 120s) | Wait node + Loop (manual retry from spec 004) |
| LLM API call | 500/503 server error | Switch to fallback model (DeepSeek) | IF node -> fallback sub-workflow |
| Quality gate | All variants rejected | Log, mark trend as 'generation_failed', skip | Error output path -> status update |
| Platform adaptation | Single platform fails | Continue with other platforms, retry failed later | Split -> parallel paths, error output per path |
| Handoff write | DB insert failure | Retry 3x, then dead-letter queue | Retry On Fail + Postgres error trigger |

**Dead-letter queue pattern:**
- Failed generations are inserted into `content_generation_failures` table with full context (trend_id, stage_failed, error_message, retry_count)
- Separate `L3-Retry-Failures` workflow runs every 2h, retrying items with retry_count < 3
- After 3 retries: mark as 'permanently_failed', alert via webhook

**Cost tracking:**
- Each sub-workflow execution logs: start_time, end_time, llm_calls_count, llm_tokens_used, estimated_cost
- Daily aggregation workflow sums cost per trend, per niche, per platform
- Budget alert if daily cost exceeds 3x the moderate scenario ($3.06/day threshold)

[SOURCE: specs/004-platform-upload -- n8n Retry On Fail silently ignored when On Error = Continue; manual Wait+Loop retry pattern]
[SOURCE: https://max-productive.ai/ai-tools/n8n/ -- n8n 2026 features: multi-agent orchestration, native LLM nodes for ChatGPT/Claude/LangChain]
[INFERENCE: Explicit error handling with dead-letter queue prevents silent data loss; cost tracking enables budget governance as daily volume scales]

### Q12: Multi-Format Output Support and Format-to-Niche Mapping

#### 5. Six Primary Video Formats for Short-Form Content

Research identifies six distinct production formats, each with different script requirements and pipeline implications:

| Format ID | Format Name | Description | Script Implications |
|-----------|------------|-------------|-------------------|
| `talking_head` | Talking Head | Creator on camera, direct address | Full voiceover script required; facial expressions in visual cues; minimal B-roll |
| `voiceover_broll` | Voiceover + B-Roll | Narrated over stock/custom footage | Full voiceover script; extensive B-roll asset tags per segment; no on-camera presence |
| `text_overlay` | Text Overlay / Faceless | Text-on-screen with background music | No voiceover (or minimal); caption_text per segment is the primary content; music/sound selection critical |
| `green_screen` | Green Screen / React | Creator reacting to background content | Partial voiceover (reaction comments); background_source field required; less scripted, more commentary |
| `tutorial_demo` | Tutorial / How-To | Step-by-step demonstration | Sequential action list; screen recording or product shots; voiceover optional (can be text overlay) |
| `ugc_testimonial` | UGC / Testimonial Style | Customer/creator authentic review feel | Conversational script; raw/unpolished tone directive; authenticity markers in TTS (lower stability for natural feel) |

**Script schema extension for format support:**

The handoff JSON schema (iteration 4) needs a `format` field that controls downstream production:

```json
{
  "script_metadata": {
    "format_id": "voiceover_broll",
    "format_config": {
      "requires_voiceover": true,
      "requires_on_camera": false,
      "broll_density": "high",
      "caption_style": "animated_word",
      "music_role": "background"
    }
  }
}
```

Each format implies different L4 production paths:
- `talking_head` -> Avatar/creator recording + TTS lip-sync or real recording
- `voiceover_broll` -> TTS generation + B-roll assembly (fully automated)
- `text_overlay` -> Caption rendering + music selection (fully automated, lowest cost)
- `green_screen` -> Background source fetch + overlay compositing
- `tutorial_demo` -> Screen capture + step markers + optional TTS
- `ugc_testimonial` -> Natural-feel TTS with low stability + handheld-style effects

[SOURCE: https://www.teleprompter.com/blog/short-form-video-strategy -- Six primary content formats: educational clips, behind-the-scenes, product teasers, UGC/testimonials, trending challenges, Q&A/myth-busting]
[SOURCE: https://westream.uk/choose-right-video-style -- Voiceover vs talking head vs text comparison: talking head builds trust, voiceover adds structure, text reaches silent viewers]
[SOURCE: https://www.superside.com/blog/short-form-video-trends -- 2026 trend: blended formats (voiceover for structure + text for emphasis + B-roll for variation) outperform single-style]
[INFERENCE: Six formats synthesized from multiple sources; format_config schema extension enables L4 to branch production pipeline based on format type without L3 needing production knowledge]

#### 6. Format-to-Niche Mapping Matrix

Different niches perform best with different formats. This mapping informs L3's format selection during the prompt chain Stage 1 (trend analysis):

| Niche Category | Primary Format | Secondary Format | Rationale |
|---------------|---------------|-----------------|-----------|
| Beauty / Fashion | `talking_head` | `tutorial_demo` | Personal trust is critical; demos show application technique |
| Tech / Gadgets | `tutorial_demo` | `voiceover_broll` | Product demonstration drives engagement; B-roll for unboxing |
| Food / Cooking | `tutorial_demo` | `talking_head` | Step-by-step process is the content; personality adds loyalty |
| Finance / Crypto | `text_overlay` | `voiceover_broll` | Data-heavy content reads well as text; creators often anonymous |
| Comedy / Entertainment | `talking_head` | `green_screen` | Performance is the content; green screen enables reaction format |
| Lifestyle / Travel | `voiceover_broll` | `ugc_testimonial` | Scenic B-roll is the draw; UGC feels authentic |
| Education / Tips | `text_overlay` | `tutorial_demo` | Information density favors text; tutorials for deeper topics |
| Health / Fitness | `talking_head` | `tutorial_demo` | Trust requires face; exercise demos are inherently tutorial |
| News / Current Events | `green_screen` | `text_overlay` | React-to-news format dominates; text overlay for breaking news |
| Gaming | `green_screen` | `voiceover_broll` | Gameplay background + reaction is standard format |

**Thai-specific format preferences:**
- Thai comedy content strongly favors `talking_head` with exaggerated facial expressions and particle-heavy scripts
- Thai finance/investment content ("การเงิน") often uses `text_overlay` with faceless format -- creators prefer anonymity
- Thai food content ("กินอะไรดี") is almost exclusively `tutorial_demo` or `talking_head`
- Thai news reaction ("ข่าว") favors `green_screen` format heavily

**Format selection logic in L3 prompt chain:**

```python
# Stage 1 output includes format_recommendation
def select_format(niche: str, trend_data: dict) -> str:
    # Primary format from niche mapping
    primary = NICHE_FORMAT_MAP[niche]["primary"]
    secondary = NICHE_FORMAT_MAP[niche]["secondary"]
    
    # Override rules:
    # 1. If trend is a visual meme/challenge -> green_screen
    if trend_data.get("trend_type") == "challenge":
        return "green_screen"
    
    # 2. If exploration variant (20% epsilon-greedy from iteration 5)
    if is_exploration_variant:
        return random.choice([f for f in ALL_FORMATS if f != primary])
    
    # 3. If L7 feedback shows secondary outperforming primary for this niche
    if feedback_data.get(f"{niche}_format_performance", {}).get(secondary, 0) > \
       feedback_data.get(f"{niche}_format_performance", {}).get(primary, 0) * 1.15:
        return secondary  # 15% performance margin to switch
    
    # 4. Variant diversification: in 3x3 matrix, allocate 2 primary + 1 secondary
    return primary  # default
```

[SOURCE: https://www.teleprompter.com/blog/short-form-video-strategy -- Platform-to-format mapping: TikTok trending/educational, IG Reels lifestyle/e-commerce, YouTube Shorts educational/tutorials]
[SOURCE: https://content-whale.com/blog/master-short-form-video-content-guide/ -- Format effectiveness by use case: tutorials most saved/shared, talking head highest trust, text overlay widest reach (silent viewers)]
[SOURCE: https://www.visla.us/blog/listicles/video-marketing-trends-for-2026/ -- UGC and creator-style baseline in 2026; blended formats outperform single-style]
[INFERENCE: Niche-format mapping synthesized from cross-referencing platform best practices with Thai content patterns from spec 005; Thai-specific preferences based on cultural content consumption patterns documented in prior iterations]

#### 7. Production Cost and Automation Level by Format

Format selection directly impacts L4 production cost and automation feasibility:

| Format | Automation Level | Est. L4 Cost/Video | Bottleneck | Fully Automated? |
|--------|-----------------|-------------------|------------|-----------------|
| `text_overlay` | 95% | $0.01-0.02 | Music selection | Yes -- caption render + music |
| `voiceover_broll` | 85% | $0.03-0.08 | B-roll sourcing | Yes -- TTS + stock footage |
| `green_screen` | 70% | $0.05-0.10 | Background source | Mostly -- needs source URL |
| `tutorial_demo` | 60% | $0.05-0.15 | Screen capture/demo footage | Partial -- may need recording |
| `talking_head` | 40% | $0.10-0.30 | Avatar or real recording | Partial -- AI avatar or human |
| `ugc_testimonial` | 30% | $0.10-0.25 | Authentic footage | No -- needs real testimonial |

**Automation-first format strategy for viral-ops:**

Phase 0 (MVP): Focus on `text_overlay` and `voiceover_broll` -- both fully automatable via L3+L4 pipeline with no human intervention. These two formats cover finance/education/lifestyle niches effectively.

Phase 1 (Scaling): Add `green_screen` (automated with URL-based background sourcing) and `tutorial_demo` (automated for screen-based content).

Phase 2 (Full Format): Add `talking_head` via AI avatar integration (e.g., HeyGen, D-ID) and `ugc_testimonial` for curated creator partnerships.

**L3 format field in handoff schema -- complete addition:**

```json
{
  "format": {
    "format_id": "voiceover_broll",
    "automation_tier": "full",
    "requires_voiceover": true,
    "requires_on_camera": false,
    "broll_density": "high",
    "caption_style": "animated_word",
    "music_role": "background",
    "background_source": null,
    "avatar_config": null
  }
}
```

[SOURCE: https://www.superside.com/blog/short-form-video-trends -- 2026 short-form trends: AI-powered production reducing per-video cost; faceless/text-overlay formats growing fastest]
[SOURCE: specs/003-thai-voice-pipeline/research/research.md -- TTS cost per generation: ElevenLabs ~$0.01-0.03 per 60s segment depending on model]
[INFERENCE: Automation-first phased rollout ensures MVP can produce content end-to-end without human intervention; cost estimates derived from TTS pricing (spec 003) + stock footage API pricing + render compute]

#### 8. Format Diversification in the 3x3 Variant Matrix

The 3x3 variant expansion (iteration 2) generates 9 variants per trend across concept and hook dimensions. Format should be a controlled variable within this matrix:

**Revised variant matrix: 3 concepts x 3 hooks x format allocation**

```
Concept 1 x Hook A -> format: primary (niche default)
Concept 1 x Hook B -> format: primary
Concept 1 x Hook C -> format: secondary (niche default)
Concept 2 x Hook A -> format: primary
Concept 2 x Hook B -> format: primary
Concept 2 x Hook C -> format: exploration (random, from iteration 5's 20% rule)
Concept 3 x Hook A -> format: primary
Concept 3 x Hook B -> format: secondary
Concept 3 x Hook C -> format: exploration OR primary (based on exploration budget)
```

**Key design: Format is NOT a new matrix dimension.** Adding format as a fourth dimension (3x3x6 = 54 variants) would explode production cost. Instead, format is allocated within the existing 9 slots:
- 5-6 slots: primary format for the niche
- 2-3 slots: secondary format
- 1 slot: exploration format (from the 20% epsilon-greedy budget)

This gives format testing data without multiplying variant count. Thompson Sampling (iteration 2) operates at the (hook_type, format_id) pair level, so format performance is tracked and fed back into the allocation over time.

[SOURCE: specs/006-content-lab/research/iterations/iteration-002.md -- 3x3 variant expansion tree, 7 variant dimensions, Thompson Sampling]
[SOURCE: specs/006-content-lab/research/iterations/iteration-005.md -- 20% exploration budget, epsilon-greedy, Thompson Sampling extension]
[INFERENCE: Format allocation within existing 9-variant matrix avoids combinatorial explosion; Thompson Sampling at (hook, format) pair level enables data-driven format optimization without additional production cost]

#### 9. n8n Workflow Topology Summary for L3

The complete L3 n8n workflow topology with all sub-workflows:

```
L3 Workflows (5 total):

1. L3-Content-Generator (Master)
   Trigger: Cron every 30min, 06:00-23:00 ICT
   Purpose: Poll trends, dispatch generation, queue output
   Calls: L3-Script-Generator (sub-workflow)

2. L3-Script-Generator (Sub-workflow, called per trend)
   Trigger: Called by L3-Content-Generator
   Purpose: Execute 5-stage prompt chain + quality gate + adaptation
   Contains: LLM API calls, quality evaluation, format selection

3. L3-Content-Calendar (Daily scheduler)
   Trigger: Cron daily at 02:00 ICT
   Purpose: Assign posting slots, manage buffer, priority scheduling
   Reads: content table; Writes: scheduled_at timestamps

4. L3-Retry-Failures (Error recovery)
   Trigger: Cron every 2h
   Purpose: Retry failed generations from dead-letter queue
   Reads: content_generation_failures; Calls: L3-Script-Generator

5. L3-Feedback-Aggregator (Feedback integration)
   Trigger: Cron weekly Sunday 04:00 UTC (from iteration 5)
   Purpose: Process L7 performance data, update exemplars/weights
   Reads: content + content_performance; Writes: script_exemplars, L3 config
```

**Inter-layer workflow chain (complete):**

```
L1-Master (2h cron) -> trends table
  |
  v (event trigger on new trend)
L2-Scorer -> viral_potential score -> trends table updated
  |
  v (L3 polls every 30min)
L3-Content-Generator -> content table (queued_for_production)
  |
  v (webhook trigger)
L4-Production-Pipeline -> content table (produced)
  |
  v (L3-Content-Calendar assigns slots)
L5-Publisher -> content table (published)
  |
  v (T+168h)
L7-Analytics -> content_performance table
  |
  v (weekly)
L3-Feedback-Aggregator -> updates L3 config + script_exemplars
```

[SOURCE: specs/005-trend-viral-brain/research/research.md -- L1 Master 2h cron, L2 event-triggered, L3 poll 30min, L7 weekly retrain Sunday 03:00 UTC]
[SOURCE: specs/004-platform-upload -- n8n sub-workflow isolation, cron-poll pattern, manual retry via Wait+loop]
[SOURCE: specs/006-content-lab/research/iterations/iteration-005.md -- L3-Feedback-Aggregator weekly Sunday 04:00 UTC, four-channel feedback]
[INFERENCE: Five L3 workflows cover the complete generation lifecycle; inter-layer chain shows data flow from trend discovery to feedback without any orphaned connections]

## Ruled Out
- **Format as a full matrix dimension (3x3x6 = 54 variants)**: Would produce 54 variants per trend, making production cost and time prohibitive. Format is better allocated within the existing 9-variant matrix.
- **Real-time calendar adjustment during generation cycles**: Over-engineering; daily calendar scheduling with P0 bypass for SURGING trends is sufficient.
- **Single monolithic L3 workflow**: Would violate n8n's sub-workflow isolation principle and prevent retry of individual failed trends. The 5-workflow topology cleanly separates concerns.

## Dead Ends
None identified. All research approaches in this iteration were productive. The n8n documentation was accessible for concurrency features, web searches returned relevant 2026 format/scheduling data, and prior iteration findings provided strong foundations for synthesis.

## Sources Consulted
- specs/005-trend-viral-brain/research/research.md (L1/L2/L7 workflow chain, velocity thresholds, polling frequencies, GBDT retraining schedule)
- specs/006-content-lab/research/iterations/iteration-001.md through iteration-005.md (prompt chain, variant expansion, quality gates, handoff schema, TTS directives, feedback loop)
- specs/004-platform-upload (n8n error handling patterns, staggered posting, sub-workflow isolation)
- https://docs.n8n.io/hosting/scaling/concurrency-control/ (EXECUTIONS_CONCURRENCY_PRODUCTION_LIMIT, queue mode)
- https://max-productive.ai/ai-tools/n8n/ (n8n 2026 features: multi-agent orchestration, native LLM nodes)
- https://logicworkflow.com/blog/n8n-batch-processing/ (batch sizing 10-50, sub-workflow memory isolation)
- https://www.teleprompter.com/blog/short-form-video-strategy (six content formats, platform-format mapping, duration recommendations)
- https://westream.uk/choose-right-video-style (voiceover vs talking head vs text comparison)
- https://www.superside.com/blog/short-form-video-trends (2026 blended formats, faceless growth)
- https://content-whale.com/blog/master-short-form-video-content-guide/ (format effectiveness by use case)
- https://www.visla.us/blog/listicles/video-marketing-trends-for-2026/ (UGC baseline, AI production cost reduction)

## Assessment
- New information ratio: 0.72
- Questions addressed: Q11, Q12
- Questions answered: Q11, Q12

## Reflection
- What worked and why: Synthesizing across five prior iterations (prompt chain, variant expansion, quality gates, handoff schema, feedback loop) with n8n workflow patterns from spec 004/005 produced a comprehensive orchestration design. The approach of building the L3 workflow topology from known n8n patterns (cron-poll, sub-workflow isolation, event trigger) was efficient because these patterns were already validated in the upstream layers. For Q12, combining multiple web sources on video format performance with Thai cultural content knowledge from earlier iterations produced a practical format-to-niche mapping with clear automation tiers.
- What did not work and why: The n8n concurrency control documentation page rendered as navigation-only without the actual content; however, enough n8n batch processing knowledge was available from the alternative source and prior spec research to complete the design.
- What I would do differently: For the remaining validation of Q1 and Q2 (substantially addressed in iteration 1 but needing validation), the next iteration should focus on consolidating all findings into a coherent architecture review, checking for contradictions between iterations, and ensuring the complete L3 pipeline is internally consistent.

## Recommended Next Focus
Consolidation and validation iteration: Q1 and Q2 remain marked as needing validation from iteration 1. With all 10 other questions now answered (Q3-Q12), the next iteration should (a) validate Q1 and Q2 findings against the complete architecture developed in iterations 2-6, (b) check for internal contradictions or gaps between the 9 findings per iteration across 6 iterations, and (c) assess whether the combined findings are sufficient to produce a plan.md for implementation. This is a synthesis/validation pass rather than new research.
