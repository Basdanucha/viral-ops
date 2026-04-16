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
- Topic: Pixelle-Video feature audit — all API endpoints, settings, UI features, workflow pipeline, configuration options to expose in viral-ops dashboard
- Started: 2026-04-17T12:00:00Z
- Status: INITIALIZED
- Iteration: 5 of 15
- Session ID: dr-002-pixelle-audit
- Parent Session: none
- Lifecycle Mode: new
- Generation: 1
- continuedFromRun: none

<!-- /ANCHOR:status -->
<!-- ANCHOR:progress -->
## 3. PROGRESS

| # | Focus | Track | Ratio | Findings | Status |
|---|-------|-------|-------|----------|--------|
| 1 | FastAPI router endpoint catalog — all 10 routers fetched and 21 endpoints documented | api-endpoints | 0.95 | 11 | complete |
| 2 | Pydantic schemas (22 models across 8 files) + API config (12 settings) + core config.yaml (15+ settings) | api-schemas-config | 0.91 | 11 | complete |
| 3 | Content generation subsystems: ComfyUI workflows (29 total), TTS engines (3 engines, 28 voices), LLM providers (6 presets), video templates (25+ across 3 aspect ratios), image gen models (9+ models) | content-subsystems | 0.94 | 8 | complete |
| 4 | Streamlit UI architecture (web/app.py + pages + components), complete 8-stage data flow pipeline (StandardPipeline), batch processing (frame-level parallelism, NOT video-level), GPU/resource management (RunningHub cloud vs local selfhost) | ui-pipeline-batch | 0.90 | 10 | complete |
| 5 | Final discovery: Streamlit widget catalog (22+ widgets), per-channel config mapping (16 per-channel + 15 global params), file management (7 directories, no upload/cleanup), definitive feature matrix (5 dashboard pages + n8n nodes) | ui-config-synthesis | 0.86 | 7 | complete |

- iterationsCompleted: 5
- keyFindings: 157
- openQuestions: 14
- resolvedQuestions: 0

<!-- /ANCHOR:progress -->
<!-- ANCHOR:questions -->
## 4. QUESTIONS
- Answered: 0/14
- [ ] Q1: What are ALL FastAPI endpoints (all 9+ routers) with complete request/response schemas?
- [ ] Q2: What are ALL configurable settings (config.yaml fields, env vars, CLI flags)?
- [ ] Q3: What ComfyUI workflows ship by default and what parameters are customizable per workflow?
- [ ] Q4: What TTS engines are supported, what are their config options (voice, speed, pitch, language)?
- [ ] Q5: What LLM providers are supported and how is the LLM prompt pipeline configured?
- [ ] Q6: What image generation options exist (models, sizes, styles, workflows)?
- [ ] Q7: What video composition options exist (templates, transitions, captions, music, aspect ratios)?
- [ ] Q8: What task/job management features exist (async jobs, status polling, cancellation, queue)?
- [ ] Q9: What file management features exist (upload, download, storage paths, cleanup)?
- [ ] Q10: What is the Streamlit UI feature set and which features need equivalent dashboard pages?
- [ ] Q11: What batch/bulk generation capabilities exist?
- [ ] Q12: What are the GPU/resource management options (local vs RunningHub, concurrency limits)?
- [ ] Q13: Which features need to be per-channel configurable in the viral-ops dashboard?
- [ ] Q14: What is the complete data flow from topic input to final video output (every intermediate artifact)?

<!-- /ANCHOR:questions -->
<!-- ANCHOR:trend -->
## 5. TREND
- Last 3 ratios: 0.94 -> 0.90 -> 0.86
- Stuck count: 0
- Guard violations: none recorded by the reducer pass
- convergenceScore: 0.86
- coverageBySources: {"github.com":18,"raw.githubusercontent.com":34}

<!-- /ANCHOR:trend -->
<!-- ANCHOR:dead-ends -->
## 6. DEAD ENDS
- Health router source fetch: low priority, inferred from mount pattern. Can confirm in a later iteration if needed. (iteration 1)
- None identified. (iteration 2)
- None this iteration. All targeted sources were successfully fetched. (iteration 2)
- None. All five target areas yielded substantial results from GitHub source files. (iteration 3)
- None identified. The direct raw GitHub fetch approach continues to be highly productive. (iteration 3)
- `pixelle_video/content.py` — does not exist as a standalone file; content generation is embedded in pipeline stages (iteration 4)
- `pixelle_video/services/content.py` — does not exist; the service layer is flat at `pixelle_video/service.py` (iteration 4)
- `webui/` directory path — does not exist; the Streamlit UI is at `web/` instead (iteration 4)
- None. All paths that returned 404 were quickly corrected by discovering the actual repository structure. (iteration 4)
- `2_History.py` path without emoji (404) — actual filename is `2_📚_History.py` with URL-encoded emoji prefix (iteration 5)
- File cleanup API endpoint — does not exist; cleanup is manual/external (iteration 5)
- File upload API endpoint — does not exist; all files are generated by the pipeline (iteration 5)
- No auto-cleanup — generated files accumulate indefinitely. viral-ops must implement its own cleanup policy (cron job or storage quota). (iteration 5)
- No file upload endpoint in the entire API — Pixelle-Video generates all files internally. The viral-ops dashboard will need a separate upload mechanism for voice clone reference audio (store in data/ and pass path to API). (iteration 5)
- Re-run/re-generate from History page — not available; must go to Home page (iteration 5)
- TTS pitch control — does not exist anywhere in the system (iteration 5)

<!-- /ANCHOR:dead-ends -->
<!-- ANCHOR:next-focus -->
## 7. NEXT FOCUS
All 14 questions are fully answered. The research is ready for convergence and synthesis. Recommended next step: final synthesis iteration to produce the definitive research.md document consolidating all findings into the complete Pixelle-Video feature audit.

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
