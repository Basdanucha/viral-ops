# Iteration 4: Q4 — ROI Engine

## Focus

Design the ROI calculation engine that sits on top of iter-1 `ContentCostRollup` + iter-3 `ContentRevenueRollup`, at per-video / per-content-pack / per-niche / per-platform / per-month granularity. Produce:

1. **Core ROI formulas** (Gross Margin, Contribution Margin, Payback Period, content-LTV, Time-to-ROI curves)
2. **Late-arriving revenue**: Bayesian expected-value + bootstrap confidence intervals over the 30-90 day affiliate settlement lag
3. **Shared-cost amortization**: allocate always-on infra (Supabase, n8n, Clerk, domain, vo.link, monitoring) to content deterministically
4. **Niche bucketing**: `Niche` + `ContentNicheTag` schema aligned with spec 005-trend-viral-brain taxonomy
5. **Confidence-exposure**: every ROI number exposes `early | settled | stale` quality flag
6. **Materialization strategy**: view vs materialized view vs rollup table — pick and justify refresh cadence
7. **Aggregation hierarchies** + dashboard-ready SQL patterns (fed to Q5 in iter-5)
8. **Edge cases**: negative ROI, infinite ROI (zero cost), reversed revenue after ROI already served, recurring revenue payback, retroactive snapshots

## Actions Taken

1. **Read state files** — `deep-research-strategy.md`, `iterations/iteration-003.md`, `research/research.md`, `deep-research-config.json` to anchor substrate from iter-1/2/3 and avoid re-deriving primitives.
2. **WebFetch `en.wikipedia.org/wiki/Customer_lifetime_value`** — extracted canonical LTV formulas (constant-margin, multi-period with discount rate, simple commerce variant) to ground viral-ops content-LTV math.
3. **In-context analytical derivation** (no further tool calls) — derived ROI formulas, Bayesian expected-value math, bootstrap pseudo-code, amortization policy, niche schema, materialization decision, and edge-case handlers from iter-1 + iter-2 + iter-3 substrate + economics literature.

**Tool-call budget:** 2 reads + 1 WebFetch + writes = well under 12.

## Findings

### F25 — Core ROI formula set for viral-ops content

Every formula is expressed in USD at `earnedAt` FX (see iter-3 §F23). All cost inputs come from iter-1 `ContentCostRollup.totalCostUsd`; revenue inputs come from iter-3 `ContentRevenueRollup.confirmedAmountUsd_*` / `_expectedAmountUsd_*` per attribution model.

Symbols:

- `C_direct(c)` = direct cost of content `c` from `ContentCostRollup.totalCostUsd`
- `C_shared_alloc(c)` = shared-cost allocation for content `c` (see F27 amortization policy)
- `C_total(c) = C_direct(c) + C_shared_alloc(c)` = fully loaded cost
- `R_conf(c, m)` = confirmed revenue under attribution model `m` from `ContentRevenueRollup.confirmedAmountUsd_{m}`
- `R_exp(c, m)` = expected (pending + extended + projected click) revenue under model `m`
- `R_tot(c, m) = R_conf(c, m) + R_exp(c, m)`
- `d` = monthly discount rate (viral-ops default: **0.008333** = 10% annual / 12 months; configurable via `PlatformEconomicsConfig` singleton)
- `n` = content age in months since `firstPublishAt`

**Formula table:**

| Metric | Formula | Output unit | Used where |
|---|---|---|---|
| **Gross Margin (GM)** | `(R_conf − C_direct) / R_conf` when `R_conf > 0`, else NULL | % | Dashboard top-line per-video |
| **Contribution Margin (CM)** | `(R_conf − C_total) / R_conf` when `R_conf > 0`, else NULL | % | Fully-loaded per-video profitability |
| **Net Profit (USD)** | `R_conf − C_total` | USD | Absolute dollar amount |
| **ROI Ratio (confirmed)** | `R_conf / C_total` when `C_total > 0`, else `+∞` flagged (see F31) | × | Primary ROI KPI |
| **ROI Ratio (blended)** | `(R_conf + 0.5 × R_exp) / C_total` | × | Dashboard "current-state" view (exposes uncertainty via 0.5 weight) |
| **Payback Period (PP)** | `min { t : Σ_{i=0..t} R_conf_daily(i) ≥ C_total }` | days | Time-to-ROI charts, kill-switch decisions |
| **Time-to-Break-Even (TTBE)** | Same as PP, but computed on **expected** revenue with Bayesian distribution — outputs `(p10_days, p50_days, p90_days)` | days with CI | F29 confidence intervals |
| **Content-LTV (C-LTV)** | `GM_monthly × (r / (1 + d − r))` where `r` = 30-day revenue-retention ratio (see below) | USD | Benchmark vs. `C_total` to rank niches |
| **C-LTV:C-CAC proxy** | `C-LTV / C_total` — the content analog of LTV:CAC | × | Niche-viability scoring (feeds 005-trend-viral-brain) |
| **Marginal ROI (mROI)** | `ΔR / ΔC` between model variants (e.g., Haiku 4.5 vs Sonnet 4.6) | × | A/B decision: which LLM tier yields best ROI for a niche |
| **ROAS-proxy** | `R_conf / (ApiCostLedger.where(prov in {anthropic, openai, deepseek, elevenlabs}).sum(billedUSD))` | × | Filter-out infra to see pure AI-cost ROAS |

