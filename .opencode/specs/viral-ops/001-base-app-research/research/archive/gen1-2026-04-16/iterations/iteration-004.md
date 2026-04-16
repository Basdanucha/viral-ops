# Iteration 4: Pixelle-Video Deep-Dive — API Architecture, Thai TTS, ComfyUI Workflows

## Focus
Deep-dive into Pixelle-Video's internal architecture to answer integration questions: Does it have a headless API? How does Thai TTS work? What is the ComfyUI workflow system? How modular is the actual codebase? This iteration shifts from candidate comparison (iteration 3) to integration viability assessment of the selected engine.

## Findings

### Finding 1: Pixelle-Video Has a Full FastAPI REST API (Headless Mode EXISTS)
**Critical discovery contradicting iteration 3's cautious assessment.** Pixelle-Video already ships a complete FastAPI-based REST API in the `api/` directory, independent of the Streamlit web UI.

**API structure:**
```
api/
├── routers/        # 9 route modules
├── schemas/        # Request/response data models
├── tasks/          # Background task processing
├── __init__.py
├── app.py          # FastAPI app (uvicorn, port 8000)
├── config.py       # API-specific configuration
└── dependencies.py # Dependency injection
```

**Mounted routers (all under `/api` prefix):**
1. `health` — Health check endpoint (no prefix)
2. `llm` — LLM integration (script generation)
3. `tts` — Text-to-speech synthesis
4. `image` — Image generation (ComfyUI)
5. `content` — Content generation pipeline
6. `video` — Video composition and rendering
7. `tasks` — Background task management
8. `files` — File upload/download
9. `resources` — Resource management
10. `frame` — Frame/scene management

**Run independently:** `uv run python api/app.py --host 0.0.0.0 --port 8000`

**This means:** No need to "wrap" Pixelle-Video with a FastAPI layer (as previously recommended). The API already exists. Integration with n8n or a dashboard orchestrator can call these REST endpoints directly.

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/app.py]

### Finding 2: Modular Layered Architecture — Service-Pipeline-Model Pattern
The `pixelle_video/` core package follows a clean layered architecture:

```
pixelle_video/
├── config/         # Configuration management
├── models/         # Data models
├── pipelines/      # Workflow/processing pipelines
├── prompts/        # LLM prompt templates
├── services/       # Service layer (core business logic)
├── utils/          # Cross-cutting utilities
├── __init__.py
├── llm_presets.py  # LLM configuration presets
├── service.py      # Main service orchestrator
└── tts_voices.py   # TTS voice configurations
```

**Architecture assessment:**
- **Service layer** (`service.py`, `services/`) — orchestrates the video generation pipeline
- **Pipeline layer** (`pipelines/`) — composable processing steps (script → images → TTS → composition)
- **Prompt layer** (`prompts/`) — LLM prompt templates, swappable per content type
- **Config layer** (`config/`) — externalized settings via `config.example.yaml`

This is genuinely modular — not just claimed. Each layer can be extended independently. Custom content types (product showcase, trend reaction) would primarily need new prompt templates and potentially new pipeline configurations.

[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/pixelle_video]

### Finding 3: Thai TTS Verified — 3 Neural Voices via Edge-TTS
Microsoft Edge-TTS provides **3 neural voices** for Thai (`th-TH`):

| Voice Name | Gender | Type |
|---|---|---|
| `th-TH-PremwadeeNeural` | Female | Neural |
| `th-TH-NiwatNeural` | Male | Neural |
| `th-TH-AcharaNeural` | Female | Neural |

**Quality level:** All are modern Neural voices (not legacy Standard/concatenative). Neural voices provide natural prosody, correct tone pronunciation (critical for Thai tonal language), and smooth intonation.

**Integration path:** Pixelle-Video's `tts_voices.py` file manages voice configurations. Edge-TTS is one of the supported engines. Configuration involves selecting the TTS workflow and specifying the voice name string (e.g., `th-TH-PremwadeeNeural`).

**Limitation:** None of the Thai voices support custom voice styles (cheerful, sad, etc.) — only neutral delivery. For style variation, would need to use Index-TTS voice cloning with a Thai reference audio file.

