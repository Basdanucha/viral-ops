# Iteration 3: Q3 — Revenue Attribution

## Focus
Design revenue ingestion and per-content attribution for all revenue streams relevant to viral-ops: (A) affiliate programs (Amazon Associates [Creators API 2026], Shopee Affiliate TH, TikTok Shop Affiliate, CJ Affiliate, Impact.com, ShareASale, LinkTree aggregators), (B) platform monetization (YouTube Partner Program, TikTok Creator Rewards 2026, IG/FB bonus replacements), (C) multi-touch attribution models for cross-posted content (one `contentId` on 4 platforms), (D) `RevenueLedger` + `RevenueAttribution` Prisma models with SCD-style confidence states (expected → pending → confirmed → reversed) to handle 30-90 day reconciliation lag, and (E) a reconciliation workflow that makes the `ROI = Revenue / ContentCostRollup` join deterministic despite variable cost/revenue timing.

## Actions Taken
1. WebFetch `developers.google.com/youtube/analytics/revenue_reports` — confirmed metric names (`estimatedRevenue`, `estimatedAdRevenue`, `estimated_partner_revenue`, `cpm`, `playbackBasedCpm`, `monetizedPlaybacks`) + both APIs (Analytics API real-time query vs Reporting API bulk CSV).
2. WebFetch `webservices.amazon.com/paapi5/documentation/` — **CRITICAL DISCOVERY**: PA-API deprecates **2026-04-30** (13 days from today 2026-04-17). Migrate to **Creators API** at `affiliate-program.amazon.com/creatorsapi/docs/`.
3. WebFetch 3× TikTok official support URLs (developers.tiktok.com, newsroom, support.tiktok.com) — all either 404 or content-mismatched. Creator Rewards Program has **no public earnings API**, per multiple 2026 industry sources.
4. WebSearch for `TikTok Creator Rewards Program 2026 API` + `Amazon Creators API 2026 endpoints` + `Impact.com Partner API Actions` + `YouTube yt-analytics-monetary.readonly` + `multi-touch attribution 2026` + `Instagram Reels Play Bonus discontinued Meta 2026` — got authoritative industry summaries where vendor docs were blocked.
5. WebFetch `integrations.impact.com/default.htm` (301→integrations.impact.com) — confirmed portal exists but lacks docs at root; search returned specific endpoints (`/impact-publisher/reference/rate-limits`, `/impact-publisher/reference/authentication`, `subId1` docs).

## Findings

### F17 — Platform monetization 2026 state matrix (authoritative)

The TikTok/IG landscape has been **massively reshaped** since 2023. viral-ops cannot treat platform monetization as a uniform source; the spread of API/no-API + invite-only schemes dictates a heterogeneous ingestion strategy.

| Platform | 2026 Monetization Program | Replaced What? | Public Earnings API? | Reporting Cadence | Attribution Granularity |
|----------|---------------------------|----------------|----------------------|-------------------|-------------------------|
| **YouTube** | YouTube Partner Program (YPP) | n/a (stable since 2007) | **YES** — YouTube Analytics API + Reporting API | Real-time query (Analytics API) + daily bulk CSV (Reporting API); revenue finalizes at ~D+2 to D+7, fully settled at month-end | Per-video, per-country, per-device, per-day |
| **TikTok** | Creator Rewards Program (CRP) | Replaced Creator Fund (deprecated 2023) + Creativity Program Beta (2024) | **NO public API**. Creator must read dashboard manually or use scraping (terms-risky) | Daily in-app dashboard; monthly payouts | Per-video but **manually exported only** |
| **Instagram** | Seasonal **invite-only** bonuses (Spring 2024, New Year 2024, etc.) + Subscriptions + Branded Content + Instagram Gifts | Reels Play Bonus discontinued **2023-03** globally | **NO** — invite-only, no API | Ad hoc per-campaign; Meta email invitation | Per-creator (not per-reel) |
| **Facebook** | Facebook Reels Performance Bonus (Pages-only, invite-only) + Ad Breaks (in-stream ads for long-form) | Reels Play Bonus discontinued **2023-03** globally | **Partial** — Meta Creator Studio / Ads Manager (Graph API Insights for ad-break revenue only); bonus payouts are manual | Daily (ad-break) / weekly (bonus invites) | Per-video for ad-break |

