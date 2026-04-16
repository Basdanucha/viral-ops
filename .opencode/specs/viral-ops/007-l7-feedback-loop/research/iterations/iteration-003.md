# Iteration 3: GBDT Retraining + Drift Detection (Q3)

## Focus

Design the LightGBM (L2 GBDT) retraining architecture with drift-aware triggers for a Thai 24–48h viral-lifecycle model. Deliver: (a) drift-detection taxonomy with concrete algorithms, (b) retraining trigger policy (scheduled vs drift vs performance vs hybrid), (c) training-data construction under label-latency + class-imbalance constraints, (d) feature-store decision for viral-ops scale, (e) model-registry / versioning + A-B rollout strategy, (f) infrastructure integration with Q2 ingestion pipeline and (g) citations for Evidently AI + NannyML + MLflow.

Prior context (do NOT re-derive):
- 38-feature LightGBM target = `log(views_168h / followers)` [SOURCE: 005-trend-viral-brain/research/research.md:307-332]
- Existing drift baseline: PSI > 0.20 for 2+ weeks → recalibrate LLM prompts; GBDT MAE ↑ 15% → immediate retrain; Spearman < 0.15 → dimension review; weekly cron `0 3 * * 0` [SOURCE: 005-trend-viral-brain/research/research.md:352-356, 511]
- Evidently AI already chosen as monitoring tool [SOURCE: 005-trend-viral-brain/research/research.md:526]
- `performance_metrics` Prisma schema + `pollAgeBucket` enum for same-age cohort slicing [SOURCE: iteration-002.md §B]

## Actions Taken

1. **Read state files + iter-001.md + iter-002.md + findings-registry.json + 005-trend-viral-brain/research.md** — confirmed 0 exhausted approaches in Q3 space, extracted the 38-feature+target+cron baseline from L2 research, verified the Prisma schema from iter-2 already has the right columns for training-feature derivation.
2. **WebFetch — Evidently AI "all metrics" index** `https://docs.evidentlyai.com/metrics/all_metrics` — confirmed preset names: `DataDriftPreset()`, `DataSummaryPreset()`, `RegressionPreset()`, `ValueDrift()`. Noted the index page defers algorithm detail to `customize_data_drift`.
3. **WebFetch — Evidently AI "customize data drift" table** `https://docs.evidentlyai.com/metrics/customize_data_drift` — **18+ algorithms** extracted with exact names, applicable column types, default thresholds, and direction semantics (p_value < θ vs distance ≥ θ). This is the canonical drift-algorithm menu. See §A.
4. **WebFetch — Evidently AI "DataDriftPreset"** `https://docs.evidentlyai.com/metrics/preset_data_drift` — confirmed auto-method selection by column type + sample size; prediction + target drift are just additional columns in the same preset (no special API), and `drift_share` (default 0.5) is the dataset-level rollup threshold.
5. **WebFetch — NannyML performance-estimation tutorial** `https://nannyml.readthedocs.io/en/stable/tutorials/performance_estimation.html` — HTTP 403 Forbidden (readthedocs blocking bot). Fallback to NannyML blog URL below.
6. **WebFetch — NannyML blog "Estimating model performance without labels"** `https://www.nannyml.com/blog/estimating-model-performance-without-labels` — HTTP 404 (URL restructured). See Ruled Out. Relied on prior knowledge + Evidently cross-reference for CBPE/DLE design rather than citing a live doc.
7. **WebFetch — LightGBM Python intro** `https://lightgbm.readthedocs.io/en/latest/Python-Intro.html` — HTTP 403 (same readthedocs block as NannyML). Fallback: relied on well-established LightGBM API semantics already documented in L2 research (Optuna tuning, weekly retrain) + standard LightGBM `init_model` continued-training semantics flagged as `[INFERENCE: established LightGBM 4.x API behavior]`.
8. **WebFetch — MLflow Model Registry** `https://mlflow.org/docs/latest/model-registry.html` — content rendered empty (JS-heavy page). Limited detail returned; the stage-transition concepts are well-established baseline MLflow knowledge, flagged `[INFERENCE: standard MLflow 2.x registry API]`.

**Budget**: 8 WebFetch + 4 state reads = 12 tool calls. At cap; no further probing. Three doc endpoints returned 403/404/empty — ruled out for this iteration, documented workarounds.

---

## Findings

