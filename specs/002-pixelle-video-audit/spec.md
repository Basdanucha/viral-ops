# Spec: Pixelle-Video Feature Audit

## Requirements
<!-- DR-SEED:REQUIREMENTS -->
Complete feature audit of Pixelle-Video (v0.1.15, Apache 2.0) to catalog every API endpoint, configurable setting, UI feature, workflow pipeline stage, and configuration option. Output a feature matrix mapping each Pixelle-Video capability to the corresponding viral-ops dashboard surface.

## Scope
<!-- DR-SEED:SCOPE -->
- Catalog all FastAPI router endpoints (9+ routers) with request/response schemas
- Document all configuration options (config.yaml, env vars, CLI flags)
- Map ComfyUI workflows, TTS engines, LLM providers, image gen options
- Document video composition options (templates, transitions, captions)
- Map features to viral-ops dashboard pages and n8n workflow integration points

## Open Questions
All 14 questions answered across 5 autonomous iterations.

## Research Context
Deep research **complete**. Canonical findings in `research/research.md` (515 lines).

<!-- BEGIN GENERATED: deep-research/spec-findings -->
## Feature Audit Summary (5 iterations, 14 questions)

### API Catalog
- **21 endpoints** across 10 routers (health, llm, tts, image, content, video, tasks, files, resources, frame)
- **22 Pydantic models** with exact field types, defaults, constraints
- Two generation modes: sync (blocking) + async (task-based polling)

### Content Generation Subsystems
- **29 ComfyUI workflows** (8 selfhost + 21 RunningHub), 6 tunable params per workflow
- **28 Edge-TTS voices** (11 languages, 3 Thai), 3 TTS engines (Edge-TTS, ChatTTS, Index-TTS)
- **6 LLM providers** (Qwen, OpenAI, Claude, DeepSeek, Ollama, Moonshot), all OpenAI-compatible
- **25+ HTML templates** (9:16, 16:9, 1:1), dynamic template_params per template
- **15+ image/video gen models** (FLUX, FLUX v2, SD 3.5, WAN 2.1/2.2, LTX2, etc.)

### 8-Stage Pipeline
setup_environment → generate_content → determine_title → plan_visuals → initialize_storyboard → produce_assets → post_production → finalize

### Per-Channel Config (16 params injectable via n8n)
TTS workflow/voice, ComfyUI image workflow, LLM provider/model/prompt, template, language, video count, aspect ratio, image size, BGM, subtitle, speed, ref_audio, num_inference_steps, template_params

### Dashboard Pages Needed (5)
1. **Content Creation** — topic, language, voice, style, template, generate button
2. **Generation Settings** — LLM provider, image model, GPU config, ComfyUI workflows
3. **Content Library** — history grid, filters, preview, download, delete
4. **Channel Settings** — per-channel voice, workflow, persona, template overrides
5. **System Settings** — RunningHub API key, concurrent limit, paths, global defaults

### Key Gaps for viral-ops
- No file upload endpoint (custom asset uploads need separate handling)
- No cleanup/purge mechanism (must implement in dashboard)
- Batch is frame-level only (multi-video batch via n8n)
- No streaming/progress for video composition
- TTS has speed (0.5-2.0) but NO pitch control
<!-- END GENERATED: deep-research/spec-findings -->
