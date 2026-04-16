# Iteration 5: Prompt Tuning Automation — Closing the L7→L3 Loop (Q5 — FINAL KEY QUESTION)

## Focus

Design the prompt tuning automation pipeline: how performance feedback from L7 (via the 4-channel `L7FeedbackEnvelope` from iter-4) drives automated updates to L3 Content Lab prompt templates **without human-in-the-loop bottleneck** but with **safety rails against reward hacking, drift amplification, and vanity-metric chasing**.

This is the closing integration iteration. It must:

1. Specify the **prompt parameter registry** (what is tunable, what is locked).
2. Define a **generation-level A/B harness** (separate prompt experiments from content/trend experiments).
3. Design a **prompt-level meta-bandit** that composes with iter-4's content-level Thompson Sampling (nested bandits).
4. Specify **promotion / revert / canary safety rails** with explicit thresholds.
5. Integrate with **MLflow** (prompts as first-class artifacts alongside LightGBM models from iter-3).
6. Define **drift-coupling policy** (does L2 drift or L3 quality-flag spike pause prompt tuning?).
7. Decide **n8n topology** (7th workflow vs extension).
8. Cover **meta-concerns** (reward hacking on prompts, model collapse, Thai linguistic erosion).

Prior context this iteration leans on (do NOT re-derive):
- 4-channel signal dimensions + `L7FeedbackEnvelope` schema [SOURCE: iteration-004.md §A, §C].
- Beta-Binomial Thompson posterior at `(variant_id, platform)` granularity with `impressions_decile` scaling [SOURCE: iteration-004.md §D.2].
- 5 vanity-metric guardrails (rage, bot, clickbait, algo-boost, multi-dim sanity) [SOURCE: iteration-004.md §E].
- Drift-to-Thompson quarantine (not reset) policy [SOURCE: iteration-004.md §F.2].
- MLflow shadow→canary→Production→Archived state machine [SOURCE: iteration-003.md §8.5].
- L3 5-stage prompt chain + Stage 1 Structural / Stage 2 Hook / Stage 3 Arc / Stage 4 CTA / Stage 5 Delivery [SOURCE: 006-content-lab/research/research.md].
- L3's 4 update cadences (Few-Shot Exemplars per-gen / Template Selection weekly / Prompt Parameter Tuning monthly / Variant Strategy bi-weekly) [SOURCE: 006-content-lab §9].
- 20% ε-greedy exploration baseline, widened to 0.40 on drift [SOURCE: iteration-004.md §F.2, 006:553].

## Actions Taken

1. **Read state**: `deep-research-state.jsonl` (4 completed iterations), `deep-research-strategy.md` (Next Focus: Q5), `iteration-004.md` (Thompson arm granularity + envelope contract + guardrails), `research.md` §§1–9 (progressive synthesis). Confirmed Q5 is the final question; integration gaps to close are (a)→(i) per dispatch context.
2. **WebFetch — DSPy arXiv abstract** `https://arxiv.org/abs/2310.03714` — confirmed DSPy's programs-as-modules abstraction: "LM pipelines as text transformation graphs, imperative computational graphs where LMs are invoked through declarative modules"; parameterized modules "learn by creating and collecting demonstrations"; compiler "optimizes pipelines to maximize a given metric" and self-bootstraps. Full algorithm names (BootstrapFewShot, MIPRO, COPRO) and hyperparameters deferred to full PDF — flagged as **Q5.open-1**.
3. **WebFetch — OPRO arXiv abstract** `https://arxiv.org/abs/2309.03409` — confirmed meta-prompt loop: "each optimization step, the LLM generates new solutions from the prompt that contains previously generated solutions with their values, then the new solutions are evaluated and added to the prompt for the next optimization step". Reported 8% gain on GSM8K, up to 50% on BBH. Detailed hyperparameters (temperature, batch size, iterations) not in abstract — flagged as **Q5.open-2**.
4. **WebFetch — PromptBreeder arXiv abstract** `https://arxiv.org/abs/2309.16797` — confirmed dual-level evolution: population of **task-prompts** AND **mutation-prompts** co-evolve; "mutation of these task-prompts is governed by mutation-prompts that the LLM generates and improves throughout evolution in a self-referential way"; outperforms Chain-of-Thought and Plan-and-Solve on arithmetic/commonsense benchmarks. Detailed mutation operators and population sizes not in abstract — flagged as **Q5.open-3**.
5. **WebFetch — Pan et al. "Defining and Characterizing Reward Hacking" arXiv abstract** `https://arxiv.org/abs/2209.13085` — confirmed core definition: "optimizing an imperfect proxy reward function leads to poor performance according to the true reward function"; formal treatment of "unhackable proxies". Specific Pan/Krakovna taxonomy requires full PDF — noted as **Q5.open-4**; mitigation in this iteration grounded in the definitional framing + iter-4's multi-channel Goodhart guard already applied.

**Budget**: 4 Reads + 4 WebFetches + 3 Writes (iteration-005, JSONL append, research.md edit) = 11 tool calls. Under cap 12.

---

## Findings

### A. PROMPT PARAMETER REGISTRY (TUNABLE VS LOCKED)

The registry maps each L3 prompt-chain stage to a tunable surface and a lock-list. The **lock-list is the hard-blocker set** — no automated tuning may alter these under any circumstance (human-approval gate only).

#### A.1 Stage-by-Stage Tunability Matrix

| L3 Stage | Purpose | Auto-Tunable Parameters | Locked Parameters (human-only) |
|---|---|---|---|
| **Stage 1 — Structural** | Build variant skeleton (format, duration, sections) | `temperature` [0.3–0.9], `top_p` [0.7–1.0], section-ratio weights, duration-range soft-bounds | Hard duration cap per platform (TikTok 60s, IG Reels 90s, YT Shorts 60s), brand-voice anchors, legal disclaimer slots |
| **Stage 2 — Hook** | First-3s opener | `hook_type_weights` (question / contrarian / statistic / story-in-3s), `emotional_tone_weights` (curiosity / surprise / outrage / humor), `few_shot_count` [3–12], `few_shot_selection_policy` | Clickbait blacklist phrases, profanity filter, defamation guards, Thai royal-speech restriction set |
| **Stage 3 — Arc** | Body / narrative escalation | `arc_pattern_weights` (problem-solution / list / story-arc / reveal), `pacing_profile` (fast / medium / slow), beat-count target | Factual-claim verification slots, legal boilerplate, accessibility caption-length floor |
| **Stage 4 — CTA** | Closing call-to-action | `cta_intensity` [0.2–0.9], `cta_type_weights` (follow / save / share / comment / watch-again), `cta_placement` (pre-reveal / post-reveal / both) | Platform-compliance CTA language (no "link in bio" spam triggers per TikTok ToS), subscribe-language locked to channel policy |
| **Stage 5 — Delivery** | XML/JSON handoff to TTS and A/V pipelines | `xml_tag_nesting_depth` [2–4], tag-name aliases (whitelisted set), JSON-schema optional-field inclusion | Required schema fields (content_id, variant_id, tts_engine, voice_id, segment_timestamps), Thai language/particle tags, safety metadata |