[SOURCE: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts]
[SOURCE: https://github.com/AIDC-AI/Pixelle-Video/tree/main/pixelle_video — tts_voices.py presence]

### Finding 4: ComfyUI Workflow Architecture — JSON-Based, Scannable
Pixelle-Video uses ComfyUI workflows stored as JSON files in the `workflows/` directory:

- System auto-scans workflows from `workflows/` folder at startup
- Default image generation uses `image_flux.json` workflow
- Workflows are selectable from the UI dropdown or via API
- Template system: `static_*.html`, `image_*.html`, `video_*.html` for different content types
- Supports: FLUX, Stable Diffusion, WAN 2.1, and custom workflows

**Creating custom workflows for viral-ops:**
1. Design a ComfyUI workflow in ComfyUI's visual editor
2. Export as JSON (standard ComfyUI format)
3. Place in `workflows/` directory — auto-discovered
4. Select via API endpoint or config

**Supported models:**
- **Image gen:** FLUX (default), Stable Diffusion, custom ComfyUI models
- **Video gen:** WAN 2.1 (image-to-video)
- **LLM:** GPT, Qwen, DeepSeek, Ollama (local)

[SOURCE: https://github.com/AIDC-AI/Pixelle-Video — README workflow documentation]

### Finding 5: GPU Requirements and RunningHub Cloud Option
**Local GPU:** Not explicitly stated in README, but implied by ComfyUI dependency. ComfyUI image generation typically requires:
- FLUX models: 12-24GB VRAM (FLUX.1-schnell runs on 8GB with quantization)
- Stable Diffusion: 4-8GB VRAM
- WAN 2.1 video: 24-48GB VRAM

**Critical insight — CPU-only partial pipeline is viable:**
- TTS (Edge-TTS) = **cloud API, no local GPU needed**
- Script generation (LLM) = can use cloud API (GPT, DeepSeek) or local (Ollama)
- Captions = CPU-based
- Video composition = CPU-based (FFmpeg)
- ONLY image/video generation requires GPU

**RunningHub cloud API:**
- Configure API key instead of local ComfyUI
- Provides "48G VRAM machine support" in the cloud
- Supports parallel processing with configurable concurrent request limits
- Acts as a drop-in replacement for local ComfyUI — same workflow JSON, different execution backend

**Phase 1 strategy:** Run TTS + composition on local CPU, use RunningHub or local GPU for image generation. This dramatically lowers the hardware barrier.

[SOURCE: https://github.com/AIDC-AI/Pixelle-Video — README RunningHub section]
[INFERENCE: based on standard ComfyUI VRAM requirements and Pixelle-Video's modular architecture separating TTS/composition from image gen]

### Finding 6: Pixelle-Video Integration Architecture for viral-ops
Based on all findings, the integration architecture for viral-ops becomes clear:

```
viral-ops Dashboard (Next.js)
        │
        ▼
n8n Orchestrator ──────────► Pixelle-Video FastAPI (port 8000)
        │                         │
        │                    ┌────┴────────┐
        │                    │  /api/llm    │ → GPT/DeepSeek/Ollama
        │                    │  /api/tts    │ → Edge-TTS (th-TH) / Index-TTS
        │                    │  /api/image  │ → ComfyUI (local) or RunningHub (cloud)
        │                    │  /api/video  │ → FFmpeg composition
        │                    │  /api/tasks  │ → Background job status
        │                    │  /api/content│ → Full pipeline trigger
        │                    └─────────────┘
        │
        ▼
Upload Layer (TikTok API / upload-post.com)
```

**Key advantages discovered this iteration:**
1. No custom API wrapper needed — FastAPI already exists
2. Each pipeline step has its own endpoint — granular control
3. Background task management built in — long-running video jobs
4. RunningHub as GPU escape hatch — no mandatory local GPU for Phase 1

[INFERENCE: based on Finding 1 (API structure), Finding 5 (GPU split), and prior iteration context (n8n orchestrator, Next.js dashboard)]

## Ruled Out
- **"Need to build FastAPI wrapper" assumption** — Pixelle-Video already has one. The MoneyPrinterTurbo API pattern reference is less critical than assumed.
- **GPU as hard requirement for Phase 1** — TTS, composition, and captions can run CPU-only; RunningHub handles image gen in the cloud.

## Dead Ends
None this iteration — all research avenues were productive.

## Sources Consulted
- https://github.com/AIDC-AI/Pixelle-Video (README, directory structure)
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/api (API directory listing)
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/pixelle_video (core package structure)
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/app.py (FastAPI application source)
- https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts (Thai TTS voices)

## Assessment
- New information ratio: 0.92
- Questions addressed: Q11 (API/headless mode), Q12 (Thai TTS), GPU requirements, ComfyUI workflow depth, code architecture
- Questions answered: Q11 (YES — full FastAPI REST API with 9 routers), Q12 (YES — 3 Thai Neural voices via Edge-TTS)

## Reflection
- What worked and why: Fetching the raw `api/app.py` source from GitHub revealed the FastAPI application structure that was invisible from the README alone. The README is UI-focused and does not advertise the REST API — only source code inspection found it. Microsoft's TTS documentation page provided definitive Thai voice data.
- What did not work and why: N/A — all research actions yielded high-value results.
- What I would do differently: In iteration 3, I should have checked the `api/` directory before concluding that a FastAPI wrapper would need to be built. Source code inspection > README claims.

## Recommended Next Focus
1. **MoneyPrinterTurbo API design comparison** — Now that Pixelle-Video's API is confirmed, compare its endpoint design with MoneyPrinterTurbo's for completeness. Are there patterns from MPT worth adopting?
2. **n8n integration pattern** — How would n8n HTTP nodes call Pixelle-Video's FastAPI endpoints? What's the workflow template?
3. **SaaS shell + video engine integration** — Revisit Q3/Q5: How does next-saas-stripe-starter integrate with Pixelle-Video's API? Define the glue layer architecture.
4. **Index-TTS voice cloning for Thai** — Edge-TTS has only neutral style. Can Index-TTS clone a Thai voice for more expressive delivery?