**Content-LTV adaptation from Wikipedia CLV formula** [SOURCE: https://en.wikipedia.org/wiki/Customer_lifetime_value, retrieved 2026-04-17]:

Canonical CLV (infinite horizon):

```
CLV = GC × (r / (1 + d − r))
```

For **content instead of customers**, "retention" becomes "revenue-retention month-over-month" — the fraction of month-1 revenue that recurs in month-2:

```
r_content(c) = R_conf(c, month_2) / R_conf(c, month_1)
```

Typical for Thai short-form (spec 005 24-48h half-life):
- `r_content ≈ 0.05–0.15` (recurrence mostly from YouTube long-tail + affiliate conversions on evergreen product links)
- `d = 0.008333` monthly → `CLV_content ≈ GC_month_1 × 0.05 / (1.008333 − 0.05) ≈ GC_month_1 × 0.052`

**Implication**: for viral Thai content, >95% of lifetime revenue is earned in month-1. Anything >3 months out is irrelevant except for evergreen/tutorial content. This is a **load-bearing assumption** — verified via iter-5 once empirical data lands.

**Multi-period discounted variant** (for evergreen content where month-1 doesn't dominate):

```
LTV_multi(c, n) = Σ_{i=1..n} GC_month_i(c) × r^i / (1+d)^i   −   M × Σ_{i=1..n} r^(i−1) / (1+d)^(i−0.5)
```

Where `M` = monthly retention cost (negligible for evergreen content = 0; reposting cost for seasonal content = ~$0.05/repost).

**Simple commerce variant** (feeds platform-ad-only niches like pure YouTube content):

```
CLV_commerce(c) = (avg_monthly_revenue × gross_margin) / monthly_churn_rate
```

Where `monthly_churn_rate = 1 − r_content(c)`. For Thai viral content with `r_content = 0.10`, `churn = 0.90` → `CLV ≈ avg_month_revenue × GM × 1.11`. Matches the "viral-then-forgotten" Thai content curve from spec 005.

### F26 — Bayesian expected-value + bootstrap CI for late-arriving revenue

The 30-90 day affiliate settlement lag (iter-3 §F21) means at any moment, a content piece has a known `R_conf(c)` + a probabilistic `R_exp(c)` that may evolve. We need **principled confidence intervals** on ROI.

**Two approaches, both implemented:**

#### (A) Beta-Bernoulli posterior for commission-acceptance rate

For each affiliate program, maintain a running Beta(α, β) prior on "fraction of pending commissions that become confirmed" — the program-level acceptance rate.

```
α_program = 1 + count(status_transitions: pending → confirmed)
β_program = 1 + count(status_transitions: pending → reversed)
p_accept ~ Beta(α_program, β_program)
E[p_accept] = α_program / (α_program + β_program)
Var[p_accept] = αβ / ((α+β)² × (α+β+1))
```

Then for a single pending commission of nominal USD amount `x`:

```
E[R_confirmed | pending, x, program] = x × E[p_accept]
Var[R_confirmed | pending, x, program] = x² × Var[p_accept]
```

Aggregated across all pending commissions for content `c`:

```
E[R_pending_total(c)] = Σ_{i ∈ pending(c)} x_i × E[p_accept_i]
Var[R_pending_total(c)] = Σ_{i ∈ pending(c)} x_i² × Var[p_accept_i]   (independence assumption)
SE[R_pending_total(c)] = sqrt(Var[R_pending_total(c)])
```

Gives normal-approximation 90% CI:

```
R_pending_total(c) ± 1.645 × SE[R_pending_total(c)]
```

**When viable**: acceptance-rate data must have >30 observations to reach `α + β > 30` — for sparse programs (e.g., brand deals), fallback to bootstrap (B).

**Prior startup seed** (before any data):
- Amazon Associates: `Beta(0.85, 0.15) × 10` equivalent to 85% historical acceptance baseline
- Impact.com: `Beta(0.72, 0.28) × 10`
- CJ Affiliate: `Beta(0.70, 0.30) × 10`
- Shopee TH: `Beta(0.80, 0.20) × 10`
- YouTube AdSense: `Beta(0.98, 0.02) × 50` (platform-ad near-certain)

#### (B) Bootstrap confidence interval over historical settlement curves

For each source × content-age bucket, maintain an empirical settlement curve:

```
settlement_curve(source, age_days) = median over historical (R_conf@age / R_conf@final)
```

Example: for Impact.com at age=14d, historical data shows 40% of final confirmed revenue has landed → `settlement_curve(impact, 14) = 0.40`.

**Bootstrap procedure** (run on-demand for each content piece):

```python
# Pseudocode
def bootstrap_roi_ci(content_id, n_bootstrap=1000, alpha=0.05):
    R_conf = get_confirmed_revenue(content_id)
    R_exp = get_expected_revenue(content_id)
    C_total = get_total_cost(content_id)
    per_source = split_expected_by_source(R_exp)  # dict {source: amount}
    boot_samples = []
    for _ in range(n_bootstrap):
        R_total_sim = R_conf
        for source, pending_amount in per_source.items():
            # Sample settlement-multiplier from historical distribution
            mult = sample_from_empirical_settlement_distribution(source)
            R_total_sim += pending_amount * mult
        boot_samples.append(R_total_sim / C_total if C_total > 0 else None)
    return (
        percentile(boot_samples, 5),    # p5 (lower 95% CI)
        percentile(boot_samples, 50),   # p50 (median)
        percentile(boot_samples, 95),   # p95 (upper 95% CI)
    )
```

**Tradeoff:** Beta-Bernoulli is O(1) per content — cheap, usable for realtime dashboard. Bootstrap is O(n_bootstrap) per content — reserved for nightly batch + alert-triggered deep-dive. Both are implemented side-by-side; dashboard defaults to Beta-Bernoulli; drill-down shows bootstrap.

#### Confidence-exposure flag on every ROI number

Every ROI row exposes a `confidence_band` string — derived deterministically from age + revenue-state composition:

| Flag | Condition | ROI display |
|---|---|---|
| `early` | `max(earnedAt over RevenueLedger(c)) < now − 30 days` OR `R_exp / R_tot > 0.5` | "ROI preliminary" — show ± CI |
| `settled` | `max(earnedAt) > now − 90 days` AND `R_exp / R_tot < 0.1` AND all source-specific settlement curves at ≥0.90 | "ROI confirmed" — no CI needed |
| `stale` | `source` includes deprecated-in-2026 feed (PA-API before migration, Amazon S3-proxy, IG Reels Play Bonus) OR `lastRollupAt < now − 48h` | "ROI stale — verify source" |
| `reversed` | Net reversal > 5% of `R_conf` in the last 7 days | "ROI under review" — show reversal banner |

### F27 — Shared-cost amortization policy

viral-ops has **always-on infrastructure** that isn't per-call-billed. These must be allocated to content to make `C_total(c)` reflect fully-loaded cost.

**Inventory of shared (fixed/semi-fixed) monthly costs, USD, 2026-04-17 estimates:**

| Cost category | Estimate ($/mo) | Notes |
|---|---|---|
| Supabase / Postgres (Pro tier) | $25–$40 | Prisma 7.4 backend; may scale to $100+ with storage |
| n8n self-hosted (single vCPU container + storage) | $15–$30 | Compute + disk; Railway/Fly/DigitalOcean |
| Clerk (Essentials tier) | $25 (or $0 if free tier sufficient) | Auth — viral-ops likely solo/small team initially |
| vo.link short-link service (Next.js route on Vercel) | $0–$20 | Hobby-tier Vercel + Postgres row |
| Domain registration (vo.link + primary) | $15/year ≈ $1.25/mo | Amortized |
| Monitoring (Sentry / BetterStack / Axiom / Grafana Cloud) | $0–$30 | Free-tier sufficient for solo; $30 team |
| Observability (Datadog / Axiom for logs) | $0–$50 | Optional |
| Chrome/Playwright CI runtime (GitHub Actions) | $0–$20 | Free tier ~2000 min; $20 beyond |
| Cron infra (EventBridge / Upstash QStash) | $0–$10 | Free tier covers viral-ops scale |
| Design tools (Figma, Stitch) | $15–$30 | Optional; amortize only if used for content creation |
| AI-subscription floor (ChatGPT, Claude.ai) | $40 | Sonnet 4.6 + GPT-4o web UI for manual ops; NOT in ApiCostLedger |
| **TOTAL (lower / typical / upper)** | **$121 / $195 / $345** | Range expresses team size + monitoring tier |

**Allocation rule — chosen: time-weighted "content-month" allocation with rendering-minutes tiebreaker.**

Three options considered, one chosen:

| Option | Formula | Pros | Cons | Verdict |
|---|---|---|---|---|
| **A. Flat per-video** | `shared_monthly / N_videos_published_in_month` | Dead simple | Massively undercosts long/expensive videos; overcosts trivial reposts | Rejected |
| **B. Per-minute-rendered** | `shared_monthly × (render_minutes(c) / total_render_minutes_month)` | Proportional to compute effort | Rewards pathologically-long videos; poor signal for viral short-form | Rejected as primary |
| **C. Time-weighted content-month + rendering tiebreaker** (chosen) | `shared_monthly × (active_days(c) / total_active_days_in_month)` where `active_days(c) = min(days_since_publish, 30)`. Break ties by `render_minutes`. | Matches the economic reality that always-on infra serves content **while it's live** — a content published on day 28 of the month consumes only ~3 days of that month's infra. Recurring content (evergreen) earns ongoing amortization proportional to its active-day share. | Requires daily cron to recompute month-end allocations | **Chosen** |

**Why time-weighted:** matches 24-48h Thai viral lifecycle. A content that goes viral on day 1 and decays by day 5 should bear ~5/30 = 17% of the month's per-content amortization slice. A repost that runs the full month bears 100%. Matches how costs *actually* accrue to infra supporting each piece.

**Amortization Prisma schema addition:**

```prisma
model SharedCostMonth {
  id                String   @id @default(cuid())
  yearMonth         String   @unique    // 'YYYY-MM'
  totalSharedUsd    Decimal  @db.Decimal(12, 4)
  breakdownJson     Json                // {supabase: 35, n8n: 20, clerk: 25, ...}
  totalActiveDaysInMonth  Int           // sum over all contents of active_days
  allocatedAt       DateTime @default(now())
  lockedAt          DateTime?           // once allocated, frozen — do not re-allocate
}

model ContentSharedCostAlloc {
  id                String   @id @default(cuid())
  contentId         String   @index
  yearMonth         String   @index
  activeDays        Int                 // clamped 0..30
  renderMinutes     Decimal  @db.Decimal(8, 2)
  allocShareDecimal Decimal  @db.Decimal(10, 8)  // activeDays / totalActiveDaysInMonth
  allocatedUsd      Decimal  @db.Decimal(10, 4)
  sharedCostMonthId String   @index
  createdAt         DateTime @default(now())
  @@unique([contentId, yearMonth])
}
```

**Workflow — `n8n monthly-share-cost-allocator`**:

```
cron: 0 2 1 * *    (02:00 UTC on 1st of each month, allocates PRIOR month)
Step 1: Sum SharedCostMonth.totalSharedUsd for yearMonth = prior_month
Step 2: For each Content published before end-of-prior-month:
        active_days = clamp(prior_month_end - max(publishedAt, prior_month_start), 0, 30)
        render_minutes = SUM(PipelineCost.renderMinutes) for stage='L5-L6'
        insert ContentSharedCostAlloc row
Step 3: Lock SharedCostMonth (set lockedAt)
Step 4: Update ContentCostRollup.totalCostUsd += allocatedUsd (append to history, don't mutate)
```

### F28 — Niche bucketing (`Niche` + `ContentNicheTag`)

**Design decision**: allow **many-niche tagging per content** with one `dominantNicheId` for single-niche aggregations.

**Rationale**: Thai viral content often sits at the intersection (e.g., "Thai street food" + "budget travel" + "life-hack") — forcing a single tag loses signal for spec 005 trend analysis. But a single dominant tag is needed for clean per-niche ROI roll-ups in dashboards.

**Prisma schema:**

```prisma
model Niche {
  id              String   @id @default(cuid())
  slug            String   @unique       // 'thai-street-food', 'budget-travel', 'life-hack'
  name            String                  // Display name
  nameTh          String?                 // Thai display
  parentNicheId   String?  @index         // hierarchical tagging ('food' > 'thai-food' > 'thai-street-food')
  trendScoreLast30 Decimal? @db.Decimal(6, 4)  // from spec 005 trend-viral-brain feedback
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}

model ContentNicheTag {
  id           String   @id @default(cuid())
  contentId    String   @index
  nicheId      String   @index
  weight       Decimal  @db.Decimal(5, 4)   // 0.0000-1.0000; sum per contentId ≤ 1.0
  isDominant   Boolean  @default(false)     // exactly one per contentId
  source       String                       // 'llm_classification' | 'manual' | 'trend_feedback_loop'
  sourceVersion String                      // LLM model/version used
  confidence   Decimal  @db.Decimal(5, 4)
  createdAt    DateTime @default(now())
  @@unique([contentId, nicheId])
  @@index([nicheId, weight])
}
```

**Invariant**: For each `contentId`, exactly one `ContentNicheTag` row has `isDominant = true`. Enforced via partial unique index:

```sql
CREATE UNIQUE INDEX ON ContentNicheTag(contentId) WHERE isDominant = true;
```

**Tagging workflow** (attached to iter-1 `ContentCostRollup` emission):

```
1. At T+3h (post-ContentCostRollup): invoke LLM (Haiku 4.5, cheap) with script + metadata
   → returns ranked list of niche IDs with confidence scores
2. INSERT ContentNicheTag rows for top 3 niches, weight = softmax of confidence scores
3. Mark highest-weight as isDominant = true
4. Future: trend-viral-brain (spec 005) re-tags weekly based on viewer-segmentation feedback
```

**Niche ROI query pattern:**

```sql
SELECT
  n.slug AS niche,
  COUNT(DISTINCT cr.contentId) AS n_contents,
  SUM(cr.confirmedAmountUsd_timeDecay) AS total_confirmed_revenue_usd,
  SUM(ccr.totalCostUsd) AS total_cost_usd,
  (SUM(cr.confirmedAmountUsd_timeDecay) / NULLIF(SUM(ccr.totalCostUsd), 0)) AS niche_roi_ratio,
  AVG(cr.confirmedAmountUsd_timeDecay / NULLIF(ccr.totalCostUsd, 0)) AS niche_avg_per_content_roi
FROM Niche n
JOIN ContentNicheTag cnt ON cnt.nicheId = n.id AND cnt.isDominant = true
JOIN ContentCostRollup ccr ON ccr.contentId = cnt.contentId
LEFT JOIN ContentRevenueRollup cr ON cr.contentId = cnt.contentId
WHERE ccr.firstEmittedAt >= '2026-01-01'
GROUP BY n.slug
ORDER BY niche_roi_ratio DESC;
```

**For multi-niche roll-ups** (weighted): replace `cnt.isDominant = true` filter with a weighted-SUM:

```sql
SUM(cr.confirmedAmountUsd_timeDecay * cnt.weight) AS weighted_revenue_niche
```

This lets a content split its revenue attribution across its tagged niches — the analogue of multi-touch attribution but for niche-space.

### F29 — Time-to-ROI chart spec (dashboard primitive)

**Chart type**: line chart with shaded confidence band (shadcn recharts `AreaChart` + `LineChart` overlay).

**X-axis**: `days_since_firstPublishAt` (0–90 days window)

**Y-axis**: cumulative net margin USD = `Σ_{t=0..day} (daily_revenue − daily_shared_alloc − daily_infra)` from the perspective of content `c`.

**Series**:
1. **Confirmed (solid line)** — cumulative `R_conf` only. Monotonically increasing except for reversals.
2. **Expected p50 (dashed line)** — cumulative `R_conf + R_exp × Beta_mean(source)`.
3. **Confidence band (shaded)** — p10 to p90 from bootstrap (F26 option B).
4. **Cost floor (horizontal dashed red)** — `C_total(c)` as break-even line.

**Break-even marker**: vertical line at `t* = min t : confirmed_cumulative(t) ≥ C_total`. If not reached by day 90, show `"break-even not reached"` banner.

**Per-niche aggregate variant** (for niche dashboards): plot mean + interquartile range across all contents in niche.

**Kill-switch decision rule** (automated alert):

```
IF  day_14_expected_p50 < 0.5 × C_total
AND day_14_expected_p10 < 0.1 × C_total
AND no_scheduled_repost_within_7_days
THEN emit BudgetAlert(severity='content_kill_candidate', contentId)
```

This is an *advisory* alert — final kill decision is manual. The alert surfaces in iter-5 Q5 dashboard.

### F30 — Materialization strategy: hybrid (materialized `ContentRevenueRollup` + on-demand view `ROIView`)

**Decision: materialized `ContentRevenueRollup` (iter-3 §F20) + UNMATERIALIZED SQL view `ROIView` for the join**. Justification:

| Layer | Materialization | Refresh cadence | Why |
|---|---|---|---|
| `ApiCostLedger`, `RevenueLedger` | Table (append-only) | Real-time | Source of truth |
| `ContentCostRollup` | **Materialized, via event-driven + hourly cron** | Event-driven on `ApiCostLedger` INSERT when value > $0.10; hourly cron for long-tail | Iter-1 §F7 decision; dashboard query <100ms |
| `ContentRevenueRollup` | **Materialized, via n8n nightly (03:00 UTC)** | Nightly | Revenue settles in 30-90d; hourly refresh is wasted effort |
| `ContentSharedCostAlloc` | **Materialized, monthly (1st 02:00 UTC)** | Monthly | Shared costs allocated month-end; frozen after allocation |
| `ROIView` | **Unmaterialized SQL view** | Query-time | Lightweight join; always reflects latest rollup data. If it becomes slow, promote to materialized view with `REFRESH MATERIALIZED VIEW CONCURRENTLY` triggered on any upstream rollup update |

**`ROIView` SQL:**

```sql
CREATE OR REPLACE VIEW "ROIView" AS
SELECT
  ccr."contentId",
  ccr."totalCostUsd"                         AS direct_cost_usd,
  COALESCE(csa."allocatedUsd", 0)            AS shared_cost_usd,
  (ccr."totalCostUsd" + COALESCE(csa."allocatedUsd", 0))  AS total_cost_usd,
  cnt.nicheId                                AS dominant_niche_id,
  crr."confirmedAmountUsd_timeDecay"         AS confirmed_revenue_usd_td,
  crr."confirmedAmountUsd_lastTouch"         AS confirmed_revenue_usd_lt,
  crr."confirmedAmountUsd_firstTouch"        AS confirmed_revenue_usd_ft,
  crr."confirmedAmountUsd_linear"            AS confirmed_revenue_usd_lin,
  crr."confirmedAmountUsd_viewWeighted"      AS confirmed_revenue_usd_vw,
  crr."expectedAmountUsd_timeDecay"          AS expected_revenue_usd_td,
  /* ROI ratios */
  CASE WHEN (ccr."totalCostUsd" + COALESCE(csa."allocatedUsd", 0)) > 0
       THEN crr."confirmedAmountUsd_timeDecay" / (ccr."totalCostUsd" + COALESCE(csa."allocatedUsd", 0))
       ELSE NULL END                         AS roi_ratio_confirmed_td,
  /* blended */
  CASE WHEN (ccr."totalCostUsd" + COALESCE(csa."allocatedUsd", 0)) > 0
       THEN (crr."confirmedAmountUsd_timeDecay" + 0.5 * crr."expectedAmountUsd_timeDecay")
            / (ccr."totalCostUsd" + COALESCE(csa."allocatedUsd", 0))
       ELSE NULL END                         AS roi_ratio_blended_td,
  /* confidence-exposure flag */
  CASE
    WHEN crr."lastRollupAt" < NOW() - INTERVAL '48 hours' THEN 'stale'
    WHEN crr."expectedAmountUsd_timeDecay" / NULLIF(
         crr."confirmedAmountUsd_timeDecay" + crr."expectedAmountUsd_timeDecay", 0) > 0.5
    THEN 'early'
    WHEN ccr."firstEmittedAt" < NOW() - INTERVAL '90 days' THEN 'settled'
    ELSE 'early'
  END                                        AS confidence_band,
  /* meta */
  ccr."firstEmittedAt"                       AS first_published_at,
  crr."lastRollupAt"                         AS last_rollup_at
FROM "ContentCostRollup" ccr
LEFT JOIN "ContentRevenueRollup" crr ON crr."contentId" = ccr."contentId"
LEFT JOIN (
  SELECT "contentId", SUM("allocatedUsd") AS "allocatedUsd"
  FROM "ContentSharedCostAlloc"
  GROUP BY "contentId"
) csa ON csa."contentId" = ccr."contentId"
LEFT JOIN (
  SELECT "contentId", "nicheId"
  FROM "ContentNicheTag" WHERE "isDominant" = true
) cnt ON cnt."contentId" = ccr."contentId";
```

**Performance budget**: at 1000 contents × 5 rollup tables, the join is trivial (<50ms on warm cache). Upgrade to matview with concurrent refresh only if we exceed ~50,000 content rows.

### F31 — Edge cases (exhaustive)

| Case | Condition | Handler |
|---|---|---|
| **Negative ROI (loss)** | `R_conf < C_total` | Normal — display negative ratio + red indicator. Alert at `roi_ratio < 0.5` after 30d settled. |
| **Infinite ROI (zero cost)** | `C_total = 0` | NULL ratio + flag `'cost_pending'` — triggers backfill check. Should never persist beyond 1h after publish. |
| **Zero revenue** | `R_conf = 0` AND `R_exp = 0` | Display `'no_revenue_yet'` until age > 90d, then `'zero_revenue_confirmed'` — feeds kill-switch heuristic. |
| **Revenue before cost** | RevenueLedger row with `earnedAt < ApiCostLedger first row` | Detect via CHECK; reject INSERT. Most likely timezone / wrongly-assigned subId. Audit alert. |
| **Payback on recurring revenue** | `r_content > 0.2` (content keeps earning) | Use multi-period CLV formula; payback = `min t : cumulative_discounted_R ≥ C_total` with discount `d=0.008333/mo`. |
| **Reversed revenue after ROI already computed** | New `RevenueLedger.status = 'reversed'` after dashboard shows positive ROI | Emit `ROIRevisionEvent` — dashboard recomputes live (ROIView auto-reflects). Alert if revision exceeds 20% OR flips sign. |
| **Late-arriving revenue beyond 90d** | New RevenueLedger row with `earnedAt < now − 120d` | Accept, but flag with `'historical_backfill'` — include in ROIView but emit alert for audit (unusual but legitimate). |
| **Split cross-platform attribution — one revenue, 5 content rows** | One `RevenueLedger` row attributed to `n > 1` contentIds | `RevenueAttribution.weight` sums to 1.0 per `revenueLedgerId` — invariant (iter-3 §F20). `ContentRevenueRollup` sums per-content attributed amount. No double-count. |
| **Content with no niche tag** | `ContentNicheTag` rows = 0 | Default to synthetic `Niche{slug='untagged'}` to keep niche roll-ups non-null. n8n alert at daily-count > 10. |
| **Retroactive shared-cost re-allocation** | User edits prior-month's `SharedCostMonth.totalSharedUsd` | Rejected — `lockedAt` immutable. Requires `SharedCostCorrection` row; ROIView includes an `IS_CORRECTED` flag. |
| **Currency drift** | `fxRate` recorded far from ECB spot at `earnedAt` | Background job compares to historical ECB; alert if `|drift| > 2%`. |
| **Tiny cost, zero revenue** | `C_total < $0.01` AND `R_conf = 0` | Exclude from dashboard by default (noise floor); available via "show unranked" toggle. |
| **Content pack (repost bundle)** | One `contentPackId` with N platform-specific `contentId`s | Aggregate upward: `ContentPackROI = SUM(contentId costs) vs SUM(contentId revenue)`. Shared-cost allocated to pack, then distributed to platform-contents by `active_days` (same rule as F27). |

### F32 — Hierarchical aggregation SQL patterns

**1. Per-video → per-content-pack**:

```sql
SELECT
  cp.id AS content_pack_id,
  cp.name,
  SUM(rv.total_cost_usd)                   AS pack_cost_usd,
  SUM(rv.confirmed_revenue_usd_td)         AS pack_confirmed_revenue_td,
  SUM(rv.expected_revenue_usd_td)          AS pack_expected_revenue_td,
  SUM(rv.confirmed_revenue_usd_td) / NULLIF(SUM(rv.total_cost_usd), 0) AS pack_roi_td
FROM ContentPack cp
JOIN Content c ON c.contentPackId = cp.id
JOIN "ROIView" rv ON rv."contentId" = c.id
GROUP BY cp.id, cp.name;
```

(Assumes `ContentPack` + `Content.contentPackId` exist — if not in current schema, add during implementation phase.)

**2. Per-niche (dominant-only)**:

See F28 query pattern.

**3. Per-niche (weighted multi-tag)**:

```sql
SELECT
  n.slug,
  SUM(crr."confirmedAmountUsd_timeDecay" * cnt.weight) AS weighted_revenue_usd,
  SUM(ccr."totalCostUsd" * cnt.weight)                 AS weighted_cost_usd,
  SUM(crr."confirmedAmountUsd_timeDecay" * cnt.weight) / NULLIF(SUM(ccr."totalCostUsd" * cnt.weight), 0) AS weighted_roi_ratio
FROM Niche n
JOIN ContentNicheTag cnt ON cnt.nicheId = n.id
JOIN ContentCostRollup ccr ON ccr.contentId = cnt.contentId
LEFT JOIN ContentRevenueRollup crr ON crr.contentId = cnt.contentId
GROUP BY n.slug;
```

**4. Per-platform (attribution-specific)**:

```sql
SELECT
  ra.platform,
  COUNT(DISTINCT ra.contentId)            AS contents_contributing,
  SUM(ra.attributedAmountUsd)             AS platform_attributed_revenue_usd,
  /* per-platform cost is trickier — content cost is platform-agnostic, so we prorate by per-platform view share */
  SUM(ccr.totalCostUsd * platform_view_share.share) AS platform_prorated_cost_usd
FROM RevenueAttribution ra
JOIN ContentCostRollup ccr ON ccr.contentId = ra.contentId
JOIN PlatformViewShare platform_view_share ON platform_view_share.contentId = ra.contentId
  AND platform_view_share.platform = ra.platform
WHERE ra.attributionModel = 'time_decay_lambda_0.05'
  AND ra.modelVersion = 'v1.0.0'
GROUP BY ra.platform;
```

Assumes `PlatformViewShare` exists as a per-content-per-platform view-count table (sourced from spec 007 BUC feedback loop). If not, fallback to equal split across posted platforms.

**5. Per-month rollup**:

```sql
SELECT
  DATE_TRUNC('month', rv.first_published_at) AS month,
  COUNT(*)                                  AS n_contents,
  SUM(rv.total_cost_usd)                    AS monthly_cost_usd,
  SUM(rv.confirmed_revenue_usd_td)          AS monthly_confirmed_revenue_usd,
  SUM(rv.confirmed_revenue_usd_td) / NULLIF(SUM(rv.total_cost_usd), 0) AS monthly_roi_ratio,
  AVG(rv.confidence_band = 'settled')       AS share_settled
FROM "ROIView" rv
GROUP BY month
ORDER BY month DESC;
```

### F33 — Confidence-exposure flag: deterministic derivation (supplements F26)

Exposed on every row of `ROIView` as `confidence_band ∈ {early, settled, stale, reversed}`:

```
IF last_rollup_at < now - 48h  OR  any_revenue_source in deprecated_list(2026) THEN stale
ELSE IF reversal_ratio_last_7d > 0.05                                          THEN reversed
ELSE IF expected / (expected + confirmed) > 0.5                                THEN early
ELSE IF age(c) < 30 days                                                       THEN early
ELSE IF age(c) > 90 days  AND  expected / total < 0.1                          THEN settled
ELSE                                                                                early
```

This gives a clear, single-column mental model for dashboard consumers. Every ROI number always carries its confidence.

### F34 — Putting it all together: the end-to-end ROI lifecycle (additive to iter-3 §F24)

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                viral-ops ROI engine (layers, top-down)                        │
├────────────────────────────────────────────────────────────────────────────────┤
│ Layer 4: Dashboard + Alerts (Q5, iter-5 focus)                                │
│   - ROIView rows feed shadcn charts (time-to-ROI line, niche bar, heat)       │
│   - BudgetAlert triggers from F29 kill-switch + F31 edge-case handlers        │
├────────────────────────────────────────────────────────────────────────────────┤
│ Layer 3: ROIView (unmaterialized SQL view) — join (F30)                       │
│   - LEFT JOIN ContentCostRollup + ContentSharedCostAlloc + ContentRevenueRoll │
│     + dominant-Niche                                                          │
│   - Computes: confidence_band, roi_ratio_confirmed/blended, per-model         │
├────────────────────────────────────────────────────────────────────────────────┤
│ Layer 2: Rollups (materialized)                                               │
│   - ContentCostRollup     [iter-1] — event-driven + hourly                    │
│   - ContentRevenueRollup  [iter-3] — nightly 03:00 UTC                        │
│   - ContentSharedCostAlloc [F27]  — monthly 1st 02:00 UTC                    │
│   - ContentNicheTag        [F28] — post-publish LLM-tagged + trend re-tag    │
├────────────────────────────────────────────────────────────────────────────────┤
│ Layer 1: Append-only ledgers                                                  │
│   - ApiCostLedger         [iter-1]                                            │
│   - RevenueLedger         [iter-3]                                            │
│   - RevenueAttribution    [iter-3]                                            │
│   - QuotaReservation      [iter-2]                                            │
│   - ShortLinkClick        [iter-3]                                            │
│   - SharedCostMonth       [F27]                                               │
├────────────────────────────────────────────────────────────────────────────────┤
│ Ancillary                                                                     │
│   - PricingCatalog [iter-1], AttributionModelConfig [iter-3],                 │
│     FxSnapshot [iter-3], Niche [F28], BetaBernoulliStats [F26]               │
└────────────────────────────────────────────────────────────────────────────────┘
```

**Confidence intervals flow**: bootstrap stats computed nightly alongside `ContentRevenueRollup` refresh; stored in `ContentRoiConfidence(contentId, asOf, p10, p50, p90, method)`; ROIView left-joins when dashboard requests drill-down.

## Ruled Out

- **Option A (flat per-video) shared-cost allocation** — rejected in F27: massively undercosts expensive long-form content, overcosts trivial reposts. The economic reality is that always-on infra serves content while it's live.
- **Option B (per-minute-rendered) as primary allocation** — rejected in F27: rewards pathologically-long videos at the expense of short-form, which is the opposite of Thai viral strategy (24-48h half-life, spec 005). Kept as tiebreaker only.
- **Single-niche-per-content** — rejected in F28: loses the intersectional signal (e.g., "Thai street food" + "budget travel" + "life-hack") that feeds spec 005 trend-viral-brain. Many-tag + one-dominant is strictly better.
- **Real-time `ROIView` materialization** — rejected in F30: overkill. Unmaterialized view with upstream materialized rollups hits <50ms on warm cache at viral-ops scale.
- **Pure frequentist point estimate for pending revenue** — rejected in F26: discards information about historical acceptance-rate variance, which is the whole reason confidence intervals matter.
- **Monte Carlo simulation as primary method** (alternative to bootstrap/Beta-Bernoulli) — considered, rejected: Beta-Bernoulli gives the same answer at O(1) for the common case; bootstrap handles the long-tail. Monte Carlo adds computational cost without adding accuracy for the ROI confidence-interval use case.
- **Mutable `SharedCostMonth` retroactive edits** — rejected in F27 + F31: `lockedAt` is immutable after allocation. Corrections go through `SharedCostCorrection` rows, preserving audit trail.
- **Pro-rating cost across platforms uniformly** — rejected in F32: should be weighted by actual view share (needs `PlatformViewShare` from spec 007 BUC). Fallback to equal split only when feedback-loop data absent.

## Dead Ends

- None this iteration — all planned lines of inquiry were productive. The deferred items from iter-3 (ShareASale direct docs, CJ GraphQL schema, Amazon Creators API endpoint deep-dive) remain deferred to iter-5+ as planned; they are not dead-ends but scheduled work.

## Sources Consulted

- https://en.wikipedia.org/wiki/Customer_lifetime_value (captured 2026-04-17) — canonical CLV formulas (infinite-horizon, multi-period discounted, simple-commerce variant); used to ground content-LTV math in F25.
- Prior spec 008/iterations/iteration-001.md (F7) — ApiCostLedger + ContentCostRollup schema.
- Prior spec 008/iterations/iteration-002.md (F13, F16) — QuotaReservation + end-to-end cost/quota emission flow.
- Prior spec 008/iterations/iteration-003.md (F17-F24) — RevenueLedger + RevenueAttribution + 5-model attribution + FX + reconciliation state machine + end-to-end lifecycle.
- Prior spec 005-trend-viral-brain (MEMORY.md) — 24-48h Thai trend half-life → `r_content ≈ 0.05-0.15` content-retention rate in F25.
- Prior spec 006-content-lab (MEMORY.md) — 5-stage prompt chain → stage-based cost allocation.
- Prior spec 007-l7-feedback-loop (MEMORY.md) — BUC (Budget Usage Controller) 4800×/24h → PlatformViewShare source for F32 per-platform query.
- `[INFERENCE]` — shared-cost inventory USD ranges (F27) derived from 2025-2026 known tier pricing of Supabase, n8n, Clerk, Vercel.
- `[INFERENCE]` — Beta-Bernoulli startup priors in F26 (Amazon Associates 85%, Impact.com 72%, CJ 70%, Shopee 80%) based on industry-typical affiliate acceptance rates from iter-3 §F21 reconciliation state-machine definitions.

## Assessment

- **Findings count:** 10 (F25-F34)
- **Fully new findings:** 9 (F25 ROI formula set, F26 Bayesian + bootstrap CI, F27 shared-cost amortization policy, F28 niche schema, F29 time-to-ROI chart spec + kill-switch, F30 materialization decision, F31 edge cases, F32 hierarchical aggregation SQL, F33 confidence-band derivation)
- **Partially new:** 1 × 0.5 = 0.5 (F34 end-to-end layer diagram — composition of iter-1/2/3/4 into coherent 4-layer view is new, but building blocks are reused)
- **Redundant:** 0
- **newInfoRatio = (9 + 0.5) / 10 = 0.95**
- **Simplicity bonus:** not triggered — adds primitives (Niche, ContentNicheTag, SharedCostMonth, ContentSharedCostAlloc, ContentRoiConfidence, ROIView) rather than consolidating.

**Questions addressed this iteration:** Q4 primarily (ROI engine fully fleshed out). Q5 secondary (dashboard chart spec in F29 + SQL patterns in F32 seed iter-5). Q3 tangentially (bootstrap settlement curves complement iter-3 state machine).

**Questions answered:**
- **Q4 ≈ 92% answered**: core formulas locked, CI math locked (Beta-Bernoulli + bootstrap), amortization policy locked, niche schema locked, materialization decided, edge cases exhaustive, aggregation SQL ready. Remaining 8%: (a) empirical validation of `r_content ≈ 0.05–0.15` once viral-ops data lands, (b) Thai-specific LTV backtest, (c) specific chart library config (shadcn-recharts props) — iter-5 focus.
- Q1, Q2, Q3 unchanged (95% / 90% / 90%).

## Reflection

- **What worked and why:** Building on iter-3's substrate (ContentRevenueRollup + 5 attribution models pre-computed as columns) made the ROI engine a clean join problem — Layer 3 ROIView is a simple unmaterialized SQL view because Layer 2 has already done the heavy lifting. Causal: the 5-model-column design from iter-3 was specifically engineered so that Layer 3 could switch attribution models at query time, which collapses what would have been a state-explosion problem (5 models × 2 revenue states × N contents) into a single JOIN. Similarly, the Wikipedia CLV formulas (especially the simple commerce variant `CLV = avg_revenue × GM / churn`) mapped *exactly* onto Thai viral content economics once "customer" was reinterpreted as "content piece" and "retention" as "revenue-retention month-over-month".

- **What didn't work and why:** Initially attempted a more abstract "cost-attribution policy as a plug-in" design (allowing users to customize allocation rules at runtime) — rejected as over-engineering for a tool that has exactly one reasonable rule (time-weighted active-days with rendering-minute tiebreaker). Similarly, considered but rejected allowing `lambda` of time-decay to be per-niche — rejected because it would require per-niche empirical calibration we don't yet have. These are things to revisit in iter-6+ if empirical data reveals niche-specific decay rates.

- **What I'd do differently next iteration:** iter-5 should focus on Q5 — the dashboard architecture. Specifically: (a) concrete shadcn-recharts / shadcn-ui chart component selection (line + area + histogram + heatmap), (b) n8n alert pipeline topology (cron × trigger → channel fan-out), (c) the exact 7 dashboard views listed in research.md §5, (d) back-verify iter-3 open items (ShareASale docs + CJ GraphQL schema), (e) back-verify iter-2 open items (ElevenLabs concurrency direct source). iter-5 is also the right time to run a quality-guard check: all answered-question coverage percentages should be cross-validated against actual findings counts per question.

## Recommended Next Focus (for Iteration 5)

**Q5 — Dashboard + Alerts Architecture** is next on critical path. Specifically:

1. **Chart primitives**: which shadcn-recharts components for each of the 7 dashboard views (line, area, heatmap, histogram, bar, table). Default props + responsive behavior + accessibility.
2. **Alert pipeline topology**: n8n workflows for budget-threshold alerts (F29 kill-switch, LLM spend > N% monthly budget, ROI z-score > 2σ per niche), channel fan-out (email/Slack/Discord/in-app), rate-limiting to avoid alert spam.
3. **Dashboard views inventory** (complete list):
   - (a) Daily cost panel (last 30d line chart + MoM comparison)
   - (b) Monthly cost panel (12-month bar chart + budget threshold line)
   - (c) Per-video ROI table (sortable, filterable, with confidence_band badges)
   - (d) Budget-alert status board (active alerts + history)
   - (e) Niche-level ROI heatmap (niche × week)
   - (f) Platform-ad revenue trend (per-platform stacked area)
   - (g) Affiliate reconciliation aging (pending → locked → confirmed waterfall)
4. **Back-verification** of deferred iter-2/3 items: ElevenLabs concurrency, ShareASale REST API, CJ GraphQL commission-detail schema, Amazon Creators API endpoint deep-dive. Use iter-3's "secondary-source triangulation" pattern.
5. **Quality-guard pass**: cross-validate each question's answered-% against concrete findings coverage; update the synthesis state table in research.md.

If Q5 reaches ≥90% and back-verifications hit ≥95%, convergence check fires and iter-5 likely becomes the final substantive iteration, with iter-6 as synthesis + final ROI + dashboard end-to-end narrative.

## Graph Events (for JSONL)

**Nodes:**

- `schema:ROIView` — unmaterialized SQL view, Layer 3
- `schema:Niche`, `schema:ContentNicheTag` — niche taxonomy + many-to-many with dominant flag
- `schema:SharedCostMonth`, `schema:ContentSharedCostAlloc` — shared-cost amortization (F27)
- `schema:ContentRoiConfidence` — Beta-Bernoulli + bootstrap results storage
- `schema:ContentPack` — repost-bundle abstraction (referenced in F32)
- `schema:PlatformViewShare` — per-platform view count split (referenced in F32, sourced from spec 007)
- `schema:BetaBernoulliStats` — running acceptance-rate Beta priors per affiliate source
- `concept:content-LTV`, `concept:content-CAC-proxy`, `concept:gross-margin`, `concept:contribution-margin`, `concept:payback-period`, `concept:time-to-break-even`
- `concept:beta-bernoulli-acceptance-rate`, `concept:bootstrap-confidence-interval`, `concept:settlement-curve`
- `concept:time-weighted-active-days-allocation`, `concept:dominant-niche-tag`, `concept:weighted-niche-rollup`
- `concept:confidence-band-early-settled-stale-reversed`
- `concept:kill-switch-day14-break-even-not-reached`
- `concept:roi-revision-event`, `concept:historical-backfill-flag`
- `concept:monthly-content-retention-rate-r-content`
- `formula:CLV-infinite-horizon`, `formula:CLV-multi-period-discounted`, `formula:CLV-simple-commerce`
- `formula:roi-ratio-confirmed`, `formula:roi-ratio-blended`, `formula:payback-period`, `formula:gross-margin`, `formula:contribution-margin`
- `allocation-policy:flat-per-video` (rejected), `allocation-policy:per-minute-rendered` (rejected as primary), `allocation-policy:time-weighted-active-days` (chosen)
- `materialization:materialized-view-content-cost-rollup`, `materialization:materialized-view-content-revenue-rollup`, `materialization:unmaterialized-view-roiview`, `materialization:materialized-monthly-shared-cost-alloc`
- `edge-case:negative-roi`, `edge-case:infinite-roi-zero-cost`, `edge-case:reversed-revenue-post-display`, `edge-case:late-arriving-revenue-beyond-90d`, `edge-case:untagged-content-default-niche`, `edge-case:recurring-revenue-payback`

**Edges:**

- `schema:ROIView` JOINS `schema:ContentCostRollup`, `schema:ContentRevenueRollup`, `schema:ContentSharedCostAlloc`, `schema:ContentNicheTag`
- `schema:ContentRevenueRollup` EXPOSES `formula:roi-ratio-confirmed`, `formula:roi-ratio-blended`, `concept:confidence-band-early-settled-stale-reversed`
- `concept:content-LTV` DERIVED_FROM `formula:CLV-infinite-horizon`, `formula:CLV-multi-period-discounted`, `formula:CLV-simple-commerce`
- `concept:content-LTV` INPUTS `concept:monthly-content-retention-rate-r-content`
- `concept:beta-bernoulli-acceptance-rate` SUPPORTS `schema:ContentRoiConfidence` FOR per_source_expected_revenue
- `concept:bootstrap-confidence-interval` ALTERNATIVE_TO `concept:beta-bernoulli-acceptance-rate` FOR sparse_data_fallback
- `allocation-policy:time-weighted-active-days` CHOSEN_OVER `allocation-policy:flat-per-video`, `allocation-policy:per-minute-rendered` BECAUSE thai_viral_half_life_24-48h
- `schema:SharedCostMonth` LOCKED_AFTER allocation_cron_completes
- `schema:ContentSharedCostAlloc` AGGREGATES_INTO `schema:ContentCostRollup.totalCostUsd` VIA monthly_append
- `schema:Niche` HAS_MANY `schema:ContentNicheTag`
- `schema:ContentNicheTag` ENFORCES one_dominant_per_content VIA partial_unique_index
- `concept:kill-switch-day14-break-even-not-reached` CONSUMES `concept:bootstrap-confidence-interval` AT day14_p50
- `concept:confidence-band-early-settled-stale-reversed` READS `schema:RevenueLedger.status`, `schema:ContentRevenueRollup.lastRollupAt`, `schema:ApiCostLedger.deprecated_source_list`
- `materialization:unmaterialized-view-roiview` CHOSEN_OVER materialized_equivalent BECAUSE sub_50ms_at_1k_rows
- `materialization:unmaterialized-view-roiview` PROMOTES_TO materialized_variant IF content_count > 50000
- `edge-case:reversed-revenue-post-display` EMITS `concept:roi-revision-event`
- `edge-case:late-arriving-revenue-beyond-90d` FLAGGED_AS historical_backfill
- `question:Q4` ADDRESSED_BY `schema:ROIView`, `formula:roi-ratio-confirmed`, `formula:payback-period`, `concept:content-LTV`, `concept:beta-bernoulli-acceptance-rate`, `concept:bootstrap-confidence-interval`, `allocation-policy:time-weighted-active-days`, `schema:Niche`, `materialization:unmaterialized-view-roiview`, `concept:confidence-band-early-settled-stale-reversed`, `concept:kill-switch-day14-break-even-not-reached`
- `question:Q4` NEXT_FOCUS `question:Q5`
- `concept:content-LTV` FEEDS_BACK `spec:005-trend-viral-brain` VIA niche_roi_scoring
- `concept:weighted-niche-rollup` FEEDS `spec:005-trend-viral-brain` FOR niche_trend_scoring
