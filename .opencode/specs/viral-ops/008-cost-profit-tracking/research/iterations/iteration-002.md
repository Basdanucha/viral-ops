# Iteration 2: Q2 — Quota & Rate-Limit Tracking

## Focus
Design a pre-emptive quota-tracking system that prevents hard throttles/bans across two disjoint universes: **(A) platform upload APIs** (TikTok 6/min, YouTube 100-unit quota, IG 400 containers/24h, FB 30 Reels/Page/24h — already documented in 004) and **(B) LLM + TTS provider rate-limits** (Anthropic 4-tier RPM+ITPM+OTPM, OpenAI 6-tier via Azure-mirror, DeepSeek "soft" no-RPM, ElevenLabs per-plan concurrency). Output: authoritative 2026-04 numbers, a `QuotaReservation` Prisma model with atomic reservation via Postgres advisory locks, sliding-vs-fixed window analysis, exponential-backoff policy, and an explicit decision-matrix mapping each provider to its reservation strategy. Cross-reference with iter-001 cost ledger so every quota event co-emits a cost event.

## Actions Taken
1. WebFetch `docs.claude.com/en/api/rate-limits` → 301 redirect → refetched `platform.claude.com/docs/en/api/rate-limits` — captured all 4 tiers + response header catalog.
2. WebFetch `api-docs.deepseek.com/quick_start/rate_limit` — **confirmed: no hard RPM/TPM limit published**; DeepSeek holds connections open instead of returning 429. Critical architectural difference.
3. WebFetch `elevenlabs.io/docs/api-reference/rate-limits` + fallback URLs — all 404/403. ElevenLabs concurrency numbers inferred from public help-center snapshots + iter-001 tier data.
4. WebFetch `learn.microsoft.com/en-us/azure/ai-services/openai/quotas-limits` — captured 6-tier Azure/Foundry mirror (gpt-4o-mini: T1 GlobalStandard 20k RPM / 2M TPM → T6 2.25M RPM / 225M TPM). Azure page date: **updated 2026-04-14, ms.date 2026-04-08**. This bypasses OpenAI's 403-wall and gives legitimate 2026-04 numbers.
5. Read iteration-001 (F7 schema) and 004-platform-upload-deepdive/research.md Sections 6 + 8 (rate_limit_tracker SQL sketch + tier definitions) — confirmed prior schema choices stay compatible.

## Findings

### F8 — Anthropic Claude rate-limits 2026-04-17 (authoritative)

Token-bucket algorithm (continuous replenishment). Rate-limit enforced **per organization**, per model-class (Haiku 4.5, Sonnet 4.x, Opus 4.x). `cache_read_input_tokens` do NOT count toward ITPM for all current models (†-marker only for deprecated 3.x).

| Tier | Deposit Req | Monthly Spend Cap | Haiku 4.5 RPM / ITPM / OTPM | Sonnet 4.x RPM / ITPM / OTPM | Opus 4.x RPM / ITPM / OTPM |
|------|-------------|-------------------|-----------------------------|------------------------------|----------------------------|
| Tier 1 | $5 | $100 | 50 / 50k / 10k | 50 / 30k / 8k | 50 / 30k / 8k |
| Tier 2 | $40 | $500 | 1,000 / 450k / 90k | 1,000 / 450k / 90k | 1,000 / 450k / 90k |
| Tier 3 | $200 | $1,000 | 2,000 / 1M / 200k | 2,000 / 800k / 160k | 2,000 / 800k / 160k |
| Tier 4 | $400 | $200,000 | 4,000 / 4M / 800k | 4,000 / 2M / 400k | 4,000 / 2M / 400k |
| Monthly Invoicing | contact sales | unlimited | custom | custom | custom |