**Sources** (all captured 2026-04-17):
- [SOURCE: https://developers.google.com/youtube/analytics/revenue_reports]
- [SOURCE: https://help.instagram.com/543274486958120/ + https://techcrunch.com/2023/03/10/meta-will-stop-offering-reels-bonuses-to-creators-on-facebook-and-instagram/]
- [SOURCE: https://multilogin.com/blog/mobile/tiktok-creator-rewards-program/ — 2026 industry survey]
- [SOURCE: https://affinco.com/tiktok-creator-rewards-program/ — 2026 complete guide]
- [SOURCE: https://www.tubefilter.com/2024/04/05/instagram-spring-bonus-creator-monetization/]

**TikTok Creator Rewards Program 2026 specifics** (industry-confirmed):
- Eligibility: **18+ yr old**, **≥10,000 followers**, **≥100,000 views in last 30 days**, personal account in good standing, country in allowed list (US, UK, DE, JP, KR, FR, BR). Thailand NOT in that list as of 2026-04.
- Video requirements: **≥1 minute duration**, original content, follows community guidelines.
- RPM: **$0.40-$1.50 per 1,000 qualified views** for US-audience content; outliers from $0.20 to $2.00+; depends on (a) originality, (b) play duration, (c) audience geography, (d) content niche.
- **"Qualified views" ≠ total views**: only views meeting TikTok's duration + originality thresholds count — the ratio can be 30-60% of total views.
- **No programmatic earnings API** as of 2026-04. viral-ops must either (i) ingest via manual CSV export uploaded by the creator, (ii) screen-scrape the dashboard (violates ToS), or (iii) accept that TikTok revenue attribution is **manually reconciled at month-end**.

**Thailand-specific implication**: TikTok Creator Rewards Program is **not available in Thailand**. Thai-creator revenue from TikTok in 2026 comes exclusively from (a) TikTok Shop Affiliate (commerce-mediated), (b) Creator Marketplace brand deals (manual invoice-based), (c) LIVE Gifts. This changes the `RevenueLedger` source-discriminator design — TikTok-TH content only ever generates affiliate/brand revenue, never ad-share.

### F18 — Affiliate program API matrix (2026-04-17)

| Program | 2026 API Status | Attribution Window | SubID Support | Rate Limit | Payout Lag |
|---------|-----------------|---------------------|----------------|------------|-------------|
| **Amazon Associates** | **Migration required**: PA-API deprecates **2026-04-30** → **Creators API** is the new canonical. Offers V1 retired 2026-01-31, Offers V2 requires Creators API by 2026-01-30. S3 proxy reports **deprecated in 2026** (no backup) | 24h cookie (standard); 90-day Add-to-Cart; 24h standard for mobile app opens | **Limited**: `ascsubtag` (SubID) rarely returned in conversion data — click→session→conversion attribution is broken for most publishers | Not publicly specified for Creators API in search results | ~60-day hold (locked period) + monthly payout |
| **Shopee Affiliate (TH)** | Dashboard-only; CSV export manual; **no public REST API** for programmatic earnings ingestion as of 2026-04 | 7-day cookie (Shopee TH standard) | Tracking-URL-based SubID (`?af_sub_id=`) | N/A | ~30-45 days from order confirmation |
| **TikTok Shop Affiliate** | In-app Creator Center dashboard + daily CSV export; **no public REST API for creator earnings** | Per-post (in-video click attribution, 7-day standard for TikTok Shop TH) | Creator-ID-based; no manual SubID injection needed (TikTok does the mapping) | N/A | Monthly, on a 30-day delay |
| **CJ Affiliate** | **GraphQL API** (Personal Access Token) at `developers.cj.com/graphql`; Commission Detail query provides per-action data | 7-45 day cookie (advertiser-set) | **`SID` (shopper ID)** — 128 char, set by publisher on click, returned in commission query | ~500 req/hour per token (inferred; not in current docs but typical) | Action states: **Locked → Extended → Closed → Corrected** (30-90 day cycle) |
| **Impact.com** | **REST API** at `integrations.impact.com/impact-publisher/`. Auth via Account SID + Auth Token (HTTP Basic) or scoped tokens. `Actions` endpoint returns conversion events | 30-day cookie (brand-set, ranges 1-90 days) | **`subId1`-`subId5`** — up to 5 subIDs per click, returned on Action | Hourly cap (429 response + rate-limit headers) — not numbered in public docs | Real-time Actions (pending), Locked at 30d, Paid monthly |
| **ShareASale** | REST API (`api.shareasale.com/x.cfm?...`) with MD5 auth-signature — mature stable API | 30-90 day cookie | **`afftrack`** — arbitrary publisher string, returned in commission reports | ~1 req/sec per affiliate ID (soft cap) | ~30 day lock + net-20 payout |
| **LinkTree / Beacons / Koji** | Analytics only (clicks), **not revenue attribution** — revenue is downstream on the linked destination's affiliate program | N/A — pure redirect | n/a | N/A | N/A |

**Critical conclusion**: There is **no uniform "affiliate API"**. Each program needs its own ingestion adapter. The common shape is:
- Click-side: UTM + SubID injection per-content at posting time
- Conversion-side: program-specific API pull (REST/GraphQL) or CSV upload
- Reconciliation: program-specific state machine (locked/extended/closed/reversed)

**Sources** (captured 2026-04-17):
- [SOURCE: https://developer.amazon.com/docs/reports-promo/reporting-API.html + https://logie.ai/news/amazons-2026-creator-api-guide/]
- [SOURCE: https://webservices.amazon.com/paapi5/documentation/ (PA-API deprecation notice)]
- [SOURCE: https://integrations.impact.com/impact-publisher/reference/rate-limits + .../authentication]
- [SOURCE: https://wecantrack.com/amazon-integration/ — SubID limitation writeup]

### F19 — Multi-touch attribution model choice for cross-platform reposts

When a single `contentId` in viral-ops is posted to TikTok + IG Reels + YouTube Shorts + FB Reels (standard repost pattern from spec 006-content-lab), revenue can arrive from:
- **Platform ads** on any/all of the 4 platforms (YouTube only has API; TikTok manual CSV; IG/FB bonus-dependent)
- **Affiliate clicks** that originate from ANY platform but convert on the merchant site hours-to-days later
- **TikTok Shop / Instagram Shopping** in-app conversions

**Attribution model tradeoffs:**

| Model | Formula | Pros | Cons | Best fit for |
|-------|---------|------|------|--------------|
| **First-touch** | 100% credit to first platform that surfaced the content | Simple; rewards discovery-stage platforms (TikTok) | Ignores platforms that drove conversion; over-credits TikTok | Top-of-funnel attribution, niche discovery metrics |
| **Last-touch** | 100% credit to final platform before conversion | Simple; reflects the platform that closed the sale | Ignores brand-building on earlier platforms; over-credits YouTube (which typically sees repeat views) | Direct-response campaigns, bottom-funnel optimization |
| **Linear** | Equal credit across all N platforms content was posted to | Fair; easy to explain | Wrong when one platform dominates reach (e.g., 90% of views on TikTok, 5% on each of IG/YT/FB) | Brand-awareness campaigns with balanced reach |
| **Time-decay** | Credit = `e^(-λ × hours_before_conversion)`, weighted by platform view-time within that window | Rewards recency; matches consumer behavior for fast-cycle Thai content (24-48h lifecycle per 005-trend) | Requires per-view timestamp data; expensive to compute | **CHOSEN DEFAULT for viral-ops** — matches the 24-48h Thai trend lifecycle from spec 005 |
| **Position-based (U-shaped)** | 40% first, 40% last, 20% middle | Balances discovery + conversion | Arbitrary 40/40/20 split; poor fit for 4-platform repost | B2B long-cycle content, not viral-ops |
| **View-weighted linear** | Credit weight per platform = `platform_views / total_views_across_platforms` | Proportional to reach; simple to compute | Doesn't capture platform-level conversion rate differences | **CHOSEN FALLBACK** when time-decay lacks timestamp data |

**Viral-ops policy (decision):**
- **Default: time-decay with λ=0.05/hour** → after 24h, earliest-platform weight decays to `e^(-1.2) ≈ 0.30` (30% of initial). Aligns with 24-48h Thai trend half-life from spec 005.
- **Fallback: view-weighted linear** when per-view timestamps unavailable (older data, bulk CSV imports).
- **Affiliate-specific override**: when a conversion arrives via UTM/SubID that deterministically maps to one platform, use **100% last-touch to that platform** regardless of default (because the UTM is the ground truth).
- **Platform-ad revenue** (YouTube AdSense) gets 100% credit to the platform that earned it (no cross-platform attribution — ad revenue is platform-local).

**The math for storage**: store raw revenue events with platform of origin + estimated touchpoint sequence, then apply attribution at query time (not at insert time). This lets us change the attribution model per-dashboard without backfilling.

[SOURCE: https://improvado.io/blog/multi-touch-attribution — 2026 industry guide]
[SOURCE: https://linkutm.com/blog/what-is-multi-touch-attribution — model-by-model comparison]
[SOURCE: https://trueprofit.io/blog/multi-touch-attribution — 2026 MTA guide]

### F20 — `RevenueLedger` + `RevenueAttribution` Prisma models

**Design principles:**
1. Mirror `ApiCostLedger` shape (iter-1, append-only, correlationId, JSON raw blob) so ROI is a simple join on `contentId`.
2. Separate **revenue events** (raw, source-of-truth) from **attribution allocations** (derived, recomputable). This is the same split as `ApiCostLedger` → `ContentCostRollup`.
3. Support **SCD-style status transitions**: `expected → pending → confirmed → reversed`. Never mutate past rows — emit new status-update rows.
4. Support **confidence score** per event (0.0-1.0): high for platform-ad API pulls with verified payout, low for affiliate "estimated commission" before lock period ends.
5. **Currency**: always store in `amountUsd` (canonical) + `amountNative` + `fxRate` + `fxRateAsOf` — affiliate programs pay in local (Shopee TH in THB, etc.).

```prisma
model RevenueLedger {
  id                    String   @id @default(cuid())
  createdAt             DateTime @default(now())
  // Source identity
  source                String   @index // 'youtube_ads' | 'tiktok_crp' | 'amazon_associates' | 'shopee_th' | 'tiktok_shop' | 'cj_affiliate' | 'impact' | 'shareasale' | 'ig_bonus' | 'fb_reels_bonus' | 'fb_ad_break' | 'brand_deal'
  sourceSubtype         String?           // e.g. 'youtube_partner_ads', 'youtube_premium', 'youtube_shorts_fund'
  externalId            String   @index   // upstream transaction/action ID — unique per source to dedupe
  // Amount
  amountNative          Decimal  @db.Decimal(14, 4) // as reported by source
  nativeCurrency        String            // 'USD' | 'THB' | 'EUR' | ...
  amountUsd             Decimal  @db.Decimal(14, 4)
  fxRate                Decimal  @db.Decimal(12, 6) // THB→USD rate applied
  fxRateAsOf            DateTime // when the FX rate was snapshotted
  // State machine (SCD-style)
  status                String   @default("expected") // 'expected' | 'pending' | 'confirmed' | 'reversed' | 'extended' | 'locked' | 'closed'
  confidence            Decimal  @db.Decimal(5, 4)    // 0.0000-1.0000 — 1.0 for confirmed, 0.3 for expected-affiliate, 0.0 for reversed
  reversalReason        String?                       // 'chargeback' | 'refund' | 'fraud' | 'adjustment'
  predecessorId         String?  @index               // FK to prior RevenueLedger row when this row supersedes it (amount change / status update)
  // Temporal
  earnedAt              DateTime @index  // when the underlying event happened (view, click, purchase)
  confirmedAt           DateTime?        // when status moved to 'confirmed'
  payoutExpectedAt      DateTime?        // projected settlement date
  // Attribution inputs (source-side metadata — used by attribution engine)
  platform              String?  @index  // 'youtube' | 'tiktok' | 'instagram' | 'facebook' | NULL for merchant-side
  platformVideoId       String?  @index  // platform's own ID (for platform-ad revenue, 1:1 with content)
  subId                 String?  @index  // UTM/SubID we injected — resolves to contentId via SubIdMapping
  rawPayload            Json              // full vendor response, for audit
  // Indexes
  @@index([source, earnedAt])
  @@index([externalId, source])
  @@index([status, confidence])
  @@index([platform, platformVideoId])
  @@index([subId])
}

model SubIdMapping {
  id             String   @id @default(cuid())
  subId          String   @unique           // opaque ID we inject; e.g. 'vo-c8f3e2-tk' = viral-ops, contentId prefix c8f3e2, tiktok
  contentId      String   @index
  platform       String   @index            // where the SubID was posted
  postedAt       DateTime
  programId      String                     // 'amazon_us' | 'shopee_th' | 'impact_advertiser_12345' — affiliate program
  createdAt      DateTime @default(now())
  @@index([contentId, platform])
}

model RevenueAttribution {
  id                String   @id @default(cuid())
  revenueLedgerId   String   @index // FK to RevenueLedger row being attributed
  contentId         String   @index
  platform          String            // where the attributed touchpoint occurred
  attributionModel  String            // 'time_decay_lambda_0.05' | 'view_weighted_linear' | 'deterministic_utm' | 'platform_local'
  weight            Decimal  @db.Decimal(7, 6) // 0.000000-1.000000 — sum of all rows for a given revenueLedgerId == 1.0 (invariant)
  attributedAmountUsd Decimal @db.Decimal(14, 4) // amountUsd × weight
  computedAt        DateTime @default(now())
  modelVersion      String            // 'v1.0.0' — allows re-computation with new model
  @@unique([revenueLedgerId, contentId, platform, attributionModel, modelVersion])
  @@index([contentId, attributionModel])
}

model AttributionModelConfig {
  id              String   @id @default(cuid())
  modelName       String   @unique // 'time_decay_lambda_0.05'
  modelType       String            // 'time_decay' | 'linear' | 'first_touch' | 'last_touch' | 'view_weighted' | 'position_based'
  parameters      Json              // {"lambda": 0.05, "halfLifeHours": 24}
  effectiveFrom   DateTime
  isDefault       Boolean  @default(false)
  createdAt       DateTime @default(now())
}
```

**Companion: extend iter-1 `ContentCostRollup` with `RevenueRollup`** (event-sourced from `RevenueAttribution`):

```prisma
model ContentRevenueRollup {
  contentId            String   @id
  // Mirror ContentCostRollup timestamps
  firstRevenueAt       DateTime?
  lastRevenueAt        DateTime?
  // Confirmed (confidence ≥ 0.95) amounts per attribution model
  confirmedAmountUsd_timeDecay       Decimal @default(0) @db.Decimal(14, 4)
  confirmedAmountUsd_lastTouch       Decimal @default(0) @db.Decimal(14, 4)
  confirmedAmountUsd_firstTouch      Decimal @default(0) @db.Decimal(14, 4)
  confirmedAmountUsd_linear          Decimal @default(0) @db.Decimal(14, 4)
  confirmedAmountUsd_viewWeighted    Decimal @default(0) @db.Decimal(14, 4)
  // Expected (confidence < 0.95) — pipeline-to-be-confirmed
  expectedAmountUsd_timeDecay        Decimal @default(0) @db.Decimal(14, 4)
  // Per-source breakdown (independent of model)
  revenueUsd_youtube_ads             Decimal @default(0) @db.Decimal(14, 4)
  revenueUsd_tiktok_shop             Decimal @default(0) @db.Decimal(14, 4)
  revenueUsd_amazon_associates       Decimal @default(0) @db.Decimal(14, 4)
  revenueUsd_impact                  Decimal @default(0) @db.Decimal(14, 4)
  // ... one column per source for fast dashboard query
  ledgerEventCount     Int     @default(0)
  lastRollupAt         DateTime @updatedAt
}
```

**ROI calculation** (now a clean join in the view layer):

```sql
SELECT
  c.contentId,
  COALESCE(r.confirmedAmountUsd_timeDecay, 0) AS confirmed_revenue_usd,
  COALESCE(r.expectedAmountUsd_timeDecay, 0) AS expected_revenue_usd,
  c.totalCostUsd AS total_cost_usd, -- from iter-1 ContentCostRollup
  (COALESCE(r.confirmedAmountUsd_timeDecay, 0) - c.totalCostUsd) AS net_profit_confirmed_usd,
  CASE WHEN c.totalCostUsd > 0
       THEN (COALESCE(r.confirmedAmountUsd_timeDecay, 0) / c.totalCostUsd)
       ELSE NULL END AS roi_ratio_confirmed
FROM ContentCostRollup c
LEFT JOIN ContentRevenueRollup r ON r.contentId = c.contentId;
```

The **attribution model** (timeDecay vs lastTouch etc.) is switchable at query time by changing the column selected — all 5 pre-computed columns live side-by-side.

### F21 — Reconciliation flow: `expected → pending → confirmed → reversed`

Affiliate commission reconciliation is the hardest part of revenue tracking. Using CJ Affiliate's canonical state machine (Locked → Extended → Closed → Corrected) as template, viral-ops uses a 5-state machine with explicit confidence thresholds.

| State | Confidence | When | Who emits | ROI treatment |
|-------|------------|------|-----------|----------------|
| `expected` | 0.20-0.40 | Click detected + UTM/SubID resolved to contentId, but no conversion yet | n/a — derived from `SubIdMapping` click events | Excluded from ROI; shown as "projected" badge in dashboard only |
| `pending` | 0.50-0.80 | Affiliate API returns a commission with state "locked" (CJ) or "pending" (Impact/Shopee) | Affiliate-specific n8n ingester | Included in **expected** ROI column |
| `confirmed` | 0.95-1.00 | Commission state moves to "closed" (CJ) or "paid" (Impact); YouTube payout cleared | Affiliate-specific n8n ingester OR platform payout settlement | Included in **confirmed** ROI column |
| `extended` | 0.60 | CJ-specific: advertiser requests extra review window (rare, typically +30-60 days) | CJ ingester | Stays in **expected** ROI column but tagged with longer expected-payout date |
| `reversed` | 0.00 | Chargeback, refund, fraud detection, or corrected downward | Affiliate-specific n8n ingester | Subtracted from **confirmed**; new row with `amountUsd < 0` linked via `predecessorId` |

**n8n reconciliation workflow blueprint** (runs nightly per source):

```
┌──────────────────────────────────────────────────────────────────────┐
│ n8n WORKFLOW: reconcile-impact-revenue (cron: 0 3 * * *, daily 03:00)│
├──────────────────────────────────────────────────────────────────────┤
│ 1. GET /impact-publisher/actions?since={last_run_timestamp}          │
│    Returns: actions[] with {id, state, subId1, amount, currency}     │
│ 2. For each action:                                                  │
│    a. Lookup RevenueLedger by externalId == action.id                │
│    b. If new: INSERT RevenueLedger {status='pending', conf=0.5}      │
│    c. If exists and state changed: INSERT new row with               │
│       predecessorId = existing row's id, updated status + conf       │
│ 3. Apply FX: THB→USD using daily ECB snapshot (store fxRateAsOf)     │
│ 4. Emit RevenueAttribution rows for all active models:               │
│    - Lookup SubIdMapping to get contentId + platform                 │
│    - If subId deterministically maps one contentId → 1.0 weight on   │
│      that contentId (deterministic_utm model)                        │
│    - Otherwise compute time_decay + view_weighted weights from       │
│      per-platform view timestamps (pulled from spec 007 BUC data)    │
│ 5. Update ContentRevenueRollup sums for affected contentIds          │
│ 6. Emit alerts for: reversals > $10, confidence drops > 20% row-over │
│    -row, stuck-in-pending > 60 days                                  │
└──────────────────────────────────────────────────────────────────────┘
```

**Key invariants:**
- Every `RevenueLedger` row is immutable after insert. State transitions always emit NEW rows with `predecessorId` linking to the superseded row.
- For a given `externalId`, only the row with MAX(`createdAt`) AND `predecessorId IS NOT referenced by another row` is "active". Dashboard queries filter WHERE NOT EXISTS (predecessor chain).
- `RevenueAttribution` rows are REGENERATED on any upstream change via a DELETE-and-reinsert inside a transaction, keyed by `(revenueLedgerId, contentId, platform, attributionModel, modelVersion)`.

**Cross-platform TikTok-TH special-case** (Thailand blocker from F17):
Because TikTok CRP isn't available in Thailand, the `reconcile-tiktok` job only needs to handle:
- `tiktok_shop` source: pulled via TikTok Seller Center CSV export (manual upload) OR vendor-side reconciliation (merchant pays us, reported through TikTok Shop API if we're the merchant).
- `brand_deal`: manual invoice entry, `externalId = contract_id`, `confidence = 1.0` immediately on signed contract.
- NO ad-share revenue row ever appears for TikTok-TH.

### F22 — SubID + short-link strategy (click-side tracking)

For multi-touch attribution to work, every piece of content must inject a per-content, per-platform-destination tracker into any affiliate link it contains.

**URL pattern:**
```
https://vo.link/{short_code}
→ redirects to
https://affiliate-program-URL?subId1=vo-{contentId6}-{platform2}&utm_source=viral-ops&utm_medium={platform}&utm_campaign=c_{contentId6}
```

Where:
- `vo.link/{short_code}` is our own short-link service (Prisma-backed: `ShortLink{code, target, contentId, platform, createdAt, clickCount}`)
- `{contentId6}` = first 6 chars of cuid (collision risk ~1/1M at 1M content pieces — acceptable; fallback uses full cuid when namespace saturated)
- `{platform2}` = 2-char code: `tk`=TikTok, `ig`=Instagram, `yt`=YouTube, `fb`=Facebook
- `subId1` syntax varies per program (Impact uses `subId1`, CJ uses `SID`, Amazon uses `ascsubtag`, Shopee uses `af_sub_id`) — the short-link rewrites to each program's native param at redirect time.

**Why self-hosted short link (not bit.ly / TinyURL)?**
1. Analytics ownership — click logs stored in our DB, not third-party.
2. Programmatic URL rewriting at redirect — can inject platform-specific subId format.
3. Bypass TikTok/IG link-in-bio restrictions (our `vo.link` domain is consistent).
4. Cost: single Postgres row + tiny Next.js route — effectively free at viral-ops scale.

**Cookie / attribution windows** (aligned with each program's default):
- Amazon: 24h standard, 90d Add-to-Cart
- Shopee TH: 7d
- TikTok Shop: 7d (in-app session)
- Impact: brand-configured 1-90d (default 30d)
- CJ: advertiser-set 7-45d
- ShareASale: advertiser-set 30-90d
- YouTube ads: N/A (platform-local, no cross-domain cookie)

**Short-link schema:**
```prisma
model ShortLink {
  code         String   @id           // short 6-8 char identifier
  targetUrl    String                 // destination affiliate URL
  contentId    String   @index
  platform     String                 // posted-on platform
  programId    String                 // affiliate program identifier
  subIdValue   String                 // opaque tracker we'll inject (FK to SubIdMapping.subId)
  clickCount   Int      @default(0)   // updated atomically on each click
  firstClickAt DateTime?
  lastClickAt  DateTime?
  createdAt    DateTime @default(now())
  @@index([contentId, platform])
}

model ShortLinkClick {
  id           String   @id @default(cuid())
  code         String   @index         // FK to ShortLink
  clickedAt    DateTime @default(now())
  ipHash       String                  // SHA-256 of IP — for fraud-screening, not identity
  userAgent    String
  referrer     String?                 // referring URL (indicates which platform's in-app browser)
  country      String?                 // derived from IP at click time
  @@index([code, clickedAt])
}
```

Click events feed `SubIdMapping` (proof we sent traffic to the program) so when `RevenueLedger` arrives with matching `subId`, the attribution is deterministic.

### F23 — Currency & FX handling for Thai-focused ops

All revenue stored in `amountUsd` (canonical) but affiliate programs pay in various currencies:
- **Shopee Affiliate TH** → THB
- **TikTok Shop TH brand deals** → THB or USD (brand-dependent)
- **Amazon Associates** → USD (for .com) or destination-market currency (for country variants — .co.uk=GBP, .de=EUR, .co.jp=JPY)
- **CJ Affiliate** → USD (default) or advertiser-currency configurable
- **Impact.com** → USD (default)
- **YouTube Partner Program** → USD (AdSense payout), converted from local ad spend at Google's internal FX
- **Facebook Ad Break** → payout-market currency

**Policy:**
1. Record `amountNative` + `nativeCurrency` as-reported.
2. Apply FX at `earnedAt` date using **daily ECB or Bank of Thailand reference rate snapshot** — store in `fxRate` + `fxRateAsOf` for audit.
3. Display dashboard in THB OR USD based on user preference, computing via the stored USD value + live FX (for display only).
4. No re-FX on state transitions (confirmed/reversed) — keep the original `earnedAt` snapshot.
5. Reversals store negative `amountUsd` computed at ORIGINAL FX rate (not reversal-date FX) — this keeps the sum invariant: `sum(confirmed.amountUsd) = net_revenue_in_usd_at_earned_dates`.

**n8n `daily-fx-snapshot` workflow:** pulls ECB + BOT reference rates once daily at 00:05 UTC, writes to `FxSnapshot` table; all revenue ingestion within next 24h reads from this table.

### F24 — End-to-end cost → revenue → ROI flow (cross-reference iter-1 + iter-2)

```
┌────────────────────────────────────────────────────────────────────────────┐
│                    VIRAL-OPS COST + REVENUE + ROI LIFECYCLE               │
├────────────────────────────────────────────────────────────────────────────┤
│ T=0d   : L3 script generation                                              │
│          → ApiCostLedger {prov=anthropic, stage=L3, cost=$0.015} (iter-1) │
│          → QuotaReservation (iter-2) consumed + refunded                   │
│ T=0d+1h: L4 TTS generation                                                 │
│          → ApiCostLedger {prov=elevenlabs, stage=L4, cost=$0.03} (iter-1) │
│ T=0d+2h: L5 edit + L6 upload to TikTok/IG/YT/FB                            │
│          → ApiCostLedger {prov=internal, stage=L5, cost=$0.01} (iter-1)   │
│          → SubIdMapping row created per-platform                           │
│          → ShortLink rows created (one per platform, pointing to our own  │
│             short-link service)                                            │
│ T=0d+3h: ContentCostRollup emitted (iter-1 — sum of all L*): $0.055       │
├────────────────────────────────────────────────────────────────────────────┤
│ T=0d+6h to T=7d: Clicks accumulate                                         │
│          → ShortLinkClick rows; atomic increment of ShortLink.clickCount  │
│          → Derived "expected" revenue projections (optional, low confidence│
├────────────────────────────────────────────────────────────────────────────┤
│ T=1d to T=30d: Platform ad revenue (YouTube only for viral-ops Thai)       │
│          → n8n youtube-ingest workflow (daily)                             │
│          → RevenueLedger {source=youtube_ads, conf=0.8, status=pending}   │
│          → RevenueAttribution inserts (platform_local, weight=1.0)         │
├────────────────────────────────────────────────────────────────────────────┤
│ T=2d to T=14d: Affiliate click-to-conversion                               │
│          → Shopee / Impact / CJ / Amazon ingest workflows                  │
│          → RevenueLedger {source=*, conf=0.5, status=pending}             │
│          → RevenueAttribution emitted:                                     │
│             • deterministic_utm model: weight=1.0 on matched contentId    │
│             • time_decay model: weights split across platforms by recency │
├────────────────────────────────────────────────────────────────────────────┤
│ T=30d to T=90d: Reconciliation                                             │
│          → Commissions move to locked → confirmed; new RevenueLedger rows │
│            with predecessorId chain                                       │
│          → Reversals emit negative-amount rows                             │
│          → ContentRevenueRollup recomputed per affected contentId         │
├────────────────────────────────────────────────────────────────────────────┤
│ T=30d+ : ROI view ready for dashboard                                      │
│          → JOIN ContentCostRollup c ON ContentRevenueRollup r ON contentId│
│          → SELECT 5 attribution models side-by-side                        │
│          → shadcn/ui chart: ROI distribution per niche + per-platform     │
└────────────────────────────────────────────────────────────────────────────┘
```

**Bounding the state explosion:** with N content × M revenue sources × K status transitions × L attribution models, raw row count grows O(N·M·K) for Ledger + O(N·L) per contentId for Attribution. At viral-ops scale (est. 1000 content pieces over 12 months × 5 sources × 3 status transitions × 5 models) = 15,000 Ledger rows + 25,000 Attribution rows. Trivial for Postgres; fits easily on a small instance.

## Ruled Out

- **Direct TikTok Creator Rewards earnings API** — **does not exist** in 2026-04. Industry sources (3 separate 2026 guides) confirm creators can only access earnings via in-app dashboard. viral-ops must accept manual CSV upload OR re-author via screen-scrape-with-ToS-risk. Deterministic API ingestion is impossible.
- **Direct Instagram Reels Play Bonus API** — program **discontinued globally 2023-03**. Current IG bonuses are invite-only seasonal programs with no API. Revenue from IG in 2026 for viral-ops is limited to Subscriptions + Branded Content + Instagram Gifts + affiliate-originated clicks.
- **PA-API (Amazon Product Advertising) for new integrations** — **deprecates 2026-04-30 (in 13 days)**. Any new viral-ops Amazon integration must start on **Creators API**. PA-API dev work is wasted effort past 2026-04-30.
- **S3-proxy based Amazon reports** — **deprecated in 2026**. Any script that pulls Amazon commission CSVs from S3 will break. Creators API is canonical replacement.
- **Real-time revenue attribution** — the 30-90 day affiliate reconciliation lag makes real-time attribution structurally impossible. Viral-ops accepts "expected" (low-confidence) projections in dashboard but only counts "confirmed" in ROI alerts.
- **Storing a single "attributedContentId" on each RevenueLedger row** — rejected; multi-touch attribution needs N:M mapping (one revenue row to multiple contentIds with varying weights). The dedicated `RevenueAttribution` table is strictly better.
- **Re-FX'ing reversals at reversal-date** — breaks the sum invariant. Always use `earnedAt` FX rate for the reversal to preserve `sum(confirmed.amountUsd) == net_revenue_at_earned_date`.

## Dead Ends

- **developers.tiktok.com/doc/creator-rewards-program** — 404. No direct TikTok dev doc page exists for Creator Rewards Program earnings API (because the API doesn't exist).
- **tiktok.com/support/faq_detail?id=7581821550694013452** — returned empty content; redirects provide no structured data. TikTok's support pages remain an unreliable source for authoritative API data.
- **Direct impact.com / CJ / Amazon dev portal WebFetch** — all returned portal-only or empty pages. Search-engine summaries of these APIs are more useful than direct WebFetch this session.

## Sources Consulted

- https://developers.google.com/youtube/analytics/revenue_reports (captured 2026-04-17) — revenue metric names + API families.
- https://developers.google.com/youtube/analytics/data_model (captured 2026-04-17) — YouTube Analytics quota baseline.
- https://developers.google.com/youtube/analytics/authorization (403) — monetary scope blocked direct, inferred from Go + .NET SDK docs.
- https://webservices.amazon.com/paapi5/documentation/ (captured 2026-04-17) — PA-API deprecation notice (2026-04-30).
- https://affiliate-program.amazon.com/creatorsapi/docs/en-us/introduction (403) — Creators API direct docs blocked.
- https://developer.amazon.com/docs/reports-promo/reporting-API.html (via search summary) — confirmed estimated-reports caveat.
- https://logie.ai/news/amazons-2026-creator-api-guide/ (via search summary, captured 2026-04-17) — PA-API → Creators API migration details.
- https://wecantrack.com/amazon-integration/ (via search summary) — SubID (ascsubtag) rarely returned by Amazon.
- https://developers.tiktok.com/doc/creator-rewards-program (404) — no API for CRP.
- https://newsroom.tiktok.com/en-us/introducing-creator-rewards-program (content-mismatch).
- https://multilogin.com/blog/mobile/tiktok-creator-rewards-program/ (via search summary, captured 2026-04-17) — 2026 RPM + eligibility data.
- https://affinco.com/tiktok-creator-rewards-program/ (via search summary) — Thailand-exclusion list confirmed.
- https://integrations.impact.com/default.htm (301 portal; 2026-04-17) — endpoint hierarchy.
- https://integrations.impact.com/impact-publisher/reference/rate-limits + .../authentication (via search summary) — Account SID + Auth Token, 429 + rate-limit headers, scoped tokens.
- https://developers.cj.com/graphql/reference (empty content) — GraphQL endpoint confirmed but full schema blocked this iter.
- https://improvado.io/blog/multi-touch-attribution (captured 2026-04-17) — MTA model comparison.
- https://trueprofit.io/blog/multi-touch-attribution (captured 2026-04-17) — 2026 guide.
- https://linkutm.com/blog/what-is-multi-touch-attribution (captured 2026-04-17).
- https://help.instagram.com/543274486958120/ (via search summary) — current IG bonus state.
- https://techcrunch.com/2023/03/10/meta-will-stop-offering-reels-bonuses-to-creators-on-facebook-and-instagram/ (captured 2026-04-17) — Reels Play Bonus 2023-03 discontinuation.
- https://www.tubefilter.com/2024/04/05/instagram-spring-bonus-creator-monetization/ (captured 2026-04-17).
- Prior spec: 008/iterations/iteration-001.md (F7) — ApiCostLedger schema for cross-reference.
- Prior spec: 008/iterations/iteration-002.md (F13, F16) — QuotaReservation + end-to-end flow template.
- Prior spec: 004-platform-upload-deepdive (memory) — platform-upload rate limits.
- Prior spec: 005-trend-viral-brain (memory) — 24-48h Thai trend lifecycle → time-decay λ=0.05/hr.
- Prior spec: 006-content-lab (memory) — 4-platform repost pattern.

## Assessment

- **Findings count:** 8 (F17-F24)
- **Fully new findings:** 7 (F17 platform monetization matrix w/ 2026 state + Thailand exclusion, F18 affiliate API matrix w/ PA-API deadline, F19 multi-touch model choice w/ time-decay default, F20 RevenueLedger + RevenueAttribution schema, F21 5-state reconciliation flow, F22 SubID/short-link strategy, F23 FX/currency handling)
- **Partially new:** 1 × 0.5 = 0.5 (F24 end-to-end flow — stitches together iter-1 + iter-2 + new revenue layer, so composition is new but building blocks are not)
- **Redundant/confirmatory:** 0
- **newInfoRatio = (7 + 0.5) / 8 = 0.9375 ≈ 0.94**

**Simplicity bonus: NOT triggered** — adds new primitives (RevenueLedger, RevenueAttribution, SubIdMapping, ShortLink, AttributionModelConfig, ContentRevenueRollup, FxSnapshot) rather than consolidating.

**Questions addressed:** Q3 primarily (revenue attribution). Q4 secondary — `RevenueAttribution` + `ContentRevenueRollup` is the ROI-engine substrate. Q5 gets groundwork via the dashboard column layout (5 attribution models as pre-computed columns).

**Questions answered:**
- Q3 ≈ **90%** answered: platform matrix locked, affiliate matrix locked, Prisma schema sketched, reconciliation flow sketched, multi-touch defaults chosen. Remaining 10%: (a) empirical RPM backtest data once first content ships, (b) ShareASale/Koji/Beacons specific API pages still not verified by direct WebFetch (industry-summary only).
- Q1 still at ~95%, Q2 at ~90% — unchanged this iteration.

## Reflection

- **What worked and why:** Using **WebSearch as an authoritative source when direct vendor docs are blocked** is now a pattern — both iter-2 (Azure Foundry mirror for OpenAI) and iter-3 (industry guides for TikTok CRP + Meta bonus state) succeeded via secondary-source triangulation. Causal: when a vendor's own docs are anti-bot-walled (Cloudflare 403) or deliberately not-published (TikTok CRP API), cross-referencing 3+ independent 2026-dated industry sources produces usable authoritative data for strategic decisions. This is the "Azure mirror" playbook generalized.
- **What didn't work and why:** Direct WebFetch against any affiliate program dev portal (impact.com, developers.cj.com) returned portal landing pages with near-zero content — these sites use heavy client-side rendering that breaks WebFetch's HTML→markdown conversion. Search-engine summaries had better fidelity because they scraped the actual doc pages. Takeaway: for JS-SPA-heavy dev portals, default to WebSearch, not WebFetch.
- **What I'd do differently next iteration:** iter-4 should focus on Q4 (ROI engine details — how to surface confidence intervals on ROI when expected vs confirmed revenue differ by 30-90 day lag) AND Q5 (dashboard architecture — which shadcn chart primitives, alert pipelines via n8n). iter-5 can back-verify: ElevenLabs rate-limit direct source (iter-2 open), ShareASale / Koji direct API page fetches (iter-3 open), Amazon Creators API endpoint-by-endpoint deep-dive, CJ GraphQL full schema.

## Recommended Next Focus (for Iteration 4)

**Q4 — ROI Engine** is next on critical path. Specifically:
1. Confidence-interval math: given N content × 5 sources × {expected, confirmed} revenue states, compute ROI distributions (mean + 10/50/90 percentile confidence bounds) for dashboard.
2. Time-to-ROI curves: how many days from publish until a contentId crosses break-even in each quantile scenario? Decision trigger: "kill content if break-even hasn't been reached by day 14".
3. Per-niche ROI aggregation: roll ContentRevenueRollup up by niche + by platform + by creator to find high-ROI content patterns (feeds back into spec 005 trend-viral-brain scoring).
4. Handling of "shared" costs that can't be attributed to a single content (base infra, n8n workers always-on) — amortization model: allocate base infra costs proportionally to content count per month.
5. Edge case: late-arriving revenue — a content piece produces 0 confirmed revenue for 60 days, then a single large affiliate conversion comes in on day 61. ROI engine must handle retroactive updates without breaking historical dashboard snapshots.

## Graph Events (for JSONL)

**Nodes:**
- `revenue:youtube-partner-program`, `revenue:tiktok-creator-rewards`, `revenue:instagram-bonuses-invite-only`, `revenue:facebook-reels-bonus-invite-only`, `revenue:facebook-ad-break`
- `revenue:amazon-associates`, `revenue:amazon-creators-api`, `revenue:shopee-affiliate-th`, `revenue:tiktok-shop-affiliate`, `revenue:cj-affiliate`, `revenue:impact-com`, `revenue:shareasale`, `revenue:linktree-beacons-koji`, `revenue:brand-deal`
- `schema:RevenueLedger`, `schema:RevenueAttribution`, `schema:SubIdMapping`, `schema:ShortLink`, `schema:ShortLinkClick`, `schema:AttributionModelConfig`, `schema:ContentRevenueRollup`, `schema:FxSnapshot`
- `attribution:first-touch`, `attribution:last-touch`, `attribution:linear`, `attribution:time-decay-lambda-0.05`, `attribution:view-weighted-linear`, `attribution:position-based-u-shaped`, `attribution:deterministic-utm`
- `state:revenue-expected`, `state:revenue-pending`, `state:revenue-confirmed`, `state:revenue-extended`, `state:revenue-reversed`
- `dead-end:tiktok-crp-no-api`, `dead-end:ig-reels-play-bonus-discontinued`, `deadline:amazon-pa-api-2026-04-30`, `deadline:amazon-offers-v1-2026-01-31`
- `concept:thailand-tiktok-crp-exclusion`

**Edges:**
- `revenue:*` FEEDS `schema:RevenueLedger`
- `schema:RevenueLedger` DRIVES `schema:RevenueAttribution`
- `schema:RevenueAttribution` ROLLS_UP_TO `schema:ContentRevenueRollup`
- `schema:ContentRevenueRollup` JOINS `schema:ContentCostRollup` (iter-1) ON `contentId`
- `attribution:time-decay-lambda-0.05` IS_DEFAULT_FOR `schema:RevenueAttribution`
- `attribution:deterministic-utm` OVERRIDES `attribution:*` WHEN subId_matches
- `schema:SubIdMapping` BRIDGES `schema:ShortLink` AND `schema:RevenueLedger`
- `revenue:tiktok-creator-rewards` BLOCKED_BY `concept:thailand-tiktok-crp-exclusion` FOR thai_content
- `revenue:amazon-associates` MIGRATES_TO `revenue:amazon-creators-api` BY `deadline:amazon-pa-api-2026-04-30`
- `revenue:instagram-bonuses-invite-only` REPLACED `revenue:instagram-reels-play-bonus` VIA `dead-end:ig-reels-play-bonus-discontinued`
- `question:Q3` ADDRESSED_BY `schema:RevenueLedger, schema:RevenueAttribution, attribution:time-decay-lambda-0.05, F17-platform-matrix, F18-affiliate-matrix`
- `question:Q3` NEXT_FOCUS `question:Q4`
- `schema:FxSnapshot` SUPPORTS `schema:RevenueLedger` FOR currency_conversion
- `state:revenue-expected` TRANSITIONS_TO `state:revenue-pending` TRANSITIONS_TO `state:revenue-confirmed` (happy path)
- `state:revenue-confirmed` TRANSITIONS_TO `state:revenue-reversed` VIA chargeback_or_refund
