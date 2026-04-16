# Deep Research Strategy — Pixelle-Video Feature Audit

<!-- ANCHOR:overview -->
## 1. OVERVIEW

### Purpose
Complete feature audit of Pixelle-Video to determine exactly what API endpoints, settings, UI features, workflow pipelines, and configuration options must be exposed in the viral-ops web dashboard. This drives the dashboard page design and n8n workflow integration.

---

<!-- /ANCHOR:overview -->
<!-- ANCHOR:topic -->
## 2. TOPIC
Pixelle-Video feature audit — exhaustive catalog of every API endpoint (request/response schemas), every configurable setting, every UI feature, every ComfyUI workflow stage, and every configuration option. Output: a feature matrix mapping Pixelle → viral-ops dashboard surfaces.

---

<!-- /ANCHOR:topic -->
<!-- ANCHOR:key-questions -->
## 3. KEY QUESTIONS (remaining)
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

<!-- /ANCHOR:key-questions -->
<!-- ANCHOR:non-goals -->
## 4. NON-GOALS
- NOT redesigning Pixelle-Video's internal architecture
- NOT comparing with other video engines (already decided in gen1)
- NOT evaluating platform upload (covered in gen1)
- Only cataloging what exists to inform viral-ops dashboard design

---

<!-- /ANCHOR:non-goals -->
<!-- ANCHOR:stop-conditions -->
## 5. STOP CONDITIONS
- All 9+ API routers documented with request/response schemas
- All config options cataloged
- Feature matrix: Pixelle-Video feature → viral-ops dashboard surface
- Complete data flow diagram
- All 14 key questions answered

---

<!-- /ANCHOR:stop-conditions -->
<!-- ANCHOR:answered-questions -->
## 6. ANSWERED QUESTIONS
[None yet]