**Why lock these**: the locked parameters protect (a) **legal/compliance surface** (disclaimers, royal speech, copyright), (b) **brand identity invariants** (voice tone), (c) **pipeline contract invariants** (downstream A/V handoff breaks if schema changes), and (d) **platform ToS obligations**. Automated optimization on these is catastrophic failure mode — legal drift or pipeline breakage that optimizer cannot observe.

**Cross-cutting tunables** (apply to all stages): `system_prompt_wording_variants` (whitelisted set of 3–5 pre-approved rephrasings per stage), `chain_thought_disclosure` (show reasoning / hide reasoning), `self_critique_enabled` [bool].

#### A.2 Prisma Schema: `prompt_template_versions`

```prisma
model PromptTemplateVersion {
  id                    String   @id @default(cuid())
  stage                 PromptStage // STRUCTURAL | HOOK | ARC | CTA | DELIVERY
  versionTag            String   @unique   // semver-like e.g. "hook-v2.3.1"
  parentVersionId       String?  // provenance chain (fork from)
  isLocked              Boolean  @default(false) // true = lock-listed, auto-tuner cannot modify
  parametersJson        Json     @db.JsonB     // tunable surface (temperature, weights, etc.)
  systemPromptBody      String   @db.Text      // full system prompt text
  fewShotExemplarRefs   String[] // FK cuids to exemplar pool
  createdAt             DateTime @default(now())
  createdBy             String   // "auto-tuner" | "human:user_id"
  mlflowRunId           String?  // MLflow experiment run ID (prompt-as-artifact)
  lifecycleState        PromptLifecycle // PROPOSED | SHADOW | CANARY | PRODUCTION | ARCHIVED | REVERTED
  promotedAt            DateTime?
  retiredAt             DateTime?
  retiredReason         String?
  @@index([stage, lifecycleState])
  @@index([versionTag])
  @@map("prompt_template_versions")
}

enum PromptStage     { STRUCTURAL HOOK ARC CTA DELIVERY }
enum PromptLifecycle { PROPOSED SHADOW CANARY PRODUCTION ARCHIVED REVERTED }
```

The `lifecycleState` mirrors iter-3's MLflow model stages (shadow → canary → production → archived) — identical state machine for consistency. `parentVersionId` lets us audit which prompt evolved from which, enabling fork-trees for PromptBreeder-style evolutionary exploration [SOURCE: https://arxiv.org/abs/2309.16797 — task-prompt population with lineage].

### B. A/B HARNESS AT GENERATION LEVEL (NOT CONTENT LEVEL)

**Confounding problem**: if we A/B two prompt versions on a live content calendar, prompt v2 may appear to win purely because its generations landed on a better trend cohort (trend velocity / niche / platform mix). Prompt changes must be **cohort-matched** against content changes.

#### B.1 Separation Principle — Three Experiment Layers

| Layer | Experiment Object | Randomization Unit | Arm Definition | Thompson Sampler | Cadence |
|---|---|---|---|---|---|
| **L3a — Content** | Creative variant (9 per concept per 006 3x3) | `(concept_id, variant_id, platform)` | iter-4 `(variant_id, platform)` | Per-variant Beta-Binomial (iter-4) | Per-post |
| **L3b — Template** | Prompt template version within a stage | `(stage, template_version_id)` | Per-`PromptTemplateVersion` row | **Meta-bandit** (§C) over template versions per stage | Per-generation |
| **L3c — Parameter** | Parameter sweep inside a fixed template | Parameter vector within template | Hyperparameter grid / Bayesian optimizer | OPRO-style iterative score-guided sampler | Weekly |

Critical rule: **L3a, L3b, L3c randomize at different units, so their signals are not confounded**. iter-4's Thompson learns which creative variant wins; L3b's meta-bandit learns which prompt template wins; L3c learns which parameter vector wins **within** a template.

#### B.2 Within-Concept Cohort Matching (anti-trend-confound)

For every prompt-template A/B experiment, require:

