# Iteration 1: Q1 — Cost Schema & Pricing Feeds

## Focus
Establish authoritative 2026-04 pricing for every LLM/TTS provider in scope (Anthropic Claude Haiku 4.5 / Sonnet 4.6 / Opus 4.7, OpenAI GPT-4o-mini + TTS family, DeepSeek V3.2 chat/reasoner, ElevenLabs tiers + model variants), identify billing units (tokens vs characters vs credits), capture cache/batch discounts, and sketch a provider-agnostic cost-ledger event schema that works for all of them and maps cleanly to a per-content rollup.

## Actions Taken
1. WebFetch Anthropic pricing (https://claude.com/pricing, redirected from anthropic.com/pricing) — captured Haiku/Sonnet/Opus input/output/cache-write/cache-read per-MTok.
2. WebFetch OpenAI pricing (openai.com/api/pricing, platform.openai.com/docs/pricing, openai.com/pricing, openai.com/docs/guides/text-to-speech) — **ALL 403 blocked** by OpenAI's anti-bot. Tier 1 fallback: fetched LiteLLM canonical pricing JSON (BerriAI/litellm main branch) — got gpt-4o-mini confirmed; TTS variants absent from that dataset.
3. WebFetch DeepSeek pricing (api-docs.deepseek.com/quick_start/pricing) — captured V3.2 chat+reasoner input cache-hit/miss and output.
4. WebFetch ElevenLabs pricing (elevenlabs.io/pricing) — captured Starter/Creator/Pro/Scale/Business tier credits + Flash/Turbo discount note + commercial license rules.
5. CocoIndex semantic search for existing cost/token emission points — **daemon crash on Windows** (PipeListener PermissionError, WinError 5). Tier 1 fallback: Grep for `(token_usage|prompt_tokens|cache_creation|cache_read)` and `(cost|billing|ApiCost|CostLedger|tokenCost)` across repo → only framework skill code (system-spec-kit hooks) matched; **no viral-ops application code is present in the repo yet** (confirms greenfield state for Q1 schema design).

## Findings

### F1 — Anthropic Claude pricing confirmed (2026-04-17 capture)
Pricing per 1M tokens USD:

| Model | Input | Output | Cache Write (5-min TTL) | Cache Read |
|---|---|---|---|---|
| Haiku 4.5 | $1.00 | $5.00 | $1.25 | $0.10 |
| Sonnet 4.6 | $3.00 | $15.00 | $3.75 | $0.30 |
| Opus 4.7 | $5.00 | $25.00 | $6.25 | $0.50 |

- Batch API: 50% discount on all three tiers.
- No explicit 1M-context surcharge listed on the current pricing page for these model IDs (contrast: Claude Sonnet 3.5/3.7 historically charged 2× for >200k context via the `claude-sonnet-4-5-1m` family; current Opus 4.7 "1M context" appears to be surcharge-free on this page, **but this needs cross-verification in iteration 2** — the `1m` variant SKU may carry a different price than the base).
- Extended caching (1-hour TTL) is mentioned as available separately but rates weren't pulled from this fetch. [INFERENCE: per historical Anthropic pricing pattern, 1-hour write is typically 2× the 5-minute write rate — must verify iter 2.]
- [SOURCE: https://claude.com/pricing — captured 2026-04-17]

### F2 — DeepSeek V3.2 pricing (2026-04-17 capture)
Per 1M tokens USD, unified across chat and reasoner:

| Mode | Input cache-hit | Input cache-miss | Output |
|---|---|---|---|
| deepseek-chat (V3.2 non-thinking) | $0.028 | $0.28 | $0.42 |
| deepseek-reasoner (V3.2 thinking) | $0.028 | $0.28 | $0.42 |

- No off-peak/discount window mentioned on current docs (this is a **change** from prior V3.1 era which offered a UTC 16:30-00:30 50% discount — **flag for iteration 2**: verify whether the discount window was retired or just not mentioned on this page).
- Both models share pricing; distinction is capability (Thinking Mode toggle) not cost.
- [SOURCE: https://api-docs.deepseek.com/quick_start/pricing — captured 2026-04-17]

### F3 — ElevenLabs tier + credit economics (2026-04-17 capture)

| Tier | $/month | Credits/month | Approx overage | Commercial license |
|---|---|---|---|---|
| Starter | $6 | 30k | ~$0.20/min | Yes |
| Creator | $11 (first month, reg. $22) | 121k | ~$0.18/min | Yes + Pro Voice Clone |
| Pro | $99 | 600k | ~$0.17/min | Yes + 192 kbps audio |
| Scale | $299 | 1.8M | ~$0.17/min | Yes + workspace seats |
| Business | $990 | 6M | ~$0.17/min | Yes |

Credit-per-character economics (critical for cost attribution math):

- **V1 English / V1 Multilingual / V2 Multilingual**: 1 char = 1 credit (baseline).
- **V2 Flash / V2 Turbo English + V2.5 Flash / V2.5 Turbo Multilingual**: 0.5-1 credit per char, tier-dependent discount. [IMPLICATION: if viral-ops defaults to v2.5 Turbo Multilingual for Thai, effective char-cost drops ~33-50% vs v2 Multilingual — material for ROI engine.]
- Commercial license required for any monetized video; Free tier unusable for L2+ output.
- [SOURCE: https://elevenlabs.io/pricing — captured 2026-04-17]

### F4 — GPT-4o-mini LLM pricing (via LiteLLM canonical JSON)
- gpt-4o-mini input: $0.15 per 1M tokens ($1.5e-7/token × 1e6).
- gpt-4o-mini output: $0.60 per 1M tokens ($6e-7/token × 1e6).
- cache_read_input_token_cost: `null` in LiteLLM entry (indicates uniform pricing, no cache discount modeled) — [INFERENCE: OpenAI does offer 50% cached-input discount on 4o-mini per its own pricing page; LiteLLM entry is stale on this field. Verify authoritative rate iteration 2 via alternative mirror.]
- [SOURCE: https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json — captured 2026-04-17]

### F5 — OpenAI TTS pricing: BLOCKED this iteration
- OpenAI's pricing pages (openai.com/pricing, openai.com/api/pricing, platform.openai.com/docs/pricing, platform.openai.com/docs/guides/text-to-speech) all returned HTTP 403 to WebFetch (anti-bot blocking).
- LiteLLM canonical JSON does **not** contain tts-1 / tts-1-hd / gpt-4o-mini-tts entries.
- [INFERENCE: Historical OpenAI TTS rates (public knowledge, ~2024-2025): tts-1 = $15/1M chars, tts-1-hd = $30/1M chars, gpt-4o-mini-tts = $0.60/1M chars input + $12/1M chars audio output. These need 2026-04 reconfirmation but are plausibility anchors for schema design.]
- **Unresolved question:** does OpenAI TTS count Thai characters as 1 per Unicode code point (what we'd naively expect) or as multiple UTF-8 bytes? Historical behavior = 1 char = 1 code point (benefits multibyte scripts vs ElevenLabs which does the same). Must verify via alternative source (e.g., Azure OpenAI docs, OpenAI Python SDK source, or Helicone cost-tracking docs) iteration 2.

### F6 — Codebase state: viral-ops app code not yet present
- Grep across `D:\Dev\Projects\viral-ops` for LLM token-usage patterns (`prompt_tokens`, `cache_creation`, `usage.input_tokens`) returned **14 files, all inside `.opencode/skill/system-spec-kit/` framework code** — zero hits in hypothetical `apps/`, `packages/ai/`, `n8n/workflows/` paths.
- Grep for cost/billing/ApiCost/CostLedger patterns: 18 files, again **all framework-internal** (mcp_server token-budget, session-analytics, ablation framework — none are viral-ops application cost emitters).
- [CONFIRMATION: this validates the "greenfield" assumption from the research strategy — the viral-ops Prisma schema and n8n workflows for cost tracking do not yet exist, so Q1 is pure schema-design territory, not reverse-engineering existing code.]
- [SOURCE: local Grep results over D:\Dev\Projects\viral-ops, 2026-04-17.]

### F7 — Provider-agnostic cost-ledger event schema sketch

Given billing-unit heterogeneity (Anthropic tokens with cache bifurcation, DeepSeek tokens with cache bifurcation, OpenAI tokens/chars/seconds, ElevenLabs credits with model-discount), a single normalized Prisma model needs three layers:

**Layer A — ApiCostLedger (raw event, append-only, one row per provider call)**

```prisma
model ApiCostLedger {
  id              String   @id @default(cuid())
  createdAt       DateTime @default(now())
  // Correlation: tie every cost event back to the content & pipeline stage
  contentId       String?  @index
  pipelineStage   String   @index   // 'L3_script' | 'L3_hook_variant' | 'L4_tts' | 'L5_edit' | 'L6_upload' | 'L7_feedback'
  correlationId   String   @index   // n8n execution_id or SDK request_id for tracing
  // Provider identity
  provider        String   @index   // 'anthropic' | 'openai' | 'deepseek' | 'elevenlabs' | 'google'
  model           String            // 'claude-opus-4-7' | 'gpt-4o-mini' | 'deepseek-chat' | 'eleven_multilingual_v2' | 'tts-1-hd'
  modelVariant    String?           // e.g. '1m-context', 'flash', 'turbo', 'thinking'
  // Billing unit (discriminator)
  unit            String            // 'token' | 'character' | 'credit' | 'second'
  // Volume fields (all nullable, only the relevant unit populated)
  inputUnits      Int?              // tokens in (LLMs) or chars in (TTS)
  outputUnits     Int?              // tokens out (LLMs) or chars synthesized (TTS) or seconds of audio
  cacheReadUnits  Int?              // Anthropic/DeepSeek cache-read tokens
  cacheWriteUnits Int?              // Anthropic cache-creation tokens
  reasoningUnits  Int?              // DeepSeek reasoner thinking tokens (if exposed separately)
  // Pricing snapshot (denormalized for historical audit — prices change!)
  unitPriceInputUSD      Decimal  @db.Decimal(12, 8)
  unitPriceOutputUSD     Decimal? @db.Decimal(12, 8)
  unitPriceCacheReadUSD  Decimal? @db.Decimal(12, 8)
  unitPriceCacheWriteUSD Decimal? @db.Decimal(12, 8)
  priceSnapshotVersion   String    // FK-lookup to PricingCatalog row (e.g. 'anthropic-2026-04-17')
  // Billed total (computed at insert, stored for fast rollup)
  billedUSD       Decimal  @db.Decimal(12, 6)
  // Batch / discount flags
  batchDiscount   Boolean  @default(false)   // Anthropic/OpenAI Batch API 50% off
  offPeakDiscount Boolean  @default(false)   // DeepSeek off-peak window (if restored)
  // Metadata
  rawResponse     Json?             // provider-returned usage dict (source of truth)
  notes           String?
  @@index([contentId, pipelineStage])
  @@index([provider, model, createdAt])
}
```

**Layer B — PricingCatalog (slowly-changing dimension, one row per (provider, model, variant, effectiveDate))**

```prisma
model PricingCatalog {
  id                    String   @id @default(cuid())
  provider              String
  model                 String
  modelVariant          String?
  unit                  String
  effectiveFrom         DateTime
  effectiveTo           DateTime?
  inputPriceUSD         Decimal  @db.Decimal(12, 8)   // per 1 unit (not per 1M — store raw)
  outputPriceUSD        Decimal? @db.Decimal(12, 8)
  cacheReadPriceUSD     Decimal? @db.Decimal(12, 8)
  cacheWritePriceUSD    Decimal? @db.Decimal(12, 8)
  batchDiscountPct      Decimal? @db.Decimal(5, 4)    // 0.5000 = 50% off
  notes                 String?  // e.g. "1M context window surcharge 2x"
  sourceUrl             String
  capturedAt            DateTime
  @@unique([provider, model, modelVariant, effectiveFrom])
}
```

**Layer C — ContentCostRollup (materialized, per-content aggregate, refreshed by n8n job)**

```prisma
model ContentCostRollup {
  id                  String   @id @default(cuid())
  contentId           String   @unique
  // Per-stage totals in USD
  l1TrendCostUSD      Decimal  @db.Decimal(10, 4) @default(0)
  l2ScoringCostUSD    Decimal  @db.Decimal(10, 4) @default(0)
  l3ScriptCostUSD     Decimal  @db.Decimal(10, 4) @default(0)
  l4TtsCostUSD        Decimal  @db.Decimal(10, 4) @default(0)
  l5EditCostUSD       Decimal  @db.Decimal(10, 4) @default(0)
  l6UploadCostUSD     Decimal  @db.Decimal(10, 4) @default(0)
  l7FeedbackCostUSD   Decimal  @db.Decimal(10, 4) @default(0)
  totalCostUSD        Decimal  @db.Decimal(10, 4) @default(0)
  // Provider share (for cost-attribution dashboards)
  anthropicCostUSD    Decimal  @db.Decimal(10, 4) @default(0)
  openaiCostUSD       Decimal  @db.Decimal(10, 4) @default(0)
  deepseekCostUSD     Decimal  @db.Decimal(10, 4) @default(0)
  elevenlabsCostUSD   Decimal  @db.Decimal(10, 4) @default(0)
  // Refresh state
  lastEventAt         DateTime
  lastRollupAt        DateTime @default(now())
  ledgerEventCount    Int      @default(0)
  @@index([totalCostUSD, lastRollupAt])
}
```

**Design rationale:**
- Three-layer split handles the three distinct concerns — (A) immutable raw events for audit, (B) versioned pricing source of truth for historical accuracy when prices change mid-month, (C) denormalized read-side for dashboard latency (<100 ms target per MEMORY.md L7 findings on BUC 4800×/24h throughput ceiling).
- `Decimal(12, 8)` for unit price = 8 decimal places accommodates DeepSeek's $0.028/1M tokens = $0.000000028/token without precision loss.
- `unit` discriminator lets the same table hold token-billed LLMs, char-billed TTS, credit-billed ElevenLabs, and second-billed audio models.
- `rawResponse` Json column = provider-returned `usage` dict — the source of truth if pricing math is ever disputed.
- `priceSnapshotVersion` FK = lets us recompute historical cost if a vendor retroactively corrects a rate (has happened — Anthropic issued a 2023 correction).
- Rollup Layer C is refreshed by n8n cron (hourly) + event-driven on ledger insert for high-value content, avoiding on-read aggregation.

## Ruled Out
- **Single flat table with nullable volume columns for every possible unit** — considered, rejected: leads to 15+ nullable columns, insert-side bugs where wrong unit gets populated, and dashboard queries full of `COALESCE(...)`. Three-layer design is strictly better.
- **Storing only billed USD without pricing snapshot** — rejected: blocks any historical audit if a vendor changes a rate or we discover a computation bug; the raw `usage` dict + versioned `PricingCatalog` lookup is essential for reproducibility.

## Dead Ends
- **CocoIndex semantic search on Windows this session** — daemon crashes at startup with `PermissionError: [WinError 5] Access is denied` on named-pipe creation. Not a research dead-end for the topic, but a tooling dead-end for this machine until the daemon is repaired (separate maintenance spec). Grep + Glob remain available as structural substitutes.
- **WebFetch against openai.com + platform.openai.com** — all endpoints returned 403. Need an alternative source for OpenAI TTS pricing (Helicone docs, Azure OpenAI portal pricing, OpenAI GitHub sample repos, or a cached-snapshot service) in iteration 2. Not a dead-end for the question, just a dead-end for this single source.

## Sources Consulted
- https://claude.com/pricing (captured 2026-04-17) — Anthropic pricing
- https://api-docs.deepseek.com/quick_start/pricing (captured 2026-04-17) — DeepSeek pricing
- https://elevenlabs.io/pricing (captured 2026-04-17) — ElevenLabs pricing
- https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json (captured 2026-04-17) — gpt-4o-mini cross-check
- https://openai.com/pricing + https://platform.openai.com/docs/pricing + https://openai.com/api/pricing + https://platform.openai.com/docs/guides/text-to-speech — **all 403 blocked**
- D:\Dev\Projects\viral-ops (Grep on token_usage + cost patterns) — confirmed greenfield

## Assessment
- **Findings count:** 7 (F1-F7)
- **Fully new findings:** 6 (F1 Anthropic table, F2 DeepSeek table, F3 ElevenLabs tiers, F4 GPT-4o-mini LLM rate, F6 greenfield confirmation, F7 schema sketch)
- **Partially new:** 1 × 0.5 = 0.5 (F5 — OpenAI TTS is partially known via historical public rates but unconfirmed for 2026-04)
- **Redundant/confirmatory:** 0
- **newInfoRatio = (6 + 0.5) / 7 = 0.929** — very high: this is an initialization iteration establishing the pricing baseline + schema from scratch, essentially all information is new-to-state.

**Questions addressed:** Q1 primarily. Schema sketch also partially addresses Q4 (ROI engine's input shape) and Q5 (rollup table feeds dashboard views).

**Questions answered:** Q1 is ~70% answered (4 of 5 providers with firm citations, schema sketched). Remaining 30% = OpenAI TTS pricing reconfirmation + DeepSeek off-peak window verification + Anthropic 1M-context surcharge re-check.

## Reflection
- **What worked and why:** WebFetch on vendor pricing pages succeeded for 3 of 4 (Anthropic via redirect, DeepSeek direct, ElevenLabs direct). Fallback to LiteLLM's canonical JSON filled the gpt-4o-mini gap when OpenAI pages blocked. Causal: vendor pricing pages that don't employ aggressive anti-bot return clean markdown; OpenAI has deliberately hardened its pricing page against scrapers.
- **What didn't work and why:** (1) OpenAI's 403 wall blocks all WebFetch attempts regardless of subdomain/path — root cause is Cloudflare bot-mitigation on openai.com and platform.openai.com. Must pivot to non-OpenAI sources (LiteLLM does not have TTS; Helicone might; Azure OpenAI docs definitely list equivalent pricing). (2) CocoIndex daemon failed on Windows due to named-pipe permissions — unrelated to research scope.
- **What I'd do differently next iteration:** Start OpenAI discovery from Helicone's published cost-tracker (helicone.ai/docs/pricing) or from Azure OpenAI's public pricing page (which mirrors OpenAI direct pricing within ~1-2 cents and is not Cloudflare-blocked). For Anthropic, explicitly fetch the "Claude 1M context" documentation path to confirm zero surcharge or find the hidden one. For DeepSeek, fetch the news/changelog page to confirm whether the off-peak window was killed or just hidden.

## Recommended Next Focus (for Iteration 2)

**Q1 completion + Q2 seed:** Close three remaining Q1 gaps, then pivot to Q2 (quota & rate-limit tracking).

Specifically:
1. **OpenAI TTS pricing 2026-04 verification** via Helicone docs (helicone.ai/docs/openai) or Azure OpenAI pricing (learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models) — confirm tts-1, tts-1-hd, gpt-4o-mini-tts rates + character-counting rule for Thai multibyte.
2. **Anthropic 1M-context surcharge** — fetch claude.com/docs/build-with-claude/context-windows or claude.com/docs/build-with-claude/pricing to confirm whether Opus 4.7 1M context carries a surcharge multiplier vs base 200k.
3. **DeepSeek off-peak window** — fetch api-docs.deepseek.com/news or deepseek.com/changelog to verify whether the UTC 16:30-00:30 50% discount is still active (important for batch-scheduling optimization in Q4 ROI engine).
4. **Begin Q2 (Quota & Rate-Limit Tracking):** cross-reference 004-platform-upload-deepdive findings (TikTok 6 req/min, YouTube 100 quota units/day, IG 400 containers/24h, FB 30 Reels/Page/24h) with LLM/TTS-side quota models — identify which providers expose rate headers (Anthropic `anthropic-ratelimit-requests-remaining`, OpenAI `x-ratelimit-remaining-requests`, etc.) and sketch a `QuotaReservation` table design for pre-emptive reservation.
5. **Validate schema sketch** against any existing viral-ops prior-spec Prisma decisions (007 L7 feedback mentions `rate_limit_tracker` — ensure new tables don't collide) by Grep'ing prior spec folders for `@@index` and `model ` patterns.

**Graph coverage events to register this iteration (for inclusion in JSONL graphEvents):**
- Nodes: `pricing:anthropic`, `pricing:openai`, `pricing:deepseek`, `pricing:elevenlabs`, `pricing:litellm-mirror`, `model:claude-haiku-4-5`, `model:claude-sonnet-4-6`, `model:claude-opus-4-7`, `model:gpt-4o-mini`, `model:deepseek-chat`, `model:deepseek-reasoner`, `model:eleven_multilingual_v2`, `schema:ApiCostLedger`, `schema:PricingCatalog`, `schema:ContentCostRollup`, `question:Q1`, `question:Q2`, `dead-end:cocoindex-windows`, `dead-end:openai-403`.
- Edges: pricing:anthropic PRICES model:claude-*, pricing:openai PRICES model:gpt-4o-mini (via litellm-mirror), pricing:deepseek PRICES model:deepseek-*, pricing:elevenlabs PRICES model:eleven_*, schema:ApiCostLedger FEEDS schema:ContentCostRollup, schema:PricingCatalog NORMALIZES schema:ApiCostLedger, question:Q1 ADDRESSED_BY all schema nodes, question:Q2 NEXT_FOCUS.