<!-- /ANCHOR:answered-questions -->
<!-- MACHINE-OWNED: START -->
<!-- ANCHOR:what-worked -->
## 7. WHAT WORKED
- Fetching raw GitHub source files directly gave complete endpoint definitions with parameter types and response models. The structured approach of starting from app.py router mounts then fetching each router ensured completeness. (iteration 1)
- Fetching raw GitHub source files directly (same approach as iteration 1) continues to be the most reliable method. The AI extraction faithfully preserved field types, defaults, and constraint annotations. Batching multiple schema files per WebFetch call maximized coverage within budget. (iteration 2)
- Fetching GitHub directory listings for workflows/ and templates/ gave complete file catalogs. Fetching raw source for tts_voices.py and llm_presets.py gave exact data structures. The FLUX workflow JSON revealed the standard ComfyUI node parameter architecture. Covering 5 questions in one iteration was possible because each area had a clear canonical source file. (iteration 3)
- Fetching the repository root listing first (when initial paths 404'd) quickly revealed the correct directory structure (`web/` not `webui/`, `pixelle_video/service.py` not `pixelle_video/services/`). The StandardPipeline source was the single most valuable fetch — it contained the complete 8-stage data flow, batch processing logic, GPU mode switching, and all configuration parameters. (iteration 4)
- Fetching the actual component source files (content_input.py, style_config.py) yielded the exact widget specs needed to complete Q10. The History page fetch revealed the complete task browsing feature set. The files router analysis closed Q9 definitively. The synthesis approach for Q13 (combining all prior iteration data) produced the per-channel mapping without requiring new fetches. (iteration 5)

<!-- /ANCHOR:what-worked -->
<!-- ANCHOR:what-failed -->
## 8. WHAT FAILED
- WebFetch summarization occasionally omitted exact type annotations or default values (e.g., LLM router temperature range). Schema details imported from `api.schemas.*` modules were not fully resolved since we only fetched router files, not schema files. (iteration 1)
- Could not fit frame.py fetch into the tool budget -- 9 schema files + 2 config files required 8 WebFetch calls. frame.py is the lowest-priority remaining schema (frame rendering is a subset of video generation). (iteration 2)
- GitHub directory listings truncate — the templates/1080x1920 listing shows 25 files but may have more. Also could not fetch 1920x1080 and 1080x1080 template listings within budget. (iteration 3)
- Initial 3 fetches all 404'd because path assumptions from iteration 1 (which only looked at `api/` routers) were wrong for the core package and UI. The web component files (content_input.py, style_config.py) could not be fetched within budget, leaving exact widget definitions incomplete. (iteration 4)
- History page filename had emoji prefix that caused initial 404 — resolved by checking the directory listing first. This is a recurring pattern with Streamlit's multi-page convention. (iteration 5)

<!-- /ANCHOR:what-failed -->
<!-- ANCHOR:exhausted-approaches -->
## 9. EXHAUSTED APPROACHES (do not retry)
### `2_History.py` path without emoji (404) — actual filename is `2_📚_History.py` with URL-encoded emoji prefix -- BLOCKED (iteration 5, 1 attempts)
- What was tried: `2_History.py` path without emoji (404) — actual filename is `2_📚_History.py` with URL-encoded emoji prefix
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: `2_History.py` path without emoji (404) — actual filename is `2_📚_History.py` with URL-encoded emoji prefix

### `pixelle_video/content.py` — does not exist as a standalone file; content generation is embedded in pipeline stages -- BLOCKED (iteration 4, 1 attempts)
- What was tried: `pixelle_video/content.py` — does not exist as a standalone file; content generation is embedded in pipeline stages
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: `pixelle_video/content.py` — does not exist as a standalone file; content generation is embedded in pipeline stages

### `pixelle_video/services/content.py` — does not exist; the service layer is flat at `pixelle_video/service.py` -- BLOCKED (iteration 4, 1 attempts)
- What was tried: `pixelle_video/services/content.py` — does not exist; the service layer is flat at `pixelle_video/service.py`
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: `pixelle_video/services/content.py` — does not exist; the service layer is flat at `pixelle_video/service.py`

### `webui/` directory path — does not exist; the Streamlit UI is at `web/` instead -- BLOCKED (iteration 4, 1 attempts)
- What was tried: `webui/` directory path — does not exist; the Streamlit UI is at `web/` instead
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: `webui/` directory path — does not exist; the Streamlit UI is at `web/` instead

### File cleanup API endpoint — does not exist; cleanup is manual/external -- BLOCKED (iteration 5, 1 attempts)
- What was tried: File cleanup API endpoint — does not exist; cleanup is manual/external
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: File cleanup API endpoint — does not exist; cleanup is manual/external

### File upload API endpoint — does not exist; all files are generated by the pipeline -- BLOCKED (iteration 5, 1 attempts)
- What was tried: File upload API endpoint — does not exist; all files are generated by the pipeline
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: File upload API endpoint — does not exist; all files are generated by the pipeline

### Health router source fetch: low priority, inferred from mount pattern. Can confirm in a later iteration if needed. -- BLOCKED (iteration 1, 1 attempts)
- What was tried: Health router source fetch: low priority, inferred from mount pattern. Can confirm in a later iteration if needed.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Health router source fetch: low priority, inferred from mount pattern. Can confirm in a later iteration if needed.

### No auto-cleanup — generated files accumulate indefinitely. viral-ops must implement its own cleanup policy (cron job or storage quota). -- BLOCKED (iteration 5, 1 attempts)
- What was tried: No auto-cleanup — generated files accumulate indefinitely. viral-ops must implement its own cleanup policy (cron job or storage quota).
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: No auto-cleanup — generated files accumulate indefinitely. viral-ops must implement its own cleanup policy (cron job or storage quota).

### No file upload endpoint in the entire API — Pixelle-Video generates all files internally. The viral-ops dashboard will need a separate upload mechanism for voice clone reference audio (store in data/ and pass path to API). -- BLOCKED (iteration 5, 1 attempts)
- What was tried: No file upload endpoint in the entire API — Pixelle-Video generates all files internally. The viral-ops dashboard will need a separate upload mechanism for voice clone reference audio (store in data/ and pass path to API).
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: No file upload endpoint in the entire API — Pixelle-Video generates all files internally. The viral-ops dashboard will need a separate upload mechanism for voice clone reference audio (store in data/ and pass path to API).

### None. All five target areas yielded substantial results from GitHub source files. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: None. All five target areas yielded substantial results from GitHub source files.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None. All five target areas yielded substantial results from GitHub source files.

### None. All paths that returned 404 were quickly corrected by discovering the actual repository structure. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: None. All paths that returned 404 were quickly corrected by discovering the actual repository structure.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None. All paths that returned 404 were quickly corrected by discovering the actual repository structure.

### None identified. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: None identified.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None identified.

### None identified. The direct raw GitHub fetch approach continues to be highly productive. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: None identified. The direct raw GitHub fetch approach continues to be highly productive.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None identified. The direct raw GitHub fetch approach continues to be highly productive.

### None this iteration. All targeted sources were successfully fetched. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: None this iteration. All targeted sources were successfully fetched.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None this iteration. All targeted sources were successfully fetched.

### Re-run/re-generate from History page — not available; must go to Home page -- BLOCKED (iteration 5, 1 attempts)
- What was tried: Re-run/re-generate from History page — not available; must go to Home page
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Re-run/re-generate from History page — not available; must go to Home page

### TTS pitch control — does not exist anywhere in the system -- BLOCKED (iteration 5, 1 attempts)
- What was tried: TTS pitch control — does not exist anywhere in the system
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: TTS pitch control — does not exist anywhere in the system

<!-- /ANCHOR:exhausted-approaches -->
<!-- ANCHOR:ruled-out-directions -->
## 10. RULED OUT DIRECTIONS
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

<!-- /ANCHOR:ruled-out-directions -->
<!-- ANCHOR:next-focus -->
## 11. NEXT FOCUS
All 14 questions are fully answered. The research is ready for convergence and synthesis. Recommended next step: final synthesis iteration to produce the definitive research.md document consolidating all findings into the complete Pixelle-Video feature audit.

<!-- /ANCHOR:next-focus -->
<!-- MACHINE-OWNED: END -->
<!-- ANCHOR:known-context -->
## 12. KNOWN CONTEXT

### From gen1 research (specs/001-base-app-research iter 3-4)
- Pixelle-Video v0.1.15 (Apache 2.0, 4.1k stars)
- FastAPI REST API on :8000 with 9 routers: health, llm, tts, image, content, video, tasks, files, resources, frame
- Run: `uv run python api/app.py --port 8000`
- Core package: `pixelle_video/` — config, models, pipelines, prompts, services, utils
- TTS: Edge-TTS (Thai 3 voices), ChatTTS, Index-TTS, voice cloning
- Image: ComfyUI workflows (FLUX, SD, WAN 2.1), JSON auto-scan from workflows/
- LLM: GPT, Qwen, DeepSeek, Ollama
- Per-request params confirmed: voice (TTS), workflow (image), prompt (LLM)
- LLM endpoint GAP: no system_prompt param → inject via n8n
- GPU: optional, RunningHub cloud as alternative
- Composition: FFmpeg, HTML templates (static, image-bg, video-bg)

### Architecture context
- viral-ops dashboard (Next.js :3000) → n8n (:5678) → Pixelle-Video (:8000)
- Dashboard needs to expose Pixelle-Video features as UI controls
- n8n injects per-channel config before calling Pixelle-Video API

---

<!-- /ANCHOR:known-context -->
<!-- ANCHOR:research-boundaries -->
## 13. RESEARCH BOUNDARIES
- Max iterations: 15
- Convergence threshold: 0.05
- Per-iteration budget: 12 tool calls, 10 minutes
- Progressive synthesis: true
- Started: 2026-04-17T12:00:00Z
<!-- /ANCHOR:research-boundaries -->