### A. DRIFT DETECTION TAXONOMY

#### A.1 Three-Axis Drift Model (what moves, what we measure)

| Drift Axis | Formal Definition | Observable When | Dominant Algorithm Family |
|---|---|---|---|
| **Data / Feature drift** (covariate shift) | `P(X)` changes while `P(Y \| X)` stays fixed | Immediately at inference time (no labels needed) | Distribution tests on feature columns |
| **Prediction drift** | `P(ŷ)` changes; model outputs shift even if features look similar | Immediately at inference (compare `ŷ_t` vs `ŷ_ref`) | Same tests applied to the prediction column |
| **Label drift** (prior shift) | `P(Y)` marginal shifts | After label arrival (T+168h for viral-ops) | Same tests applied to realized target column |
| **Concept drift** | `P(Y \| X)` changes — same inputs, different ground truth | Only after labels arrive; can be inferred via CBPE | ADWIN, Page-Hinkley, DDM/EDDM, or estimated-performance drop |

For the viral-ops 24–48h lifecycle model, the dominant practical risk is **concept drift** (Thai-TikTok algorithm changes silently change what goes viral), but because label latency is T+168h (7-day `views_168h` target per 005), we cannot wait for labeled concept drift — we lean on **prediction drift + data drift** as *leading indicators* and reserve label-based concept drift for weekly confirmatory checks. [INFERENCE: standard pattern in NannyML/Evidently guidance, grounded in label-latency constraint from 005-trend-viral-brain]

#### A.2 Evidently AI Algorithm Menu (canonical)

18+ drift methods available in Evidently AI (confirmed Apr 2026):

| Method | Column Types | Default Threshold | Trigger Direction |
|---|---|---|---|
| `ks` (Kolmogorov–Smirnov) | Numerical only | 0.05 | p_value < θ |
| `chisquare` (Chi-Square) | Categorical (>2 labels) | 0.05 | p_value < θ |
| `z` (Z-test) | Categorical (binary) | 0.05 | p_value < θ |
| `wasserstein` (Earth Mover) | Numerical | 0.1 | distance ≥ θ |
| `kl_div` (KL divergence) | Numerical & categorical | 0.1 | divergence ≥ θ |
| **`psi` (Population Stability Index)** | Numerical & categorical | **0.1** | value ≥ θ |
| `jensenshannon` | Numerical & categorical | 0.1 | distance ≥ θ |
| `anderson` (Anderson–Darling) | Numerical | 0.05 | p_value < θ |
| `fisher_exact` | Categorical | 0.05 | p_value < θ |
| `cramer_von_mises` | Numerical | 0.05 | p_value < θ |
| `g-test` | Categorical | 0.05 | p_value < θ |
| `hellinger` | Numerical & categorical | 0.1 | distance ≥ θ |
| `mannw` (Mann–Whitney U) | Numerical | 0.05 | p_value < θ |
| `ed` (Energy Distance) | Numerical | 0.1 | distance ≥ θ |
| `es` (Epps–Singleton) | Numerical | 0.05 | p_value < θ |
| `t_test` | Numerical | 0.05 | p_value < θ |
| `empirical_mmd` | Numerical | 0.05 | p_value < θ |
| `TVD` (Total Variation Distance) | Categorical | 0.05 | p_value < θ |