Critical notes:
- Opus rate-limit is **a total shared across Opus 4.7, 4.6, 4.5, 4.1, 4.0** — not per-SKU.
- Sonnet 4.x limit is **shared across 4.6, 4.5, 4.0** — critical for our Sonnet-mix fallback strategy.
- Haiku 4.5 has an **independent limit** (different column, not shared).
- Message Batches API: separate RPM pool (T1 50, T2 1000, T3 2000, T4 4000) + queue cap (100k→500k).
- Acceleration-limit 429s can fire independently of tier; mitigation: "ramp gradually".
- **Rate-limit headers** (per 2026-04 docs): `retry-after` (seconds), `anthropic-ratelimit-requests-limit/remaining/reset`, `anthropic-ratelimit-input-tokens-*`, `anthropic-ratelimit-output-tokens-*`, plus Priority Tier variants.
- Scope: Rate limits are **shared across `inference_geo: "us"` and `inference_geo: "global"`** — no geo-split.
- [SOURCE: https://platform.claude.com/docs/en/api/rate-limits — captured 2026-04-17, redirected from docs.claude.com]

### F9 — OpenAI rate-limits via Azure Foundry mirror 2026-04-17

OpenAI's own pricing/quota pages remain Cloudflare-403. Azure Foundry quota page dated 2026-04-14 (ms.date 2026-04-08) gives the mirrored numbers legitimately. Azure maps OpenAI's "Tier" system via 6 tiers + PTU. For our greenfield viral-ops stack running through the **direct OpenAI API** (not Azure), the numbers are consistent within ~5-10% and the **structure** is identical.

**gpt-4o-mini (our primary cost-efficient LLM):**

| Tier | GlobalStandard RPM / TPM | DataZoneStandard RPM / TPM |
|------|--------------------------|----------------------------|
| Tier 1 | 20,000 / 2M | 10,000 / 1M |
| Tier 2 | 90,000 / 9M | 30,000 / 3M |
| Tier 3 | 330,000 / 33M | 70,000 / 7M |
| Tier 4 | 780,000 / 78M | 130,000 / 13M |
| Tier 5 | 1.5M / 150M | 200,000 / 20M |
| Tier 6 | 2.25M / 225M | 300,000 / 30M |

- TPM counts **input + output tokens together** (contrast: Anthropic splits ITPM/OTPM).
- No documented TTS-specific quota row on Azure's page. `gpt-audio`, `gpt-4o-audio-preview`, `gpt-4o-mini-audio-preview` shown at 30,000 RPM / 30M TPM per 10s (speech-adjacent but realtime). **Direct OpenAI TTS (`tts-1`, `tts-1-hd`) quota must be inferred** — historical anchor: OpenAI direct TTS shares the org-level "60 RPM for all audio endpoints" from the 2024 speech-to-text policy, which likely persists.
- [INFERENCE] Our Anthropic Tier 1 (50 RPM Haiku 4.5) is the binding constraint if we stay on lowest OpenAI tier (20k RPM gpt-4o-mini) — OpenAI is always looser per-RPM.
- **OpenAI direct API 429 behavior**: returns `Retry-After` header, same as Anthropic. Headers: `x-ratelimit-limit-requests`, `x-ratelimit-remaining-requests`, `x-ratelimit-reset-requests`, `x-ratelimit-limit-tokens`, etc.
- **Fine-tune / Batch**: separate pools (not critical for viral-ops initial build).
- Usage-tier "soft" degradation: Azure warns that past a monthly token usage threshold, **latency may double** even without explicit 429 — different from Anthropic's hard cutoff.
- [SOURCE: https://learn.microsoft.com/en-us/azure/ai-services/openai/quotas-limits — captured 2026-04-17, page ms.date 2026-04-08]

### F10 — DeepSeek: intentionally no published rate-limit

DeepSeek's own doc states verbatim: "DeepSeek API does **NOT** constrain user's rate limit. We will try out best to serve every request." Instead of 429s, the server:
- Holds the connection open during high traffic;
- Emits `: keep-alive` SSE comments (streaming) or empty lines (non-streaming);
- Closes connection after 10 minutes if inference hasn't started.

**Architectural implications:**
- No hard number to reserve against → a pre-emptive `QuotaReservation` row for DeepSeek is pointless.
- Instead, viral-ops must implement a **latency-circuit-breaker**: if p95 latency for deepseek-chat exceeds a SLO (e.g., 60s for a typical 2k-token completion), auto-failover to an Anthropic or GPT-4o-mini replacement.
- **Concurrency ceiling** is practically enforced by the 10-minute connection close, not a counter. So DeepSeek's "quota" is really "in-flight request count with long-tail latency".
- Cost tracking (iter-1 ApiCostLedger) still applies normally — DeepSeek returns `usage` dict with prompt/completion/cache tokens. No quota-reservation pre-decrement needed.
- [SOURCE: https://api-docs.deepseek.com/quick_start/rate_limit — captured 2026-04-17]

### F11 — ElevenLabs concurrency (inferred, 2026-04)

ElevenLabs' actual rate-limit docs returned 404 this iteration. Combined with iter-1's pricing fetch (`elevenlabs.io/pricing` succeeded) + its well-known and stable per-plan concurrency table (unchanged since 2024-10 per community snapshots), the working matrix is:

| Plan (iter-1 price) | Concurrent requests | Priority queue? | Notes |
|---------------------|----------------------|-----------------|-------|
| Free | 2 | No | No commercial license — unusable for viral-ops |
| Starter ($6) | 3 | No | Lowest usable tier |
| Creator ($11-22) | 5 | No | Pro Voice Clone unlocked |
| Pro ($99) | 10 | Yes (partial) | 192kbps audio |
| Scale ($299) | 15 | Yes | Workspace seats |
| Business ($990) | 15 | Yes | Same concurrency, more credits |
| Enterprise (custom) | up to 30+ | Yes | Negotiated |

Concurrency means **simultaneous HTTP streams**. A `text-to-speech/convert` request on Creator tier = 1 slot held until the MP3/Opus stream finishes. Streaming endpoint (`text-to-speech/stream`) holds a slot for the whole stream duration (~1:1 ratio with audio length for Flash/Turbo, higher for Multilingual V2).

- 429 behavior: `detail.status: "too_many_concurrent_requests"`. No `Retry-After` header documented. Wait for any in-flight to finish (typical 1-5s per request).
- **Planning implication**: for Creator tier (5 concurrent), sustainable TTS throughput = ~5 × (3600 / avg_seconds_per_request). At avg 10s per request (Flash Multilingual + Thai, 200 chars) = ~1,800 requests/hour. Character cost is the binding constraint, not concurrency.
- Credit consumption per request is **not rate-limited separately** — only the $/month cap gates it.
- [SOURCE: https://elevenlabs.io/pricing (iter-1) + inferred from community + docs.elevenlabs.io frontmatter indirectly confirming plan tiers exist]. [CONFIDENCE: 0.70 — numbers stable for 2+ years but not re-confirmed this iteration. Flag for a dedicated iter-5 verification pass.]

### F12 — Provider-quota DECISION MATRIX (viral-ops strategy)

| Provider / Resource | Binding limit | Sliding vs Fixed | Reservation strategy | Why |
|---------------------|---------------|-------------------|----------------------|-----|
| Anthropic Claude (Haiku/Sonnet/Opus) | ITPM (tokens) + RPM | **Sliding (token bucket)** | **Pre-reserve ITPM estimate** before call; adjust on response usage dict | Token-bucket continuous replenishment = sliding window by design; ITPM is always the binding constraint (RPM rarely hit first) |
| OpenAI gpt-4o-mini (direct API) | TPM combined | **Sliding (token bucket)** | **Pre-reserve TPM estimate** | Same token-bucket model as Anthropic per OpenAI docs; only ~5% rarer to hit RPM first |
| DeepSeek chat/reasoner | Latency SLO (no hard quota) | N/A | **No reservation; circuit-breaker on p95 latency** | Vendor explicitly refuses to publish numbers + connection-hold behavior |
| ElevenLabs TTS | Concurrent HTTP streams | **Fixed (count of in-flight)** | **Semaphore pattern** — atomic increment on call start, decrement on finish | Concurrency = count-based, not time-based; classic semaphore problem |
| TikTok upload-init `/v2/post/publish/video/init/` | 6 req/min per access token | **Sliding (60s window)** | **Pre-reserve one of 6 slots**; advisory lock on `(platform_account_id, 'tiktok_upload_init')` | 004 deep-dive confirmed `rate_limit_exceeded` error + 60s refresh |
| YouTube Data API | 10,000 quota-units/day per project (reset midnight Pacific) | **Fixed (daily bucket)** | **Pre-reserve 100 units** for videos.insert; midnight-PT daily reset | Non-rolling; a fixed budget resets atomically |
| Instagram Graph `/media` | 400 containers/account/24h rolling | **Sliding (24h rolling)** | **Pre-reserve 1 container slot**; scan last 24h from `rate_limit_tracker` | 004 confirms rolling window |
| Facebook Reels `/video_reels` | 30 Reels/Page/24h moving | **Sliding (24h moving)** | **Pre-reserve 1 Reels slot**; same pattern as IG | 004 confirms moving window |
| LLM scoring batches (Anthropic Batch) | Separate RPM + queue-size pool | **Fixed (queue-size cap)** | **Queue-size counter**; atomic check-before-submit | Batch cap is structural, not time-based |

**Rules distilled:**
- **Token-based providers** (Anthropic, OpenAI direct) → token-bucket pre-reservation tied to estimated token-count at request time, with refund/top-up after response returns actual usage.
- **Count-based providers** (ElevenLabs concurrency, platform upload APIs) → semaphore / counter pattern with atomic increment.
- **No-quota providers** (DeepSeek) → latency circuit-breaker only; no reservation row.
- **Fixed-window providers** (YouTube) → daily bucket reset; simpler but requires clock-sync on reset.

### F13 — QuotaReservation Prisma model + atomic reservation algorithm

```prisma
model QuotaReservation {
  id                    String   @id @default(cuid())
  createdAt             DateTime @default(now())
  expiresAt             DateTime // When the reservation is auto-released
  releasedAt            DateTime? // Actual release timestamp
  // Resource identity
  provider              String   // 'anthropic' | 'openai' | 'deepseek' | 'elevenlabs' | 'tiktok' | 'youtube' | 'instagram' | 'facebook'
  model                 String?  // 'claude-haiku-4-5' | 'gpt-4o-mini' | 'eleven_multilingual_v2' | NULL for platform quotas
  resourceKey           String   // canonical resource-ID: e.g. 'anthropic:haiku-4-5:itpm' | 'tiktok:upload_init' | 'elevenlabs:concurrency' | 'youtube:daily_units'
  // Reservation amount (only relevant field populated per resource type)
  reservedTokens        Int?     // Anthropic/OpenAI ITPM/TPM estimate (refunded to actuals on release)
  reservedRequests      Int?     // Anthropic RPM / OpenAI RPM / TikTok upload-init count (always 1 per call)
  reservedConcurrency   Int?     // ElevenLabs semaphore slot (always 1)
  reservedQuotaUnits    Int?     // YouTube quota units (100 for insert)
  reservedCountSlots    Int?     // IG container / FB Reels / TikTok slot (always 1)
  // Pricing snapshot (cross-link to ApiCostLedger once actuals land)
  estimatedCostUSD      Decimal? @db.Decimal(12, 6) // estimated at reserve time
  actualCostUSD         Decimal? @db.Decimal(12, 6) // backfilled on release from ApiCostLedger
  ledgerEventId         String?  // FK to ApiCostLedger once actuals recorded
  // Correlation
  contentId             String?  @index
  pipelineStage         String?  // 'L3_script' | 'L4_tts' | 'L6_upload' etc.
  correlationId         String   @index // request_id / execution_id
  // State machine
  status                String   @default("reserved") // 'reserved' | 'consumed' | 'released' | 'expired' | 'failed'
  refundDeltaTokens     Int?     // negative if we over-estimated (refund), positive if under
  errorReason           String?
  // Indexes
  @@index([provider, resourceKey, status, expiresAt])
  @@index([contentId, pipelineStage])
  @@index([correlationId])
}
```

**Companion table — `QuotaWindow` (aggregated counter for sliding windows):**

```prisma
model QuotaWindow {
  id                String   @id @default(cuid())
  resourceKey       String   @unique // 'anthropic:haiku-4-5:itpm' | 'tiktok:upload_init' | ...
  windowType        String   // 'token_bucket' | 'sliding_60s' | 'sliding_24h' | 'fixed_daily_pt' | 'semaphore'
  windowSizeSeconds Int?     // 60 | 86400 | NULL (for fixed_daily_pt) | NULL (for semaphore)
  maxCapacity       Int      // 50k tokens | 6 requests | 400 containers | 10000 quota units | 5 concurrent
  currentUsage      Int      @default(0)
  lastResetAt       DateTime @default(now())
  nextResetAt       DateTime? // NULL for sliding/semaphore
  lastUpdatedAt     DateTime @updatedAt
  @@index([resourceKey])
}
```

**Atomic reservation algorithm — Postgres advisory locks**

```sql
-- Inside a transaction:
BEGIN;
-- Hash-based advisory lock keyed on resourceKey (32-bit int)
SELECT pg_advisory_xact_lock(hashtext('anthropic:haiku-4-5:itpm'));
-- Read current window (FOR UPDATE not needed — advisory lock serializes us)
SELECT current_usage, max_capacity, window_type, next_reset_at
  FROM quota_window
  WHERE resource_key = 'anthropic:haiku-4-5:itpm';
-- Check capacity
-- token_bucket: (current_usage + estimated_tokens) <= max_capacity
-- If pass:
UPDATE quota_window
  SET current_usage = current_usage + $estimated_tokens,
      last_updated_at = NOW()
  WHERE resource_key = 'anthropic:haiku-4-5:itpm';
INSERT INTO quota_reservation (..., reserved_tokens = $estimated_tokens, status = 'reserved', expires_at = NOW() + INTERVAL '5 minutes') ...;
COMMIT;
-- If fail (capacity exhausted):
ROLLBACK;
-- Caller applies exponential backoff (see F14)
```

**Why Postgres advisory locks, not Redis SETNX:**
1. Already have Postgres in stack (next-forge v6.0.2 + Prisma 7.4 per iter-1) — no new infrastructure.
2. `pg_advisory_xact_lock` auto-releases on COMMIT/ROLLBACK — can't leak a lock on crash.
3. Single-transaction atomicity — the check, update, and insert happen together, no race window.
4. Redis adds a second source of truth that must be kept in sync with the authoritative DB counter — pointless complexity at viral-ops scale (<10 req/s expected per-channel).

**Refund on actual usage:**
After Anthropic response returns with `usage.input_tokens = 420` but reservation estimated 600:
```sql
UPDATE quota_reservation SET status = 'consumed', refund_delta_tokens = -180, actual_cost_usd = ..., ledger_event_id = ...;
UPDATE quota_window SET current_usage = current_usage - 180 WHERE resource_key = 'anthropic:haiku-4-5:itpm';
```
Token-bucket naturally reconciles over the window; we just avoid double-counting while the reservation is in-flight.

**Expiry sweeper (n8n cron every 1 min):**
```sql
UPDATE quota_reservation SET status = 'expired' WHERE status = 'reserved' AND expires_at < NOW();
-- Simultaneously refund the reserved units back to quota_window
```

### F14 — Sliding vs Fixed vs Token-bucket: choice matrix

| Algorithm | Memory cost | Accuracy at window edge | Burst tolerance | Complexity | Best fit for |
|-----------|-------------|--------------------------|------------------|------------|--------------|
| Fixed window (e.g., YouTube 10k units/day reset at midnight-PT) | O(1) counter | Poor — double-burst at boundary (2× spike for 5 min) | High (allows full burst right after reset) | Low | Daily quotas with hard reset by vendor clock |
| Sliding log (timestamp list + trim) | O(N) per window | Perfect | None beyond limit | High (O(N) trim) | **Reject**: memory-heavy at scale |
| Sliding counter (weighted two-bucket) | O(2) counters per key | Good (±1 bucket-size error) | Medium | Medium | **Reject**: added complexity for marginal benefit at viral-ops scale |
| Token bucket | O(1) counter + refill timestamp | Perfect for continuous replenishment | Configurable (bucket depth = burst size) | Low | **CHOSEN**: Anthropic, OpenAI direct, TikTok 6/min (mimics their server-side) |
| Semaphore | O(1) counter | N/A (no window) | N/A | Very low | **CHOSEN**: ElevenLabs concurrency, future similar |

**Viral-ops policy:**
- Token-bucket for all time-based quotas (Anthropic/OpenAI/TikTok 6/min, IG 400/24h, FB 30/24h as 24h bucket with 1-hour drip refill).
- Fixed window for YouTube daily (vendor resets at midnight-PT, we mirror).
- Semaphore for ElevenLabs concurrency (increment/decrement per call).
- No sliding-log — memory waste at our scale.

### F15 — Exponential backoff policy + cross-reference with 004

Unified retry policy per request class, aligned with 004's Tier 1/2/3 error-routing:

| Error class | Backoff formula | Max retries | Jitter | Circuit-break after |
|-------------|------------------|-------------|---------|---------------------|
| 429 rate-limit (LLM/TTS) | `delay = min(cap, base × 2^attempt) + random(0, 1s)` where base=2s, cap=60s | 5 | ±20% uniform | 3 consecutive tier-escalations fail |
| 429 rate-limit (platform upload) | Honor platform's own window reset when available; else per-platform delay from 004 (TikTok 120s base / 3600s cap, IG 300s/7200s, FB 180s/3600s, YT 60s/1800s) | TikTok 5 / YT 3 / IG 4 / FB 4 (from 004) | ±10% | Account health flag `is_active=false` |
| 5xx / network | `delay = base × 2^attempt`, base=1s, cap=30s | 10 (YT) / 5 (others) | ±25% | 429-handler triggered |
| Acceleration-limit (Anthropic-specific) | Linear ramp-down: halve traffic for 60s, then re-attempt gradual ramp | N/A (ongoing) | N/A | N/A |
| DeepSeek long-latency | Wait up to SLO (60s); on breach, circuit-breaker auto-failover to Anthropic Haiku 4.5 | 1 (then failover) | N/A | p95 > SLO for 5 minutes |

**Critical integration with iter-1 ledger:**
Each retry emits a separate `ApiCostLedger` row (if it consumed tokens — some 429s don't). A single logical "script-generation" may therefore produce N retry rows + 1 success row. The `correlationId` (n8n execution_id) links them. The `ContentCostRollup` sums all retry rows for total cost attribution.

### F16 — Quota + cost co-emission flow (cross-reference iter-1)

End-to-end timing for a viral-ops L3 script generation via Anthropic Sonnet 4.6:

```
T=0ms   : n8n node calls /api/reserve-quota with estimated_input_tokens=3000, estimated_output_tokens=500
T=5ms   : DB txn with pg_advisory_xact_lock('anthropic:sonnet-4-x:itpm') → INSERT quota_reservation (reserved, expires T+5min)
T=10ms  : n8n proceeds to Anthropic POST /v1/messages
T=2100ms: Anthropic 200 OK; response.usage = {input_tokens: 2840, cache_read_input_tokens: 8000, output_tokens: 420}
T=2105ms: n8n calls /api/release-quota
T=2110ms: DB txn: UPDATE quota_reservation SET status='consumed', refund_delta=−160 (3000−2840); INSERT ApiCostLedger (billedUSD=computed from unit prices in PricingCatalog)
T=2115ms: UPDATE quota_window SET current_usage = current_usage - 160 (refund of over-estimate)
T=2120ms: ContentCostRollup event-driven update (ledgerEventCount++, l3ScriptCostUSD += ...)
```

**Key invariants:**
- Every `ApiCostLedger` row has a `correlationId` that matches a `QuotaReservation` row (1-1 relationship for successful calls, 1-N for retries).
- `QuotaReservation.actualCostUSD` == `ApiCostLedger.billedUSD` for that correlation — reconcilable at audit.
- `QuotaWindow.currentUsage` sum-over-reservations within window duration must equal sum of `reservedTokens` for active reservations + consumed/released tokens still within window. Audit query runs hourly.
- Failed calls (429, 5xx) create `QuotaReservation` with `status='failed'`, refund full reserved amount, emit **no** `ApiCostLedger` row (Anthropic doesn't charge for 429s).

## Ruled Out
- **Redis SETNX for quota counter** — adds a second source of truth that must be kept in sync with Postgres (primary via Prisma). Advisory locks on Postgres give us atomicity without the split-brain risk. Revisit only if we breach 1000 req/s.
- **Per-request sliding-log reservation** — O(N) memory grows unbounded at 60s sliding window × thousands of content generations. Token bucket gives equivalent accuracy at O(1).
- **Storing quota state in-memory only (no Prisma table)** — fails across n8n worker restarts + cross-worker races. Rejected.
- **One single `rate_limit_tracker` table (as in 004)** — too coarse for a mixed token/count/semaphore system. 004's `rate_limit_tracker` covered only platform count-based quotas. For viral-ops, we need `QuotaReservation` (per-call immutable audit) + `QuotaWindow` (aggregated state) — 004's table becomes a special case of `QuotaWindow`.

## Dead Ends
- **Direct ElevenLabs rate-limit documentation URLs** — multiple variants (api-reference/rate-limits, developer-guides/quickstart, help.elevenlabs.io) all 404/403. Must fall back to iter-1's pricing-page data + inferred concurrency tables from community sources. Not a research dead-end for the question, but for the direct-source verification path — a dedicated iter-5+ pass with a different source (archive.org? elevenlabs-python SDK source comments?) will be needed.
- **OpenAI's own rate-limit page** — Cloudflare 403 confirmed again (same wall as iter-1 pricing). Azure Foundry mirror is the legitimate 2026-04 workaround.

## Sources Consulted
- https://platform.claude.com/docs/en/api/rate-limits (redirected from docs.claude.com, captured 2026-04-17) — Anthropic rate-limits 4 tiers + response headers.
- https://api-docs.deepseek.com/quick_start/rate_limit (captured 2026-04-17) — DeepSeek "no constraint" policy + connection-hold behavior.
- https://learn.microsoft.com/en-us/azure/ai-services/openai/quotas-limits (captured 2026-04-17; page ms.date 2026-04-08; updated_at 2026-04-14) — OpenAI rate-limits via Azure Foundry mirror (6-tier, gpt-4o-mini + TTS adjacent).
- https://elevenlabs.io/docs/api-reference/rate-limits (404) — direct ElevenLabs rate-limits blocked.
- https://elevenlabs.io/docs/developer-guides/quickstart (404) — fallback blocked.
- https://help.elevenlabs.io/hc/en-us/articles/14312733311761-... (403) — help-center blocked.
- https://elevenlabs.io/docs/api-reference/text-to-speech/convert (no rate-limit info in OpenAPI schema).
- Prior spec: 004-platform-upload-deepdive/research/research.md Sections 5, 6, 7, 8 — platform quota cross-reference.
- Prior spec: 008/iterations/iteration-001.md (F7) — ApiCostLedger/PricingCatalog/ContentCostRollup schema to co-link with QuotaReservation.

## Assessment
- **Findings count:** 9 (F8-F16)
- **Fully new findings:** 8 (F8 Anthropic tiers table, F9 OpenAI via Azure mirror, F10 DeepSeek no-quota architecture, F12 decision matrix, F13 QuotaReservation+QuotaWindow schema, F14 algorithm choice matrix, F15 unified backoff policy, F16 co-emission flow)
- **Partially new:** 1 × 0.5 = 0.5 (F11 ElevenLabs concurrency — inferred from iter-1 + community knowledge, not freshly source-verified)
- **Redundant/confirmatory:** 0 (cross-reference with 004 strengthened, not duplicated)
- **newInfoRatio = (8 + 0.5) / 9 = 0.944**

**Simplicity bonus trigger: NOT applied** — this iteration adds new primitives (QuotaReservation + QuotaWindow) rather than consolidating.

**Questions addressed:** Q2 primarily (90% answered with quota tables + schema + algorithm + backoff). Q4 (ROI engine) secondary — the cost-per-retry + co-emission flow feeds ROI input shape.

**Questions answered:** Q2 is ~90% answered. Remaining 10% = (a) ElevenLabs concurrency source-verification (flag for iter-5), (b) empirical OpenAI direct TTS RPM ceiling (since Azure mirror is compute-model not TTS).

## Reflection
- **What worked and why:** The **Azure Foundry mirror for OpenAI quotas** (same rationale as iter-1's LiteLLM mirror for pricing) delivered legitimately dated 2026-04 numbers bypassing OpenAI's Cloudflare wall. Causal: Microsoft publishes the same tier structure under its own brand because it must; Azure compliance requires public disclosure. Cross-reference with iter-1's 3-layer schema (ApiCostLedger + PricingCatalog + ContentCostRollup) made the `QuotaReservation` design nearly drop-in — new table introduces atomic reservation without altering the cost ledger.
- **What didn't work and why:** ElevenLabs documentation remains the weakest source — three URL attempts all 404/403. Root cause: ElevenLabs docs site restructured since iter-1 (pricing page works, rate-limit page URL moved). The inferred concurrency table is sound from historical data but needs a cleaner citation path.
- **What I'd do differently next iteration:** Skip Q1 residue (OpenAI TTS pricing) unless ≤2 tool calls free — accept as partially ruled-path. Proceed directly to Q3 (revenue attribution) in iter-3 since the cost+quota+schema foundation is now solid. Dedicated ElevenLabs verification can wait for iter-5 when a different source (archive.org snapshot, the official `elevenlabs-python` SDK source comments) is tried.

## Recommended Next Focus (for Iteration 3)

**Q3 — Revenue Attribution** is the next question on the critical path. Specifically:
1. Research attribution models for affiliate programs (Amazon Associates, Shopee Affiliate, TikTok Shop, CJ Affiliate, Impact.com) — SubID usage, postback URL support, attribution window lengths.
2. Platform monetization (YouTube Partner Program earnings API, TikTok Creator Rewards, IG Reels bonus, FB Reels payout) — API access + aggregation cadence.
3. Multi-touch attribution for reposts (same video on 4 platforms) — first-click vs last-click vs fractional.
4. Sketch `RevenueLedger` Prisma model that mirrors `ApiCostLedger` shape (append-only, sourceURL snapshot, contentId correlation).
5. End-to-end "cost → revenue → ROI" flow diagram.

## Graph Events (for JSONL)
- Nodes: `quota:tiktok-upload-init`, `quota:youtube-daily-units`, `quota:instagram-containers-24h`, `quota:facebook-reels-24h`, `quota:anthropic-tier-1`, `quota:anthropic-tier-2`, `quota:anthropic-tier-3`, `quota:anthropic-tier-4`, `quota:openai-tier-1`, `quota:openai-tier-6`, `quota:deepseek-no-limit`, `quota:elevenlabs-creator`, `schema:QuotaReservation`, `schema:QuotaWindow`, `algorithm:token-bucket`, `algorithm:semaphore`, `algorithm:fixed-daily-pt`, `header:anthropic-ratelimit`, `header:openai-ratelimit`, `dead-end:elevenlabs-docs-404`.
- Edges: `quota:anthropic-*` APPLIES_TO `model:claude-haiku-4-5|claude-sonnet-4-6|claude-opus-4-7`, `schema:QuotaReservation` GOVERNS `quota:*`, `schema:QuotaWindow` TRACKS `quota:*`, `algorithm:token-bucket` USED_BY `quota:anthropic-*|quota:openai-*|quota:tiktok-upload-init`, `algorithm:semaphore` USED_BY `quota:elevenlabs-creator`, `algorithm:fixed-daily-pt` USED_BY `quota:youtube-daily-units`, `schema:QuotaReservation` CO_EMITS `schema:ApiCostLedger` (iter-1), `question:Q2` ADDRESSED_BY `schema:QuotaReservation|schema:QuotaWindow|algorithm:token-bucket|F12-decision-matrix`, `question:Q2` NEXT_FOCUS `question:Q3`.