1. **Same-concept bilateral sampling**: each concept generated in the experiment window MUST produce both a v1 and a v2 variant when resources allow, so both prompt versions hit the same trend timestamp and niche context.
2. **Cohort stratification**: if bilateral sampling is not feasible (latency, budget), stratify by `(niche, trend_velocity_bucket, platform, account_tier)` and allocate prompt versions **proportionally within strata** — not globally randomized.
3. **Minimum cohort overlap**: require ≥60% cohort-overlap in `(niche, platform, age_bucket)` between v1 and v2 populations before a comparison is declared valid. If <60%, mark the experiment `INCONCLUSIVE_COHORT_SKEW` and extend the run window.
4. **Trend-velocity matching**: use L2 trend-velocity scores (005 GBDT feature) as a covariate; include it in the Welch/Bayesian analysis to absorb trend-driven variance. [INFERENCE: iter-3's 38-feature LightGBM vector includes trend_velocity — details in 005 research; confirm in implementation phase.]

#### B.3 Sample Size & Statistical Test

- **Success metric**: the L7 4-channel composite score (percentile-rank, [0,1]) from iter-4's `L7FeedbackEnvelope.aggregate_score`. One composite per envelope at `time_window = T+7d`.
- **Power analysis target**: detect a minimum-effect-size of Δ=0.05 on composite score with α=0.05, power=0.80. Using a two-sample Welch's t-test approximation with σ≈0.20 (percentile-rank variance on 4-channel mix), minimum sample ≈ **126 envelopes per arm** [INFERENCE: Welch approximation, confirm with implementation-phase power tool such as `statsmodels.stats.power.TTestIndPower`].
- **Primary test**: **Welch's t-test** (unequal variances, robust) on composite score z-scored by cohort (to remove niche/platform/trend-velocity main effect).
- **Secondary test — Bayesian A/B**: Beta(α, β) posterior over "v2 > v1" probability with Beta(1,1) uniform prior, updated with Thompson-style sampling; stop when `P(v2 > v1 | data) ≥ 0.95` AND lift ≥ 5%.
- **Multi-metric sanity**: the win condition requires EITHER Welch p<0.05 AND no channel regresses >1σ, OR Bayesian `P(v2 > v1) ≥ 0.95` AND no channel regresses >1σ. Anti-Goodhart: single-channel blowout without 3 other channels holding is NOT a win. [SOURCE: iteration-004.md §E.5 multi-dim sanity gate, reused at prompt-experiment level.]

#### B.4 Guardrail Channel Veto

Even if composite wins, if quality-flag incidence changes significantly between v1 and v2, the experiment is vetoed:

```
reject_v2 if
  rage_flag_rate_v2 - rage_flag_rate_v1 > 0.05   OR
  clickbait_flag_rate_v2 - clickbait_flag_rate_v1 > 0.05  OR
  bot_flag_rate_v2 - bot_flag_rate_v1 > 0.03    OR
  (any channel z-score regression > -1σ)
```

These gates ensure a winning prompt does not covertly convert to a rage/clickbait/bot-attracting style while scoring high on composite. [SOURCE: Goodhart's Law mitigation, https://en.wikipedia.org/wiki/Goodhart%27s_law + iter-4 §E guardrails.]

### C. META-BANDIT ON PROMPT VARIANTS (NESTED BANDITS)

#### C.1 Nested Architecture

```
┌───────────────────────────────────────────────────────────────┐
│ META-BANDIT (L3b — per-stage prompt-template selection)       │
│   arms = PromptTemplateVersion rows with lifecycleState       │
│          in (CANARY, PRODUCTION)                              │
│   reward = average composite score of all variants generated  │
│            by this template in last window                    │
│   algorithm = Thompson Sampling (Beta-Binomial, same family   │
│               as iter-4's content-level bandit)               │
└───────────────────────────────┬───────────────────────────────┘
                                │ selects template for generation
                                ▼
┌───────────────────────────────────────────────────────────────┐
│ INNER BANDIT (L3a — per-variant Thompson from iter-4)          │
│   arms = (variant_id, platform) tuples from 3x3 expansion     │
│   reward = composite from L7FeedbackEnvelope.aggregate_score  │
│   algorithm = Beta-Binomial with impressions_decile scaling   │
└───────────────────────────────────────────────────────────────┘
```

#### C.2 Algorithm Choice — Thompson, Not UCB

Thompson Sampling is chosen for the meta-bandit for **three reasons**:

1. **Consistency with iter-4**: content-level is already Thompson (Chapelle & Li 2011 Beta-Binomial). Using the same family at meta-level keeps posterior semantics uniform and enables shared monitoring/visualization tooling.
2. **Better handling of delayed feedback**: prompt-level rewards arrive at T+7d (stable window per iter-4 §B.1); UCB1's deterministic exploration term does not adapt to delayed observations as gracefully as Thompson's randomized posterior draws. [INFERENCE: delayed-feedback Thompson variants (Vernade 2017, Grover 2018) are more mature than delayed-UCB; verify in implementation.]
3. **Natural cold-start**: Beta(1,1) uniform prior for a newly-proposed prompt version mirrors iter-4's new-variant bootstrap. Consistent developer mental model.

#### C.3 Double-Counting Prevention (Credit-Attribution Rule)

If prompt v2 "wins" at meta-level, we must not double-count v2's gains by also inflating the inner content-Thompson posteriors. The fix is **per-envelope credit attribution**:

```
Each envelope already carries variant_id, which uniquely identifies the parent
(concept_id, stage_prompt_version_ids[]). When updating posteriors:

  inner Thompson (L3a): update (variant_id, platform) Beta posterior
                         with composite and impressions_decile   [iter-4 rule]
  meta Thompson (L3b): for each stage in this variant's lineage,
                        update (stage, template_version_id) Beta posterior
                        ALSO with composite and impressions_decile
```

The inner bandit's reward is **not divided**; the meta bandit's reward is **not compounded**. Both posteriors observe the same reward signal with the same virtual-trial weight, but they partition the arm space differently (variant vs template). This is the standard nested-bandit pattern [INFERENCE: nested-bandit literature (Slivkins 2019, Lattimore & Szepesvári 2020); formal citation deferred to Q5.open-5].

#### C.4 Reward Signal Definition at Meta-Level

```
For each PromptTemplateVersion tv in stage s:
  relevant_envelopes(tv) = envelopes where tv ∈ variant.stage_prompt_version_ids
                            AND readyForThompson = true
                            AND no CRITICAL quality_flag
  reward_stream(tv) = [envelope.aggregate_score.composite for envelope in relevant_envelopes(tv)]
  Beta update:
    α_{tv,t+1} = α_{tv,t} + Σ (r × impressions_decile) over reward_stream new since last update
    β_{tv,t+1} = β_{tv,t} + Σ ((1-r) × impressions_decile) over reward_stream new since last update
```

The CRITICAL-flag filter ensures rage/bot/sanity-gate envelopes do NOT contribute to meta-level scoring — a prompt that generates rage-bait cannot get posterior credit even if composite is high. This is the structural reward-hacking defense at the prompt level.

#### C.5 Per-Stage Independence

Each of the 5 stages (Structural / Hook / Arc / CTA / Delivery) runs its **own independent meta-bandit**. This is correct because (a) each stage has a different tunable surface (§A.1), (b) stages are drawn in sequence during generation and each selection is a separate choice, and (c) independent stage-bandits prevent catastrophic joint-failure (one bad stage version poisoning the whole chain).

### D. SAFETY RAILS — PROMOTION, REVERT, CANARY

#### D.1 Canary Rollout (Shadow → Canary → Production)

Mirrors iter-3's MLflow model canary, applied to prompt versions:

| Phase | Traffic % | Duration | Success Gate | Failure Gate |
|---|---|---|---|---|
| **SHADOW** | 0% (scored alongside, not served) | 24h | Emits ≥50 synthetic scores via offline evaluation on replay set | Evaluation harness error, schema mismatch |
| **CANARY** | 5% of generations in stage | 72h | Composite ≥ PROD composite − 0.02, no flag-rate regression > §B.4 thresholds, no guardrail critical | Composite drop > 0.05 OR flag-rate regression OR guardrail critical |
| **PRODUCTION (partial)** | 25% | 7d | ≥126 envelopes, Welch p<0.05 OR Bayesian P(win)≥0.95, all 4 channels hold | Composite drop in any 48h window > 0.05 |
| **PRODUCTION (full)** | 100% | permanent until superseded | meta-bandit posterior mean > previous PROD by ≥0.02 | auto-revert on D.2 criteria |

Each transition runs automatically; human approval is required only to (a) add a new PROPOSED version (author gate), (b) override an auto-revert (escalation gate).

#### D.2 Auto-Revert Triggers

Active Production prompt auto-reverts to previous Archived PRODUCTION if ANY fires:

```
1. Single-channel regression:   any channel mean z-score drops > 1σ over 48h window
2. Composite regression:         composite drop > 0.05 over 7d window vs prior PROD baseline
3. Quality flag spike:           rage_flag_rate or clickbait_flag_rate increase > 0.05 absolute over 48h
4. Drift escalation:             drift_events.severity=CRITICAL (PREDICTION or PERFORMANCE) per iter-3
5. Multi-dim sanity failure:     iter-4 §E.5 triggered on > 10% of envelopes over 48h
```

Revert is atomic (same pattern as iter-3 MLflow: PROD version moves to ARCHIVED/REVERTED, previous ARCHIVED promoted to PROD). The reverted version gets `retiredReason` populated and is **locked from re-promotion for 14 days** (cool-down; prevents oscillation).

#### D.3 Human-in-Loop Escape Hatch (Force-Freeze)

A single feature flag `L3_AUTO_TUNE_FROZEN` pauses ALL meta-bandit updates, ALL new prompt promotions, and holds the current PROD prompt set indefinitely. Activated by:

- Manual operator action (incident response).
- Drift coupling policy (§F below).
- L7 envelope CRITICAL flags exceeding baseline by >2x for 24h (auto-activated safeguard).

When frozen, the system still serves the current PROD prompts and still ingests envelopes for analytics/audit, but posterior updates pause and new-version proposals queue without activating. This is the **circuit-breaker pattern** — safer than trying to self-correct a thrashing auto-tuner.

#### D.4 Promotion Criteria (summary decision matrix)

| Gate | Threshold | Rationale |
|---|---|---|
| Sample size | ≥126 envelopes per arm | Welch power analysis for Δ=0.05 at σ=0.20 |
| Statistical test | Welch p<0.05 OR Bayesian P(win)≥0.95 | Dual-test robustness |
| Composite gain | Δcomposite ≥ 0.02 (meta-bandit posterior mean delta) | Practical significance floor |
| Channel non-regression | No channel z-score drop > 1σ | Multi-metric Goodhart guard |
| Flag non-regression | rage/clickbait flag rate delta ≤ 0.05 | Anti-reward-hacking guard |
| Trend coverage | ≥3 distinct trend_ids in the win cohort | Prevents single-trend overfit |
| Drift quiescence | drift_events severity ≠ CRITICAL during experiment | Don't promote during model drift |

All gates must pass for auto-promotion. If 6 of 7 pass, queue for human review rather than auto-revert.

### E. MLFLOW INTEGRATION — PROMPTS AS FIRST-CLASS ARTIFACTS

[SOURCE: iteration-003.md §8.5 — MLflow shadow/canary/production/archived state machine.]

#### E.1 Experiment Structure

```
MLflow experiment tree:
  viral-ops/
  ├── models/
  │   └── viral-gbdt           (iter-3: LightGBM versions)
  └── prompts/
      ├── structural            (Stage 1 versions)
      ├── hook                  (Stage 2 versions)
      ├── arc                   (Stage 3 versions)
      ├── cta                   (Stage 4 versions)
      └── delivery              (Stage 5 versions)
```

Each `PromptTemplateVersion` row has an `mlflowRunId` FK into the MLflow run, which stores:
- **Params**: `parametersJson` from the Prisma row (temperature, weights, few-shot count, etc.).
- **Artifacts**: the full `systemPromptBody` text, `fewShotExemplarRefs` blob, and the rendered messages JSON.
- **Metrics**: rolling composite score, per-channel means, flag rates, sample size, posterior α/β at observation time.
- **Tags**: `l2_model_version` (which GBDT version generated the training signal), `lifecycleState`, `parent_version_tag`, `stage`.

#### E.2 Reproducibility Rule — Version Triples

Every L7FeedbackEnvelope is joined at consumption time with a **version triple** for reproducibility:

```
reproducibility_triple = (
  l2_model_version,                   // viral-gbdt-vX.Y.Z
  l3_prompt_version_chain,            // [structural-v1.3, hook-v2.1, arc-v1.0, cta-v1.5, delivery-v1.0]
  content_lab_code_sha                // L3 generator git SHA
)
```

Given any piece of content, a single join query answers: "which model + which prompt chain + which code generated this?" This is the **lineage guarantee** that iter-3's MLflow registry provides at model level, now extended to prompts.

#### E.3 Prompt Artifact Serialization

Prompts are serialized as JSON manifest + raw text blobs:

```json
{
  "manifest_version": "1.0",
  "stage": "hook",
  "version_tag": "hook-v2.3.1",
  "parent_version_tag": "hook-v2.2.4",
  "parameters": { "temperature": 0.7, "few_shot_count": 6,
                  "hook_type_weights": {"question": 0.3, "contrarian": 0.3, "statistic": 0.2, "story": 0.2},
                  "emotional_tone_weights": {"curiosity": 0.4, "surprise": 0.3, "outrage": 0.05, "humor": 0.25} },
  "system_prompt_path": "prompts/hook/hook-v2.3.1/system.md",
  "few_shot_exemplar_refs": ["exemplar:a7f3...", "exemplar:b2c1...", ...],
  "lock_list_fingerprint": "sha256:...",
  "thai_particle_guard": "enabled:003-thai-voice-pipeline",
  "created_by": "auto-tuner:opro-v1",
  "created_at": "2026-04-17T14:32:00Z"
}
```

The `lock_list_fingerprint` is a SHA-256 of the lock-listed portions of the stage template. If the auto-tuner ever produces a version whose lock-listed section differs from the baseline, fingerprint mismatch aborts registration — **structural lockout enforcement** at serialization time.

### F. DRIFT COUPLING POLICY

The question: when L2 GBDT drift fires (iter-3) or L7 quality-flag spike fires (iter-4), should prompt tuning also pause?

#### F.1 Policy Decision Matrix

| Upstream Signal | Prompt-Tuning Action |
|---|---|
| `drift_events.severity=CRITICAL` (PREDICTION or PERFORMANCE) | **Freeze meta-bandit updates; no new prompt promotions; existing PROD prompts stay active.** Same policy as iter-4's Thompson quarantine — consistency principle. |
| `drift_events.severity=CRITICAL` (FEATURE or LABEL) | **Reduce canary traffic from 5% → 1%, extend canary window 72h → 168h, otherwise continue.** Feature/label drift is upstream and prompts may NOT be the cause; don't fully freeze. |
| `drift_events.severity=CRITICAL` (CORRELATION) | **Full freeze.** Correlation drift indicates LLM-dimension rubric breakdown; any prompt tuning in this state is reinforcing a broken correlation structure. |
| Quality-flag spike (rage/clickbait/bot > 2x baseline) | **Quarantine meta-bandit: pause posterior updates on affected stage (hook or cta most likely); force-revert latest CANARY promotion in that stage.** |
| Multi-dim sanity-gate failure spike | **Widen meta-bandit ε (0.10 → 0.30) for exploration; do NOT freeze — structural guard is already active at envelope level.** |
| `L3_AUTO_TUNE_FROZEN` manual flag | **Full freeze on everything (see §D.3).** |

#### F.2 Rationale — Why Not "Tuning Is The Fix"

A naive argument: "if the model is drifting, let the auto-tuner find better prompts to fix it." This is **rejected** for three reasons:

1. **Stale reward signal**: during drift, the L7 envelopes reflect a world the L2 scorer no longer models accurately. Meta-bandit updates based on stale composites converge on a local optimum that **will not survive the drift resolution** — tuning effort is wasted.
2. **Feedback amplification risk**: a drifting L2 can mis-score content, which biases envelope composites, which biases prompt selection, which generates content targeting the biased signal, which further entrenches the drift. This is the **auto-tuner amplification loop** — explicit Goodhart at the prompt level.
3. **Recovery order**: the correct recovery is (a) L2 retraining completes per iter-3 weekly floor or drift-triggered ceiling, (b) L2 new model passes canary, (c) prompt auto-tuner resumes with fresh signal. Parallelism here is an anti-pattern.

[SOURCE: analogous reasoning to iter-4 §F.2 drift-to-Thompson quarantine; same structural argument applied at prompt layer.]

#### F.3 Resumption Protocol

On `drift_events.resolvedAt IS NOT NULL` + post-drift new model reaches Production:
1. Clear quarantine flag on all stages.
2. **DO NOT reset** meta-bandit posteriors (keep history for post-resolution analysis — same quarantine-not-reset doctrine as iter-4).
3. Widen ε to 0.30 for first 7d post-resume to re-explore (analog to iter-4 ε widen).
4. Emit `DriftEvent.resolution = "auto-tuner resumed"` for audit.
5. Run a one-shot regression test: compare current PROD prompts' composite under NEW L2 model vs their composite pre-drift. If Δ > 0.1 degradation, downgrade PROD to CANARY and let meta-bandit re-select.

### G. n8n TOPOLOGY — EXTEND L3-FEEDBACK-AGGREGATOR OR ADD L7-PROMPT-TUNER?

**Decision: ADD new 7th workflow `L3-Prompt-Tuner` on the L3 side.**

#### G.1 Rationale

- **Separation of concerns**: L3-Feedback-Aggregator (from 006:614, modified by iter-4) already aggregates envelopes and pushes to content-level Thompson. Adding prompt-level meta-bandit logic bloats it and mixes two reward-attribution contexts.
- **Different cadence**: feedback aggregation runs hourly (aligned with pollAgeBucket transitions, iter-4 §F.3). Prompt tuning should run on longer cadence (daily for meta-bandit posterior refresh, weekly for canary→PROD transitions).
- **Independent failure domain**: prompt-tuner failure must not break content-variant feedback aggregation. Separate workflows give separate error handling.

#### G.2 Workflow `L3-Prompt-Tuner` Specification

```
Schedule: Cron 0 4 * * * (daily, 04:00 UTC — offset 1h from L3-Feedback-Aggregator Sun 03:00 UTC)
Triggers:
  - scheduled (primary)
  - event-driven: drift_events.severity=CRITICAL (immediate pause/resume)
  - event-driven: quality_flag spike >2x baseline (immediate quarantine)

Steps:
  1. Check L3_AUTO_TUNE_FROZEN flag → if true, exit with status='frozen'
  2. Query recent L7FeedbackEnvelopes since last run:
       WHERE readyForThompson = true
       AND emittedAt > last_prompt_tuner_runAt
       AND no CRITICAL quality_flag
  3. For each envelope, join to variant.stage_prompt_version_ids (5 stages)
  4. For each (stage, template_version_id) pair in the window:
       - update Beta(α,β) posterior with composite and impressions_decile
       - persist in prompt_template_versions.thompsonPosteriorJson
  5. Check promotion criteria (§D.4) for each CANARY version per stage:
       - if pass: atomic transition CANARY→PRODUCTION, archive prior PROD
       - if fail-soft (6/7 gates): enqueue human review task
       - if fail-hard: mark REVERTED, start cool-down
  6. Check auto-revert triggers (§D.2) on current PROD prompts
  7. Emit L3PromptTuneEvent rows for audit
  8. Slack alert on promotions, reverts, or freeze transitions
  9. Sync to MLflow: update metrics on live runs, close completed runs
```

#### G.3 Total L7/L3 Workflow Count After iter-5

| Owner | Workflows |
|---|---|
| **L7 (ingestion + feedback)** | 3: polling-cron (iter-2) + drift_detection_tick (iter-3) + L7-Feedback-Emitter (iter-4) |
| **L3 (generation + tuning)** | 7: L3-Content-Generator, L3-Script-Generator, L3-Content-Calendar, L3-Retry-Failures, L3-Feedback-Aggregator (all 006), **L3-Prompt-Tuner (new iter-5)**, plus the AV pipeline workflow |
| **Total** | 10 |

#### G.4 Event-Driven Topology Detail

The primary cadence is cron-daily, but two event triggers shortcut the schedule:

1. **Drift escalation hook**: iter-3's drift_detection_tick, on `CRITICAL`, fires a synchronous HTTP call to L3-Prompt-Tuner's `/pause-endpoint` in addition to logging the DriftEvent. Idempotent; multiple CRITICAL events don't stack.
2. **Quality-flag spike hook**: L7-Feedback-Emitter (iter-4), when rage/clickbait/bot flag rate in a 6h window exceeds 2x the 30d baseline, fires `/quarantine-stage?stage={hook|cta|...}` on L3-Prompt-Tuner.

Both hooks are **one-way** into the tuner — pause/quarantine state persists until explicit resume.

### H. META-CONCERNS (THE THINGS THAT WILL BITE US)

#### H.1 Prompt-Level Goodhart — Reward Hacking On Prompts

Auto-tuning a prompt against a composite score has three known failure modes:

1. **Outrage convergence**: over many iterations, the tuner biases hook_type_weights toward `outrage` and `contrarian` because these generate high engagement. The Goodhart guard is iter-4's 5-flag guardrail, but only if flag rates are monitored with meta-bandit veto (§D.2 trigger 3 handles this). **Residual risk**: subclinical rage content that doesn't cross the 0.60 negative-sentiment threshold but still erodes brand over months. **Mitigation**: periodic human-review sampling of top-scoring prompts at monthly cadence; L7-Prompt-Quality-Review is a deferred workflow [Q5.deferred-1].

2. **Clickbait drift**: tuner converges on hooks that maximize `1 - reels_skip_rate` without completion follow-through. iter-4 §E.3 already flags this at envelope level; meta-bandit reward filter (§C.4 CRITICAL-flag exclusion) prevents posterior credit. **Residual risk**: clickbait that just barely passes the 0.25 completion floor but is obviously bait. **Mitigation**: long-tail completion metric (T+30d, not T+7d) as secondary meta-bandit signal [deferred to implementation phase].

3. **Vanity convergence**: tuner maximizes impressions without conversion. iter-4 §E.5 multi-dim sanity gate + §D.4 channel non-regression gate handle this structurally. Robust.

#### H.2 Model Collapse — Training-Generation-Training Loop

If the LightGBM L2 scorer is trained on labels from content L3 generated, and L3 prompts are tuned on L2-scored-envelope composites, there is a **closed loop**: `L3 generates → L2 scores → L7 envelopes → L3 meta-bandit updates prompts → L3 generates more narrowly`.

Long-term risk: diversity collapse. The system converges on a narrow distribution of "safely-scoring" content, losing the long tail that drives actual virality on Thai TikTok (where novelty is the primary L2 feature per 005).

**Mitigations** (layered):

1. **Forced exploration floor** — ε-greedy at 10% (baseline) and widened to 30% on drift (§F.1). This guarantees 10% of generations come from non-winning prompts regardless of posterior mass.
2. **Exemplar diversity constraint** — few-shot exemplar selection in §A.1 requires a **diversity quota** (≥30% exemplars must come outside the top-10% performer pool). Prevents exemplar-pool collapse to a single aesthetic.
3. **Trend novelty injection** — iter-3 L2's trend-velocity feature. Prompts that only score on established trends (low trend-velocity) are demoted regardless of composite. This keeps novelty as a structural input. [INFERENCE: implementation-phase work; tie to L2 feature 005-trend-viral-brain.]
4. **Human exemplar injection** — quarterly review where operators inject 5–10 new hand-crafted exemplars into the pool, guaranteed included in few-shot selection with minimum-use quota. Keeps human taste in the loop.

#### H.3 Thai Linguistic Nuance Erosion

A generic auto-tuner may converge on Thai-language patterns that read well on composite but erode:

- **Particle usage** — Thai discourse particles (ครับ / ค่ะ / นะ / แหละ / หรอก / เล่ย / จ้า) carry subtle pragmatic weight [SOURCE: MEMORY.md project_thai_voice_pipeline — 60+ Thai particles tracked].
- **Formality registers** — royal speech, polite speech, colloquial, slang; mis-registration is a brand risk.
- **Code-switching patterns** — Thai-English code-switching norms vary by niche (tech vs lifestyle vs food).

**Mitigations**:

1. **Locked particles list** — lock-listed as per §A.1 Hook row. The auto-tuner cannot alter particle selection logic; only the expression around particles is tunable.
2. **Formality register as lock-listed parameter** — formality target is a hard-coded brand policy, not a tunable weight. Auto-tuner sees it as read-only.
3. **Thai-linguist review slot** — every quarter, a Thai-language human reviewer samples 50 auto-generated outputs across stages and scores linguistic fit; if score drops >10% quarter-over-quarter, force-freeze is auto-activated (§D.3).
4. **PyThaiNLP validator** — every prompt version passes a pre-canary gate: generate 20 sample outputs, run PyThaiNLP tokenizer + particle-validator, require ≥95% Thai-grammatical parse rate. Failures block promotion. [SOURCE: MEMORY.md project_thai_voice_pipeline — PyThaiNLP mandatory.]

#### H.4 Citations Framework — DSPy / OPRO / PromptBreeder Applicability

| Paper | Applicable To viral-ops | How |
|---|---|---|
| **DSPy** (Khattab et al. 2023, arxiv 2310.03714) | L3 pipeline architecture | Treat Stage 1–5 prompt chain as DSPy modules with `Signature` contracts; enable DSPy's BootstrapFewShot to auto-select few-shot exemplars as the inner tuner for `few_shot_exemplar_refs` in §A.1. MIPRO/COPRO compilers for joint-optimization of parameters + exemplars. [SOURCE: https://arxiv.org/abs/2310.03714 abstract — "compiler optimizes pipelines to maximize a given metric"] |
| **OPRO** (Yang et al. 2023, arxiv 2309.03409) | L3c parameter-layer tuning | Use OPRO's meta-prompt loop ("solution + score" accumulating history) to iterate on prompt-parameter vectors within a fixed template. Reported 8% GSM8K / up to 50% BBH gains [SOURCE: https://arxiv.org/abs/2309.03409 abstract]. |
| **PromptBreeder** (Fernando et al. 2023, arxiv 2309.16797) | L3b template-layer exploration | Evolutionary task-prompt + mutation-prompt co-evolution for proposing new `PromptTemplateVersion` candidates before they enter SHADOW. Self-referential mutation matches our `parent_version_tag` lineage [SOURCE: https://arxiv.org/abs/2309.16797 abstract — "task-prompts + mutation-prompts co-evolve, self-referential"]. |
| **Pan et al. 2022** (arxiv 2209.13085) | Reward-hacking framing | Grounds §H.1–H.3 — "optimizing an imperfect proxy reward function leads to poor performance according to the true reward function" [SOURCE: https://arxiv.org/abs/2209.13085 abstract]. All three meta-concerns are instances of imperfect-proxy failure. |

#### H.5 Implementation Sequencing Recommendation

Given DSPy/OPRO/PromptBreeder complexity, phase the rollout:

- **Phase 1 (MVP)**: Manual prompt versions + meta-bandit on 2–3 human-authored versions per stage. No DSPy/OPRO/PromptBreeder yet; focus on envelope plumbing, meta-bandit math, safety rails.
- **Phase 2**: Add OPRO-style parameter sweep (§L3c) within a fixed template. Lowest-risk automated tuning.
- **Phase 3**: Add DSPy signature wrapper around the 5-stage chain; BootstrapFewShot for few-shot exemplar selection.
- **Phase 4**: Add PromptBreeder-style evolutionary proposer for new template versions (into PROPOSED state). Requires the strongest guardrails; rolls out only after Phase 1–3 are stable.

---

## Open Questions

- **Q5.open-1**: DSPy specific algorithm hyperparameters (BootstrapFewShot max_bootstrapped_demos, MIPRO num_candidates, COPRO temperature schedule) — abstract insufficient, need full PDF. Defer to implementation phase.
- **Q5.open-2**: OPRO iteration budget, temperature, meta-prompt template concrete example — abstract insufficient. Defer to implementation phase (Google DeepMind repo has code).
- **Q5.open-3**: PromptBreeder population size, mutation operator set, fitness function formula — abstract insufficient. Defer to implementation phase.
- **Q5.open-4**: Pan et al. + Krakovna et al. specific reward-hacking taxonomy labels — abstract confirms definitional framing; formal category labels deferred.
- **Q5.open-5**: Nested-bandit formal convergence guarantees (Slivkins, Lattimore & Szepesvári) — not fetched this iteration; implementation can proceed on Thompson+Thompson composition since both are consistent-family posterior updates.
- **Q5.deferred-1**: L7-Prompt-Quality-Review human-sampling workflow — scoped as future work but NOT blocking research convergence.
- **Q5.deferred-2**: Exact Thai-linguist sampling cadence and PyThaiNLP validator rule-set — ties into 003-thai-voice-pipeline; implementation spec.

## Ruled Out (this iteration)

- **Single global bandit across all stages** — rejected; each stage has different tunable surfaces and sequential decisions, and a global arm space collapses the action-credit problem.
- **UCB1 for meta-bandit** — rejected; less robust under delayed feedback than Thompson, and inconsistent with iter-4's Beta-Binomial inner bandit.
- **Extending L3-Feedback-Aggregator instead of new L3-Prompt-Tuner workflow** — rejected; mixes reward-attribution contexts and couples failure domains.
- **Letting auto-tuner continue during L2 drift** — rejected on stale-signal and amplification-loop grounds (§F.2).
- **Resetting meta-bandit posteriors on drift** — rejected for the same quarantine-not-reset reason as iter-4 (history needed for post-drift rollback comparison).
- **Allowing auto-tuner to modify locked parameters** — rejected categorically; lock-list is a hard safety boundary (compliance, brand, pipeline contract, platform ToS).
- **Tuning prompt + content simultaneously without cohort matching** — rejected due to confounding (§B.1 separation principle).
- **Single-channel win as promotion criterion** — rejected on multi-dim Goodhart guard (§D.4).
- **No cool-down after revert** — rejected; oscillation risk; 14d cool-down required.
- **Using Welch alone without Bayesian sanity** — rejected; dual-test robustness required for 5% traffic commitments.

## Dead Ends (promote to strategy)

- **arxiv abstract pages as sole source for full hyperparameters** — abstracts confirm concepts but not hyperparameter detail. Future iterations should WebFetch the PDF rendering or fetch the GitHub repos (Google DeepMind OPRO, Stanford DSPy, DeepMind PromptBreeder) when hyperparameter depth is required.
- **Hoping one meta-bandit family covers 3 experiment layers** — requires separation into L3a (content), L3b (template), L3c (parameter) with different units of randomization.

## Sources Consulted

- https://arxiv.org/abs/2310.03714 (DSPy — modules-as-programs, compiler-optimizes-metric)
- https://arxiv.org/abs/2309.03409 (OPRO — meta-prompt loop, 8%/50% GSM8K/BBH gains)
- https://arxiv.org/abs/2309.16797 (PromptBreeder — dual-level evolution, self-referential mutation)
- https://arxiv.org/abs/2209.13085 (Pan et al. — reward hacking definitional framing)
- https://en.wikipedia.org/wiki/Goodhart%27s_law (Goodhart mitigation — carry-over grounding from iter-4)
- https://proceedings.neurips.cc/paper/2011/file/e53a0a2978c28872a4505bdb51db06dc-Paper.pdf (Chapelle & Li 2011 Thompson — carry-over grounding from iter-4)
- .opencode/specs/viral-ops/007-l7-feedback-loop/research/iterations/iteration-003.md §8.5 (MLflow state machine)
- .opencode/specs/viral-ops/007-l7-feedback-loop/research/iterations/iteration-004.md §§A–F (4-channel envelope, Thompson arm granularity, drift quarantine, guardrails)
- .opencode/specs/viral-ops/006-content-lab/research/research.md §9 (5-stage prompt chain, 4 update cadences, ε-greedy budget)
- MEMORY.md project_thai_voice_pipeline (PyThaiNLP mandatory, 60+ Thai particles)

## Assessment

- **New information ratio**: raw = `(10 new + 0.5 × 3 refinements) / 13 = 0.88`; conservative = **0.80** after discounting the arXiv-abstract-only depth (Q5.open-1/2/3/4) and the fact that some §H mitigations are design inferences rather than cited primary sources. Same discipline as iter-2/3/4.
- **Simplicity bonus**: +0.05 for resolving iter-4's implicit tension — iter-4 mentioned the monthly `thompson_update_recommended_weights` recalibration but did not specify where it fires; this iteration places it in the `L3-Prompt-Tuner` workflow §G.2 Step 5 and in §C.4 meta-reward function. Also bridges L3's "Prompt Parameter Tuning" cadence (006:518) to a concrete meta-bandit + MLflow + canary pipeline. **Final newInfoRatio = 0.85** (0.80 raw + 0.05 simplicity).
- **Net findings (this iteration)**:
  1. Prompt parameter registry with stage-by-stage tunable/locked matrix (§A.1)
  2. `PromptTemplateVersion` Prisma schema with lifecycle + MLflow FK + lock-list fingerprint (§A.2, §E.3)
  3. Three-layer experiment separation (L3a content / L3b template / L3c parameter) with different randomization units (§B.1)
  4. Cohort-matched generation-level A/B design with Welch + Bayesian dual-test (§B.2, §B.3)
  5. Guardrail-veto layer on A/B promotion decisions (§B.4)
  6. Nested Thompson-Thompson meta-bandit architecture (§C.1, §C.2) with credit-attribution rule (§C.3)
  7. Per-stage independent meta-bandit decomposition (§C.5)
  8. Canary / Production(partial) / Production(full) rollout state machine with auto-revert + 14d cool-down (§D.1, §D.2)
  9. L3_AUTO_TUNE_FROZEN circuit breaker (§D.3)
  10. MLflow prompt-as-artifact integration with reproducibility version-triple (§E.1, §E.2)
  11. Drift coupling policy matrix with quarantine-not-reset + ε-widen resumption (§F.1, §F.3)
  12. L3-Prompt-Tuner new 7th L3 workflow (§G.2) with event-driven pause/quarantine hooks (§G.4)
  13. Meta-concern framework: prompt Goodhart, model collapse, Thai erosion with explicit layered mitigations (§H.1–H.3)
  14. Phased implementation sequencing (MVP → OPRO → DSPy → PromptBreeder) in §H.5
- **Questions addressed**: Q5 fully.
- **Questions answered**: Q5. **ALL 5 KEY QUESTIONS NOW ANSWERED.**
- **Final newInfoRatio**: **0.85**.

## Reflection

- **What worked and why**: Leaning on iter-4's safety infrastructure (5 quality flags, drift quarantine doctrine) and iter-3's MLflow state machine meant Q5 didn't need to re-invent safety primitives — it composed them at a new layer (prompt instead of content). The separation of three experiment layers (L3a/b/c) was the single most important design move because it resolved the confounding problem cleanly and gave each layer its natural unit of randomization. Grounding §H in Goodhart + Pan et al. definitional framing kept the meta-concerns principled rather than speculative.
- **What didn't work and why**: arXiv abstract pages gave conceptual ground-truth on DSPy/OPRO/PromptBreeder but not hyperparameter depth. Root cause: abstracts summarize, don't operationalize. Lesson (same as iter-4): for algorithm-hyperparameter detail, go to the GitHub repo or the full PDF rendering, not the arxiv abstract. For this iteration the depth from abstracts was enough to ground the **applicability** claims in §H.4 but not enough to spec concrete hyperparameters — those are correctly deferred to the implementation phase where runnable experiments can confirm them.
- **What I would do differently**: on a sixth iteration (if triggered), I would fetch the GitHub README files of the three papers' reference implementations directly. Also, the delayed-feedback bandit citation (Vernade 2017 / Grover 2018) is still a speculative INFERENCE tag in §C.2; next time check those papers' abstracts early.

## Convergence Assessment

**All 5 key questions are now answered.** The progressive synthesis in `research.md` carries an integrated end-to-end story:

- **Q1 (platform APIs)** — answered iter-1.
- **Q2 (ingestion pipeline + Prisma schema + rate limits)** — answered iter-2.
- **Q3 (GBDT retraining + drift detection + MLflow state machine)** — answered iter-3.
- **Q4 (4-channel feedback + Thompson content-level + envelope schema + guardrails)** — answered iter-4.
- **Q5 (prompt tuning automation + meta-bandit + MLflow prompt artifacts + drift coupling + safety rails)** — answered iter-5.

**Integration gaps closed this iteration**:
- L3's abstract "4 update cadences" (006:518) → concrete L3-Prompt-Tuner workflow with daily cron and event hooks.
- Monthly `thompson_update_recommended_weights` recalibration (iter-4 §D.4) → mapped to §C.4 meta-reward function + §G.2 Step 4–5.
- MLflow as model registry (iter-3 §8.5) → extended to prompt registry (§E.1).
- Drift-to-Thompson quarantine doctrine (iter-4 §F.2) → generalized to drift-to-prompt-tuning quarantine (§F.1, same principles).

**No integration gaps remain that block research-phase convergence.** Implementation-phase opens are explicitly scoped (Q5.open-1 through Q5.deferred-2).

**Recommendation**: Allow STOP on convergence gates. Quality guards met (≥4 sources per question with primary citations; ≥1 concrete implementation pattern per question; no TOC-only findings). All questions resolved. Max iterations 15 not reached but max-iterations is a ceiling, not a target. Iter-6 would pull diminishing returns on abstracts we already have and would start repeating Q5.open items that are correctly scoped to implementation.

If the convergence policy requires one more pass for robustness (e.g., if `weighted_stop_score` is at 0.55 and needs 0.60), the optional iter-6 focus should be: **"Gap-closure validation"** — verify each of the Q5.open items by fetching primary repos (Stanford DSPy GitHub, Google DeepMind OPRO GitHub, DeepMind PromptBreeder GitHub) for concrete hyperparameter values, and update the implementation-phase readiness score. That is a **defensive** iteration, not a generative one.

## Recommended Next Focus

**Primary recommendation**: **STOP — convergence reached.** All 5 key questions answered with concrete implementation patterns and safety rails. Proceed to synthesis phase.

**Conditional iter-6 focus (if convergence gates require one more)**: Gap-closure validation — WebFetch DSPy/OPRO/PromptBreeder GitHub repos for concrete hyperparameters; verify Chapelle-Li delayed-feedback-bandit citation via Vernade 2017 abstract; confirm Pan et al. + Krakovna et al. reward-hacking taxonomy labels.

---

## Graph Events (for JSONL record)

```
nodes (new this iteration):
- registry/prompt_template_versions
- stage/structural | stage/hook | stage/arc | stage/cta | stage/delivery
- tunable/temperature_top_p | tunable/hook_type_weights | tunable/emotional_tone_weights
- tunable/cta_intensity | tunable/xml_tag_nesting_depth
- locked/legal_disclaimer | locked/brand_voice | locked/thai_particles
- locked/platform_tos | locked/pipeline_contract
- layer/L3a_content_bandit (ref iter-4)
- layer/L3b_template_meta_bandit
- layer/L3c_parameter_sweep
- ab_harness/cohort_matching
- ab_harness/welch_test | ab_harness/bayesian_test
- meta_bandit/thompson_nested
- credit_attribution/variant_id_joins_stage_version_ids
- lifecycle/PROPOSED | lifecycle/SHADOW | lifecycle/CANARY
- lifecycle/PRODUCTION_PARTIAL | lifecycle/PRODUCTION_FULL | lifecycle/ARCHIVED | lifecycle/REVERTED
- safety/auto_revert | safety/cool_down_14d | safety/L3_AUTO_TUNE_FROZEN
- mlflow/prompts_namespace
- mlflow/reproducibility_triple
- mlflow/lock_list_fingerprint_sha256
- drift_coupling/prediction_performance_freeze
- drift_coupling/correlation_full_freeze
- drift_coupling/feature_label_reduce_canary
- drift_coupling/quality_flag_quarantine_stage
- workflow/L3_prompt_tuner
- hook/drift_escalation_sync_call
- hook/quality_flag_quarantine_sync_call
- citation/dspy_2310_03714
- citation/opro_2309_03409
- citation/promptbreeder_2309_16797
- citation/pan_reward_hacking_2209_13085
- meta_concern/prompt_goodhart_outrage_convergence
- meta_concern/clickbait_drift
- meta_concern/vanity_convergence
- meta_concern/model_collapse_diversity_loss
- meta_concern/thai_linguistic_erosion
- mitigation/forced_exploration_10pct
- mitigation/exemplar_diversity_quota_30pct
- mitigation/trend_novelty_injection
- mitigation/human_exemplar_quarterly
- mitigation/pythainlp_validator_gate_95pct
- phase/mvp_manual_versions | phase/opro_parameter_sweep
- phase/dspy_bootstrapfewshot | phase/promptbreeder_evolutionary

edges (new this iteration):
- L7FeedbackEnvelope --consumed_by--> layer/L3a_content_bandit (iter-4)
- L7FeedbackEnvelope --consumed_by--> layer/L3b_template_meta_bandit
- L7FeedbackEnvelope --consumed_by--> layer/L3c_parameter_sweep
- meta_bandit/thompson_nested --composes_with--> inner_bandit/iter_4_thompson
- stage/hook --has_tunables--> tunable/hook_type_weights + tunable/emotional_tone_weights
- stage/* --has_locked--> locked/*
- registry/prompt_template_versions --has_lifecycle--> lifecycle/*
- lifecycle/CANARY --promotes_to--> lifecycle/PRODUCTION_PARTIAL --promotes_to--> lifecycle/PRODUCTION_FULL
- lifecycle/PRODUCTION_FULL --auto_reverts_to--> lifecycle/REVERTED --cools_down--> 14d
- lifecycle/REVERTED --archives_predecessor--> lifecycle/ARCHIVED
- drift_events(CRITICAL, PREDICTION|PERFORMANCE) --freezes--> workflow/L3_prompt_tuner
- drift_events(CRITICAL, CORRELATION) --full_freezes--> workflow/L3_prompt_tuner
- drift_events(CRITICAL, FEATURE|LABEL) --reduces_canary--> lifecycle/CANARY
- quality_flag(rage|clickbait|bot, >2x baseline) --quarantines--> stage/{hook|cta}
- workflow/L3_prompt_tuner --updates--> meta_bandit/thompson_nested
- workflow/L3_prompt_tuner --transitions--> lifecycle/*
- workflow/L3_prompt_tuner --syncs--> mlflow/prompts_namespace
- mlflow/prompts_namespace --stores_artifact--> registry/prompt_template_versions
- mlflow/reproducibility_triple --joins--> (l2_model_version, l3_prompt_version_chain, l3_code_sha)
- mlflow/lock_list_fingerprint_sha256 --validates--> registry/prompt_template_versions (blocks on mismatch)
- citation/dspy_2310_03714 --informs--> phase/dspy_bootstrapfewshot
- citation/opro_2309_03409 --informs--> phase/opro_parameter_sweep + layer/L3c_parameter_sweep
- citation/promptbreeder_2309_16797 --informs--> phase/promptbreeder_evolutionary
- citation/pan_reward_hacking_2209_13085 --grounds--> meta_concern/*
- meta_concern/prompt_goodhart_outrage_convergence --mitigated_by--> guardrail/rage (iter-4)
- meta_concern/clickbait_drift --mitigated_by--> guardrail/clickbait (iter-4) + long_tail_T30d_metric (deferred)
- meta_concern/model_collapse_diversity_loss --mitigated_by--> mitigation/forced_exploration_10pct + mitigation/exemplar_diversity_quota_30pct + mitigation/trend_novelty_injection + mitigation/human_exemplar_quarterly
- meta_concern/thai_linguistic_erosion --mitigated_by--> locked/thai_particles + mitigation/pythainlp_validator_gate_95pct + thai_linguist_review_quarterly (deferred)
- safety/L3_AUTO_TUNE_FROZEN --auto_activates_on--> quality_flag_2x_baseline_24h
- safety/L3_AUTO_TUNE_FROZEN --pauses--> meta_bandit/thompson_nested + workflow/L3_prompt_tuner
```