Plus text drift: `perc_text_content_drift` (θ=0.95) and `abs_text_content_drift` (θ=0.55). [SOURCE: https://docs.evidentlyai.com/metrics/customize_data_drift]

**Dataset-level rollup**: `drift_share` parameter (default **0.5** — dataset is "drifted" if ≥50% of columns drift). [SOURCE: same]

**Auto-method selection**: `DataDriftPreset()` picks a method per column based on column type + sample size; explicit override is per-column. [SOURCE: https://docs.evidentlyai.com/metrics/preset_data_drift]

#### A.3 Recommended Drift Stack for viral-ops L7

The L2 baseline already chose **PSI > 0.20** as the recalibration threshold [SOURCE: 005]. This iteration *upgrades* the stack:

| Axis | Algorithm | Threshold | Rationale |
|---|---|---|---|
| **Data drift — numerical features** (32 of 38) | `psi` | > 0.20 (severe) / 0.10–0.20 (warn) | Already specified in L2; PSI's banded interpretation matches ML-industry standard (0.1 insignificant, 0.1–0.25 moderate, >0.25 severe). Keep. |
| **Data drift — categorical features** (4 of 38: platform, language, account_tier, time_bucket) | `jensenshannon` + `chisquare` fallback | 0.1 distance / 0.05 p-val | JS is more stable than PSI on low-cardinality categorical (per Evidently guidance); chi-square as secondary significance test. [INFERENCE: Evidently column-type recommendations] |
| **Prediction drift** (`ŷ = log(views_168h/followers)` estimate at T+24h) | `wasserstein` | 0.1 | Prediction is a continuous score; Wasserstein captures tail movement that PSI can miss. Alerts leading indicator. |
| **Label drift** (`y = log(views_168h/followers)` when T+168h arrives) | `psi` | > 0.20 | Consistency with feature-drift banding; monthly rollup. |
| **Concept drift** (label-dependent, lagged) | **Derived: ΔMAE > 15%** on held-out daily window | 15% | Inherits L2's existing performance-triggered rule. No change. |
| **Unlabeled concept drift proxy** (leading) | **CBPE-style estimated MAE** via cross-model agreement | 15% estimated | [INFERENCE: when labels lag 7 days, estimate MAE using prediction confidence + prediction drift as a proxy; confirm weekly when labels land] |

This gives us **4 parallel drift channels** (feature numerical, feature categorical, prediction, label) + **1 performance channel** (MAE on labeled window) + **1 rubric channel** (Spearman < 0.15 per LLM dimension, inherited from L2).

### B. RETRAINING TRIGGER POLICY (Hybrid)

#### B.1 Decision Matrix

| Trigger Type | Cadence | Signal | Action | Rationale for Thai 24–48h Lifecycle |
|---|---|---|---|---|
| **Scheduled (baseline)** | Weekly, Sunday 03:00 UTC (cron `0 3 * * 0`) | Unconditional | Full retrain on 90-day rolling window | Cheap, bounds staleness; matches L2 plan. Weekly = 3–5 complete viral cycles worth of data. **Daily is too aggressive** (insufficient new labels — 24–48h lifecycle ≠ 24h label arrival; labels land at T+168h). |
| **Drift-triggered (data)** | Daily check | `drift_share > 0.5` OR any feature PSI > 0.20 sustained 2 days | Open retrain ticket (not immediate retrain — avoid drift-chasing thrash) | L2's "sustained 2 weeks" is too slow for a 24–48h-lifecycle domain; tighten to **2 days sustained** (but only opens ticket; retrain job decides) |
| **Drift-triggered (prediction)** | Hourly check | `wasserstein(ŷ_24h, ŷ_ref) > 0.1` for 2 consecutive hours | Alert + queue retrain eval | Prediction drift is the fastest leading indicator; the algorithm "flipped what it rewards" usually shows up in ŷ before features. |
| **Performance-triggered (label)** | Daily (labels landing at T+168h, so rolling 7-day label window) | MAE ↑ 15% on held-out daily window | **Immediate retrain** | Inherited from L2. High-priority. |
| **Correlation collapse** (per LLM dimension) | Weekly | Spearman < 0.15 for 2 weeks | Rubric review + possibly zero-weight the dimension | Inherited from L2. |
| **Data milestone** | Event-based | +200 new labeled videos since last train | Opportunistic retrain | Inherited from L2. |
| **Upstream LLM model update** | Event-based | LLM judge model version change | Re-run 50-concept gold standard calibration, then retrain | Inherited from L2. |

#### B.2 Hybrid Policy = Scheduled Floor + Drift/Performance Ceiling

The weekly schedule is a **floor** (guarantees staleness ≤ 7d). Drift and performance triggers can force retrain earlier but cannot delay beyond weekly. Opportunistic data-milestone retrain is allowed **only if ≥ 48h since last retrain** (anti-thrash guard). [INFERENCE: hybrid scheduled-plus-triggered is the recommended pattern in Evidently docs and widely deployed at Uber/Spotify per industry writeups; no single source fetched this iteration but cross-validated against L2's existing hybrid design]

#### B.3 Cadence Analysis for 24–48h Lifecycle

Given:
- Thai viral lifecycle: 24–48h [SOURCE: 005]
- Label latency: T+168h (7d) [SOURCE: 005 target metric]
- Label ratio: ~1–5% of uploads go viral [INFERENCE: generic social-media power-law; assumption]

Implication: the **slowest moving part is label arrival**, not lifecycle. A daily retrain would retrain on mostly-partial labels (posts < 168h old have no final `views_168h`). Weekly retrain gives every Sunday's batch a full week of labeled training examples from the previous week's uploads. **Weekly cadence is structurally correct; only tighten to drift-triggered sub-weekly retrains when leading indicators fire.**

### C. TRAINING-DATA CONSTRUCTION

#### C.1 Label Definition (Regression, not Classification)

L2 already specifies **regression** target = `log(views_168h / followers)` [SOURCE: 005:326]. This is the superior design vs binary "went viral" because:
- Regression preserves the magnitude signal (a 10M-view post is 100× more informative than a 10k-view post; binary collapses both to 1).
- Avoids the "define viral" rabbit-hole (threshold bikeshedding).
- Log-transform handles the power-law distribution natively.

Keep the L2 target; **no change recommended**.

#### C.2 Label-Latency Handling

- **Training-row eligibility**: a post enters the training set only when `metricDate >= upload_date + 168h`, i.e., the T+7d poll has landed for that `(content_id, platform, platform_post_id)` tuple in `performance_metrics`. Use `pollAgeBucket = T_7D` row from iter-2 schema as the gate.
- **Training-set freshness**: on any given Sunday retrain, the newest usable training rows are posts uploaded ≤ T-168h = Sunday minus 7 days. Rows newer than that are "in flight" (for inference and drift monitoring, NOT training).
- **Feature snapshotting at inference time**: to avoid online/offline skew, capture a **frozen feature vector** at the moment of first prediction (typically at upload completion + 1h — i.e., when `T_1H` row lands for the primary platform). Store as `training_feature_snapshot` JSON on the `content` row. When the T+168h label lands, pair it with the frozen snapshot for training; do NOT re-derive features from latest `performance_metrics` (that would introduce target leakage from later observations). [INFERENCE: standard feature-logging pattern for ML systems to prevent train-serve skew]

#### C.3 Class Balance / Imbalance (applicable to scoring bands, not raw target)

Because the target is continuous log-rate, there is no literal "class imbalance". However, downstream consumers discretize into SURGING/RISING/EMERGING bands (per L2 velocity table, 005:115). If a secondary **binary viral classifier** (P(is_viral)) is trained on top of the regression for L3 downstream consumers:
- Use LightGBM `is_unbalance=True` or compute `scale_pos_weight = n_negative / n_positive` when class ratio < 10%. [INFERENCE: standard LightGBM imbalance API]
- **Prefer sample weighting** over SMOTE: SMOTE on tabular structured features with categorical mixing often degrades calibration; LightGBM's `sample_weight` keeps probability estimates calibrated, which matters because Thompson Sampling (L3, 006) requires calibrated probabilities as arm priors.
- Focal loss is NOT standard in LightGBM; skip.

#### C.4 Training-Window Retention

- **Rolling 90-day window** (L2 default) on LABELED rows only.
- Posts older than 90 days: archive but retain for long-term drift comparison (the *reference window* in Evidently should be the 90-day window from the PREVIOUS training run — use it as baseline to detect current 90d shift).
- Thai 24–48h lifecycle means most training signal is from the last 14–30 days; the tail 30–90 days primarily stabilizes long-tail features (account_age, publisher_history). [INFERENCE: power-law distribution of label magnitude]
- **Weighted training**: apply a time-decay weight `exp(-age_days / 30)` to each training row so fresh examples dominate learning without losing the tail regularizer. [INFERENCE: standard exponential decay for non-stationary domains; choose half-life matching cycle length]

### D. FEATURE-STORE DECISION

#### D.1 Trade-off Matrix

| Option | Infra Cost | Dev Cost | Online/Offline Skew Risk | Scale Ceiling | Recommendation |
|---|---|---|---|---|---|
| **A — Pure Postgres + Prisma** (reuse `performance_metrics` + materialized views for rollups) | $0 marginal | Low (reuse existing) | Low if feature derivation is read-only views | ~10M rows manageable; beyond that → partitioning | **RECOMMENDED for v1** |
| **B — Dedicated feature store** (Feast, Tecton) | +$200–$2000/mo | High (new service, new schema, new deploy) | Low (designed for skew prevention) | Billions of rows | **Overkill for viral-ops scale** (expected 10k–1M posts Year 1) |
| **C — Hybrid** (Postgres for online serving + S3/Parquet training snapshots) | Low ($10–50/mo S3) | Medium | Medium (snapshot logic must stay in sync) | Scales with S3 | **Adopt only when Postgres table exceeds 50M rows OR training takes > 30 min** |

#### D.2 Option A Implementation Pattern

```prisma
model TrainingFeatureSnapshot {
  id                String   @id @default(cuid())
  contentId         String   @unique
  platform          Platform
  snapshotAt        DateTime // T+1h frozen feature moment
  featuresJson      Json     @db.JsonB // 38-feature vector at inference time
  featureSchemaVer  String   // e.g. "v1.0", "v1.1" — track feature-engineering changes
  predictionYhat    Float    // ŷ at snapshot time
  modelVersion      String   // which model produced ŷ
  labelY            Float?   // NULL until T+168h poll lands
  labelLandedAt     DateTime?
  @@index([platform, snapshotAt])
  @@index([labelLandedAt]) // for "eligible for training" sweeps
  @@index([modelVersion])  // for version-stratified drift analysis
  @@map("training_feature_snapshots")
}
```

Training pipeline query (weekly cron):
```sql
SELECT features_json, label_y
FROM training_feature_snapshots
WHERE label_landed_at IS NOT NULL
  AND label_landed_at >= NOW() - INTERVAL '90 days'
  AND feature_schema_ver = 'v1.0'
ORDER BY snapshot_at DESC;
```

Online inference reads directly from `performance_metrics` + aggregates (via Prisma client or a thin read model). Because training snapshot was frozen, the model trains on the SAME feature values that were used at inference — **skew = 0 by construction**. [INFERENCE: snapshot-at-inference is the industry-standard anti-skew pattern]

#### D.3 Drift-Event Audit Table

```prisma
model DriftEvent {
  id              String   @id @default(cuid())
  detectedAt      DateTime @default(now())
  driftKind       DriftKind // FEATURE_NUMERICAL | FEATURE_CATEGORICAL | PREDICTION | LABEL | PERFORMANCE | CORRELATION
  columnName      String?  // NULL for dataset-level
  method          String   // "psi" | "wasserstein" | "jensenshannon" | "mae_delta" | "spearman"
  thresholdValue  Float
  observedValue   Float
  sampleSize      Int
  referenceWindow Json     @db.JsonB // { start, end, count }
  currentWindow   Json     @db.JsonB
  severity        Severity // INFO | WARN | CRITICAL
  action          String   // "logged" | "retrain_queued" | "retrain_triggered" | "alerted"
  retrainJobId    String?  // FK to retrain job run when applicable
  resolvedAt      DateTime?
  resolution      String?  // "retrained" | "false_alarm" | "rubric_review" | "manual_override"
  @@index([detectedAt])
  @@index([driftKind, severity])
  @@index([retrainJobId])
  @@map("drift_events")
}

enum DriftKind {
  FEATURE_NUMERICAL
  FEATURE_CATEGORICAL
  PREDICTION
  LABEL
  PERFORMANCE
  CORRELATION
}

enum Severity {
  INFO
  WARN
  CRITICAL
}
```

### E. MODEL REGISTRY / VERSIONING

#### E.1 Registry Choice: MLflow (local, Postgres-backed)

- **Why MLflow over W&B or DIY**: MLflow is open-source, self-hostable alongside the existing Postgres instance, has a native `mlflow.lightgbm` flavor, and the registry stage machine (`None → Staging → Production → Archived`) maps directly onto a shadow/canary/full rollout. [INFERENCE: MLflow 2.x standard registry API; W&B requires SaaS lock-in + higher cost at viral-ops scale]
- **Why not DIY on S3+Postgres**: registry work (lineage, metric comparison, signed artifacts, stage transitions with audit) is non-trivial; MLflow gives it for free with a thin Postgres dependency viral-ops already runs.

#### E.2 A/B Rollout State Machine

```
[Training complete]
       │
       ▼
[register_model(name="viral-gbdt", source=artifact)]
       │
       ▼
[stage=None] ──promote──▶ [stage=Staging]        ← shadow mode: scored alongside Production but NOT served
                              │
                              ▼ (24h min + metric gates)
                          [stage=Staging, canary=10%] ← serves 10% of traffic; compare online MAE vs Production
                              │
                              ▼ (48h + canary passes)
                          [stage=Production]     ← fully serving
                              │
                              │ (drift regression detected)
                              ▼
                          [stage=Archived] ← Production falls back to previous version
```

**Shadow-mode (stage=Staging)**: the challenger scores every request, but the Production model's prediction is returned to callers. Scores of both are logged side-by-side for MAE comparison. No user impact.

**Canary (stage=Staging with routing %)**: 10% of traffic sees challenger predictions; 90% sees Production. 48h minimum. Promote when challenger MAE ≤ Production MAE within ±3% AND no drift regression.

**Rollback**: on drift regression in Production (ΔMAE > 15% vs validation), transition newest Production → Archived and the previous Archived version → Production. Single transaction. Alert human operator. [INFERENCE: MLflow stage-transition API supports this atomically]

### F. INFRASTRUCTURE INTEGRATION

#### F.1 Component Placement

| Component | Location | Rationale |
|---|---|---|
| **LightGBM training** | Python worker (new `apps/ml-trainer/` container) | Sklearn/LightGBM not supported by n8n; training job is long-running (5–30 min at 100k rows) and GPU-optional |
| **Training orchestration** | n8n cron (calls Python worker via internal HTTP) | n8n already owns schedules; Python worker is the data plane |
| **Inference** | FastAPI service (co-located with BERTopic per 005:[ANCHOR:bertopic-fastapi]) | BERTopic already Python+FastAPI; serve GBDT from the same container to minimize infra surface |
| **Drift monitoring** | Evidently AI job in same Python worker | Run after every inference batch (hourly for prediction drift, daily for feature drift) |
| **Model artifacts** | MLflow tracking server + Postgres backend + S3/local artifact store | Reuse existing Postgres; S3 if already provisioned else local volume |
| **Feature store** | Postgres `training_feature_snapshots` + `performance_metrics` views (Option A) | No new infra |
| **Drift events** | Postgres `drift_events` table | Auditable, queryable from dashboards |

#### F.2 Connection to Q2 Ingestion Pipeline

From iter-2 `performance_metrics` table, the training-data handoff is:

```
performance_metrics (pollAgeBucket=T_7D, metricDate >= uploadDate + 7d)
       │
       │ (daily Python job: label_backfill)
       ▼
training_feature_snapshots (labelY, labelLandedAt populated)
       │
       │ (weekly Python job: train_gbdt)
       ▼
MLflow artifact store + registry (stage=Staging)
       │
       │ (gates: shadow + canary + MAE comparison)
       ▼
MLflow registry (stage=Production)
       │
       │ (FastAPI loads on model-change webhook)
       ▼
/api/score endpoint → L3 Content Lab (Thompson Sampling prior update)
```

Each edge is an n8n workflow triggered on cron OR MLflow webhook. The **critical new n8n workflow** is `drift_detection_tick`:

```
Cron (*/30 min)
  → HTTP POST http://ml-trainer:8080/drift/check
  → Python worker runs Evidently Report on:
     - performance_metrics (last 24h window vs last 7d baseline): feature drift
     - training_feature_snapshots (ŷ last 24h vs model-trained-on baseline): prediction drift
     - training_feature_snapshots where labelLandedAt IS NOT NULL (last 14d vs prior 90d): label drift
  → Evidently emits JSON → Python worker writes rows to drift_events table
  → If any severity=CRITICAL: n8n posts to Slack + creates `drift_events.action='retrain_queued'`
  → Weekly Sunday 03:00 UTC: n8n reads queued drift_events, assembles justification, invokes /train endpoint
```

### G. CITATIONS (real, verified this iteration)

- **Evidently AI** — 18+ drift algorithm menu with exact names + thresholds + column-type applicability. [SOURCE: https://docs.evidentlyai.com/metrics/customize_data_drift]
- **Evidently AI DataDriftPreset** — auto-method selection, dataset-level `drift_share` default 0.5, prediction+target drift via column inclusion. [SOURCE: https://docs.evidentlyai.com/metrics/preset_data_drift]
- **Evidently AI all metrics index** — `DataDriftPreset`, `DataSummaryPreset`, `RegressionPreset`, `ValueDrift` naming confirmed. [SOURCE: https://docs.evidentlyai.com/metrics/all_metrics]
- **L2 baseline (005-trend-viral-brain)** — 38-feature set, target = log(views_168h/followers), weekly cron `0 3 * * 0`, PSI>0.20, MAE+15%, Spearman<0.15 [SOURCE: 005-trend-viral-brain/research/research.md:307–356, 511]
- **Q2 ingestion pipeline (iter-2)** — `performance_metrics` schema with `pollAgeBucket` + JSONB retention; composite-key idempotent upsert [SOURCE: iteration-002.md §B, §D]
- **Pending / dead-ends (not re-fetch)**: NannyML ReadTheDocs (403), NannyML blog (404), LightGBM ReadTheDocs (403), MLflow registry page (empty JS render). These should be re-tried via GitHub raw docs or npm/pypi-hosted mirrors in a future iteration if more depth needed.

---

## Open Questions

- **Q3.new-1**: Should we adopt **NannyML's CBPE (Confidence-Based Performance Estimation)** as the canonical "concept drift without labels" proxy, given 7-day label latency? Need to verify via alternate source (GitHub readme or PyPI description) whether CBPE applies cleanly to LightGBM regression (most literature uses classification). **Defer to iteration 4 or 5 as side-quest — low priority; drift-based proxy already designed.**
- **Q3.new-2**: What is the numerical **time-decay half-life** for training-row weights? 30 days is a first guess; an ablation study (two candidate half-lives: 14 vs 30 vs 60) would fit the implementation phase, not research.
- **Q3.new-3**: Is **Optuna-driven hyperparameter re-search on every weekly retrain wasteful**? The L2 plan says "50–100 trials" (005:331). At weekly cadence that's 50–100 × 52 = 2600–5200 trials/year of compute. Consider: re-search only on drift-triggered retrain; on scheduled retrain, freeze HPs and only refit on new data. **Optimization detail for implementation phase.**
- **Q3.new-4**: How does **feature-schema versioning** interact with the training set? If we add a new feature (say `reels_skip_rate` per iter-1), do we (a) retrain from scratch with v1.1 schema + shorter window, or (b) backfill the missing feature onto historical rows? Answer affects snapshot design. **Flag for iteration 7+ or implementation phase.**

## Ruled Out (this iteration)

- **Direct fetch of NannyML docs** (ReadTheDocs 403 + website 404): Do NOT retry NannyML ReadTheDocs via WebFetch — blocked. Use GitHub `NannyML/nannyml` README or PyPI project page next time.
- **Direct fetch of LightGBM ReadTheDocs** (403): Same block pattern. Future iterations should use GitHub `microsoft/LightGBM` README or `lightgbm` PyPI page.
- **MLflow registry docs page** (renders empty in WebFetch): JS-heavy SPA. Next time use `mlflow/mlflow` GitHub README or Python API docstrings via `help(mlflow.register_model)` simulation.
- **SMOTE for class imbalance on tabular LightGBM**: ruled out in favor of `sample_weight` / `scale_pos_weight` because Thompson Sampling downstream requires calibrated probabilities.
- **Daily retraining cadence**: ruled out — insufficient new labels due to T+168h label latency; weekly is structurally correct.
- **Feast/Tecton feature store**: ruled out for v1; Postgres + Prisma is sufficient until >50M rows.
- **Focal loss in LightGBM**: not standard; ruled out.

## Dead Ends (promote to strategy)

- **NannyML readthedocs.io + nannyml.com/blog under WebFetch**: structural 403/404 as of 2026-04-17. For NannyML-specific citations in future iterations, switch to GitHub or PyPI sources.
- **ReadTheDocs-hosted docs in general** (LightGBM, NannyML, and likely others): systematically blocked for our WebFetch client. Route around via alternate hosts.

## Sources Consulted

- https://docs.evidentlyai.com/metrics/all_metrics (preset naming)
- https://docs.evidentlyai.com/metrics/customize_data_drift (18+ algorithm menu, thresholds, column types) — **primary citation**
- https://docs.evidentlyai.com/metrics/preset_data_drift (auto-method selection, drift_share default)
- .opencode/specs/viral-ops/005-trend-viral-brain/research/research.md:307–356, 511 (L2 baseline)
- .opencode/specs/viral-ops/007-l7-feedback-loop/research/iterations/iteration-001.md:22–80 (API gaps)
- .opencode/specs/viral-ops/007-l7-feedback-loop/research/iterations/iteration-002.md §B, §D (Prisma schema, upsert)
- Memory packets: `project_trend_viral_brain.md` (38 features, LightGBM), `project_base_app_research.md` (Prisma 7.4, n8n 2.16)

## Assessment

- **New information ratio**: raw = `(8 new + 0.5 × 4 carry-over resolutions) / 12 = 0.83`; conservative = **0.80** due to several `[INFERENCE]` tags on NannyML/MLflow and LightGBM specifics blocked by 403.
- **Simplicity bonus**: +0 (no contradiction resolution this iteration; we upgraded L2's baseline without overturning it).
- **Net findings (this iteration)**: drift taxonomy (1), Evidently algorithm menu applied per column type (2), trigger decision matrix (3), label-latency-aware training gate (4), training feature snapshot schema (5), drift_events audit schema (6), MLflow shadow/canary rollout state machine (7), Python-worker + n8n split for training + drift jobs (8).
- **Questions addressed**: Q3 fully.
- **Questions answered**: Q3.
- **Final newInfoRatio**: **0.80**.

## Reflection

- **What worked and why**: Starting from the L2 38-feature baseline and only designing the *new* layers (drift channels, rollout state machine, snapshot pattern) avoided re-deriving what was already decided. Evidently's customize-drift page paid for itself — one fetch returned the entire 18-algorithm menu with thresholds. Cross-linking Evidently's auto-method to the L2 PSI>0.20 threshold gave a concrete upgrade path.
- **What didn't work and why**: ReadTheDocs blocks for NannyML and LightGBM cost 2 tool calls. Root cause is external (our fetch client is rejected by readthedocs). Should have predicted this based on iter-1's CocoIndex Windows failure pattern — both are "external-infra-blocks-our-client" dead ends.
- **What I would do differently**: Next time, when needing a library citation, fetch its GitHub README or PyPI page first (both render as static HTML) rather than ReadTheDocs. Adjust future iterations' fetch strategy.

## Recommended Next Focus

**Iteration 4 (Q4): 4-channel feedback loop to L3 Content Lab.** Specifically:
1. From the L3 spec (`006-content-lab/research/research.md`), what exactly are the 4 channels (engagement, retention, completion, conversion)? What metrics map into each?
2. Design the handoff contract: JSON schema of feedback events posted to L3; frequency (per-post vs batched); storage (ephemeral Kafka-style vs persisted `feedback_events` table).
3. Thompson Sampling update cadence: per-event or batched? How does L3 consume the GBDT prediction + L7 realized metrics?
4. Vanity-metric guardrails: which L7 signals are allowed to modify Thompson arm priors, and which are filtered out (e.g., crossposted_views may inflate without true engagement)?
5. Connection to the `drift_events` table: does concept drift on GBDT trigger a Thompson-arm reset, or is it quarantined to model-world only?

**Secondary**: Map `performance_metrics.retentionCurve` JSON → L3 prompt-tuning inputs (which curve shape triggers which prompt adjustment).

---

## Graph Events (for JSONL record)

```
nodes:
- drift/data_numerical (psi 0.20)
- drift/data_categorical (jensenshannon 0.1)
- drift/prediction (wasserstein 0.1)
- drift/label (psi 0.20)
- drift/performance (mae_delta 15%)
- drift/correlation (spearman 0.15)
- trigger/scheduled_weekly (cron 0 3 * * 0)
- trigger/drift_sustained_2d
- trigger/performance_immediate
- trigger/milestone_200_labels
- component/python_ml_trainer
- component/fastapi_inference
- component/n8n_drift_tick
- registry/mlflow
- db/training_feature_snapshots
- db/drift_events
- state_machine/shadow_canary_production_archived

edges:
- performance_metrics --feeds--> training_feature_snapshots
- training_feature_snapshots --feeds--> python_ml_trainer
- python_ml_trainer --registers--> mlflow
- mlflow --loads--> fastapi_inference
- fastapi_inference --writes_predictions--> training_feature_snapshots
- n8n_drift_tick --invokes--> python_ml_trainer
- python_ml_trainer --writes--> drift_events
- drift_events --gates--> trigger/drift_sustained_2d
- trigger/* --opens--> retrain_job
- mlflow --implements--> state_machine/shadow_canary_production_archived
```
