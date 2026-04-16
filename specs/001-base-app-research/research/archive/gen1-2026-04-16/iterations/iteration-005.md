# Iteration 5: n8n Integration Pattern, Glue Architecture, Index-TTS Thai Voice Cloning

## Focus
How the viral-ops stack integrates together in Phase 1 (local-use on Windows): n8n orchestration calling Pixelle-Video's FastAPI, dashboard triggering workflows, and Index-TTS as an expressive Thai voice alternative to Edge-TTS. This iteration addresses Q3 (pipeline architecture support), Q5 (extensibility), and Q7 (background job orchestration).

## Findings

### 1. n8n Installation and Local Setup on Windows
n8n runs locally on Windows via two methods:
- **npm/npx** (simplest): `npx n8n` starts immediately on `http://localhost:5678`. Requires Node.js 18+. Uses SQLite by default for local development (zero-config). Data stored in `~/.n8n/`.
- **Docker Desktop**: `docker run -it --rm -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n` — production-grade with persistent volume. Port 5678.
- n8n is **fully supported on Windows** via both methods. The npm approach is simplest for Phase 1 local-use.
- Environment variables control configuration: `N8N_PORT`, `DB_TYPE` (sqlite/postgres), `N8N_BASIC_AUTH_ACTIVE`, `WEBHOOK_URL`.
[SOURCE: https://raw.githubusercontent.com/n8n-io/n8n/master/README.md — port 5678, npx n8n, Docker volume mount]
[SOURCE: https://docs.n8n.io/api/ — API documentation index confirms REST API, webhooks, HTTP Request node exist]

### 2. n8n REST API for Dashboard Integration
n8n exposes a full REST API (enabled via `N8N_PUBLIC_API_ENABLED=true`) at `http://localhost:5678/api/v1/`:
- **POST `/api/v1/workflows/{id}/execute`** — Trigger any workflow programmatically. Returns execution ID for polling status.
- **GET `/api/v1/executions/{id}`** — Poll execution status (running/success/error) and retrieve output data.
- **POST `/api/v1/workflows`** — Create/update workflows programmatically.
- **Authentication**: API Key (header `X-N8N-API-KEY`) or Basic Auth.
- **Webhook node alternative**: Any workflow starting with a Webhook node gets a unique URL like `http://localhost:5678/webhook/{webhook-id}` that accepts POST/GET requests with JSON payload. This is the simplest trigger mechanism.

**Dashboard integration pattern**: Next.js API route calls n8n webhook URL with video generation parameters. n8n workflow executes, dashboard polls execution status via REST API.
[SOURCE: https://docs.n8n.io/api/ — REST API documentation structure confirms these endpoints]
[INFERENCE: based on n8n v1 REST API schema (well-documented in n8n community) and standard webhook node behavior]

### 3. n8n HTTP Request Node Calling Pixelle-Video FastAPI
The n8n HTTP Request node is the bridge between n8n workflows and Pixelle-Video's FastAPI (port 8000). A complete viral-ops workflow would chain these nodes:

```
Webhook Trigger (from dashboard)
  → HTTP Request: POST http://localhost:8000/api/llm/generate_script
      Body: { "topic": "{{$json.topic}}", "language": "th" }
  → HTTP Request: POST http://localhost:8000/api/tts/synthesize
      Body: { "text": "{{$node.script.json.script}}", "voice": "th-TH-PremwadeeNeural" }
  → HTTP Request: POST http://localhost:8000/api/image/generate
      Body: { "prompt": "{{$node.script.json.visual_prompts}}", "workflow": "default" }
  → HTTP Request: POST http://localhost:8000/api/video/compose
      Body: { "audio_path": "{{...}}", "images": [...], "captions": true }
  → HTTP Request: POST upload-endpoint (TikTok API / platform)
  → Respond to Webhook: { "status": "complete", "video_url": "..." }
```

Key HTTP Request node capabilities:
- Supports GET, POST, PUT, PATCH, DELETE
- JSON body builder (expression or raw JSON)
- Response handling: auto-parse JSON, binary data for files
- Retry on failure (configurable attempts + backoff)
- Expression syntax `{{$json.field}}` passes data between nodes
- Can send/receive binary data (audio files, images, video)
- Pagination support for list endpoints
- All on localhost — zero network latency between services

[INFERENCE: based on n8n HTTP Request node documentation structure, Pixelle-Video FastAPI router endpoints from iteration 4, and standard n8n expression syntax]

### 4. Phase 1 Glue Architecture: Three-Service Localhost Stack
For Phase 1 (local-use on Windows), the full stack runs as three processes on localhost:

```
┌─────────────────────────────────────────────────────────┐
│  Windows Machine (Phase 1 Local)                        │
│                                                         │
│  ┌─────────────────┐    REST API     ┌───────────────┐  │
│  │  Next.js         │──────────────→│  n8n           │  │
│  │  Dashboard       │  POST webhook  │  Orchestrator  │  │
│  │  :3000           │←─────────────│  :5678         │  │
│  │                  │  poll status   │                │  │
│  └─────────────────┘                └───────┬───────┘  │
│                                             │          │
│                                    HTTP Req  │          │
│                                    nodes     │          │
│                                             ▼          │
│                                    ┌───────────────┐  │
│                                    │ Pixelle-Video  │  │
│                                    │ FastAPI        │  │
│                                    │ :8000          │  │
│                                    │                │  │
│                                    │ ├ /api/llm     │  │
│                                    │ ├ /api/tts     │  │
│                                    │ ├ /api/image   │  │
│                                    │ ├ /api/video   │  │
│                                    │ └ /api/tasks   │  │
│                                    └───────────────┘  │
│                                                         │
│  State: SQLite (n8n) + Prisma/PG (Dashboard)           │
│  Files: Local filesystem (shared data dir)              │
└─────────────────────────────────────────────────────────┘
```

**Communication pattern**:
1. User clicks "Generate Video" in dashboard (Next.js :3000)
2. Next.js API route POSTs to n8n webhook: `http://localhost:5678/webhook/viral-ops-generate`
3. n8n workflow chains HTTP requests to Pixelle-Video FastAPI :8000
4. n8n `/api/tasks/` endpoint tracks async job progress
5. Dashboard polls n8n execution status or uses n8n's webhook response

**State management**:
- **n8n SQLite**: Workflow definitions, execution history, credentials (built-in)
- **Dashboard Prisma/PG**: User data, video metadata (title, status, platform, publish date), content calendar
- **Pixelle-Video**: Stateless per-request (files on local filesystem). The `/api/tasks/` router provides job tracking for long-running operations.
- **Shared filesystem**: Generated assets (audio, images, video) stored in a shared local directory accessible by all three services.

**Process management**: Three terminal windows or a single `docker-compose.yml` / PM2 process manager. For Phase 1 simplicity, `concurrently` npm package or a `.bat` startup script.

[INFERENCE: based on n8n port 5678 (README), Pixelle-Video port 8000 (iteration 4 app.py source), Next.js default port 3000, and standard localhost service architecture]

### 5. Index-TTS Voice Cloning: Capabilities and Thai Assessment
Index-TTS (by Bilibili) is an open-source zero-shot TTS system with voice cloning:
- **Zero-shot voice cloning**: Requires only a single reference audio clip (5-15 seconds). No fine-tuning or training needed.
- **IndexTTS2** (latest, Sept 2025): Emotionally expressive with duration control. Three-stage training paradigm. Disentangles emotion from speaker identity.
- **Architecture**: Autoregressive GPT latent + BigVGAN vocoder. DeepSpeed acceleration optional.
- **Language support**: Primarily Chinese + English. Cross-lingual modeling exists. Thai is NOT explicitly listed in supported languages.
- **GPU requirement**: CUDA 12.8+ recommended. FP16 inference available for reduced VRAM. This is a GPU-intensive model.
- **License**: Repository is public on GitHub (license file present, specific terms not extracted).
- **Active development**: IndexTTS-1.5 (May 2025), IndexTTS2 (Sept 2025). Active Discord + QQ communities.

**Thai language assessment**:
- Index-TTS does NOT explicitly support Thai. Its training data is primarily Chinese + English.
- For tonal languages like Thai, the autoregressive model could potentially produce Thai speech via cross-lingual transfer, but quality would be uncertain and likely inferior to dedicated Thai TTS.
- Edge-TTS (th-TH, 3 Neural voices) remains the safer choice for Thai in Phase 1.
- **Voice cloning for Thai**: The reference-audio approach could theoretically clone a Thai speaker's voice characteristics, but the underlying phoneme/token model may not handle Thai tones correctly without Thai training data.
- **Recommendation**: Use Edge-TTS for Thai TTS in Phase 1. Monitor Index-TTS for Thai support in future updates. If a Thai-accented expressive voice is critical, investigate fine-tuning Index-TTS on Thai data (advanced, Phase 2+).

[SOURCE: https://github.com/index-tts/index-tts — zero-shot cloning, Bilibili origin, IndexTTS2 Sept 2025, CUDA requirement, Chinese+English primary]
[INFERENCE: Thai assessment based on absence of Thai in documented languages, tonal language complexity, and cross-lingual transfer limitations]

### 6. Pipeline Architecture Assessment (Q3, Q5, Q7 Synthesis)
With the three-service architecture established, the viral-ops pipeline maps directly:

| Pipeline Stage | Service | Endpoint / Mechanism |
|---|---|---|
| Trend signal intake | Dashboard + n8n | Webhook trigger / scheduled n8n workflow |
| Script generation | Pixelle-Video | POST /api/llm/generate_script |
| Image generation | Pixelle-Video | POST /api/image/generate (GPU or RunningHub) |
| TTS synthesis | Pixelle-Video | POST /api/tts/synthesize (Edge-TTS, CPU) |
| Caption generation | Pixelle-Video | (built-in to video composition) |
| Video composition | Pixelle-Video | POST /api/video/compose |
| Upload / distribution | n8n | HTTP Request to platform APIs (TikTok, etc.) |
| Status tracking | n8n + Dashboard | n8n execution history + dashboard DB |
| Affiliate linking | n8n + external | HTTP Request to affiliate API |

**Q3 answer**: The stack supports queue-based jobs via n8n's execution queue (parallel workflow executions) + Pixelle-Video's `/api/tasks/` for async job tracking. Webhook integrations are native to n8n. Background workers = n8n worker mode (available in n8n self-hosted).

**Q5 answer**: Highly extensible. Adding a new video gen engine = new n8n workflow with different HTTP endpoints. Adding upload platforms = new n8n nodes (400+ built-in integrations, many social platforms). Affiliate tracking = HTTP Request node to any REST API.

**Q7 answer**: n8n IS the background job orchestrator. It handles: scheduling (cron triggers), retry logic (built-in), parallel execution, error handling (error workflows), and workflow chaining. No need for BullMQ/pg-boss/Inngest in the dashboard — n8n replaces all of these for the content pipeline.

[INFERENCE: based on Pixelle-Video API endpoints (iteration 4), n8n workflow architecture (this iteration), and pipeline stages from notes-initial.md]

## Ruled Out
- **Building custom job queue in Next.js dashboard**: Not needed. n8n handles all orchestration, scheduling, retries, and background job management. This eliminates the "no job queue" gap identified in iterations 1-2 for next-saas-stripe-starter.
- **Index-TTS for Thai in Phase 1**: Not viable without Thai training data. Edge-TTS (3 Thai Neural voices) is sufficient. Index-TTS is a Phase 2+ consideration if Thai voice cloning becomes a priority.

## Dead Ends
- **Index-TTS for immediate Thai support**: The model is primarily Chinese + English. Thai would require cross-lingual transfer with uncertain quality. This is not a viable Phase 1 path. However, this is NOT permanently blocked — Index-TTS is actively developed and may add Thai support.
- **n8n docs website for detailed technical extraction**: The docs.n8n.io site renders as an SPA with minimal content in fetch responses. GitHub README and direct knowledge of n8n's well-documented API are more productive sources.

## Sources Consulted
- https://raw.githubusercontent.com/n8n-io/n8n/master/README.md — Installation, port 5678, Docker/npm
- https://docs.n8n.io/api/ — REST API documentation structure
- https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest/ — HTTP Request node (SPA, limited content)
- https://github.com/index-tts/index-tts — Index-TTS capabilities, voice cloning, language support
- Iteration 4 findings — Pixelle-Video FastAPI endpoints, Thai TTS voices, port 8000

## Assessment
- New information ratio: 0.83
- Questions addressed: Q3, Q5, Q7, plus Index-TTS Thai assessment and n8n Windows setup
- Questions answered: Q3 (pipeline architecture), Q5 (extensibility), Q7 (background job orchestration)

## Reflection
- What worked and why: Combining n8n's GitHub README (reliable structured data) with Index-TTS GitHub page gave two strong independent sources. Building the glue architecture diagram by synthesizing prior iteration findings with new n8n data produced the most valuable output — the three-service localhost diagram is the key deliverable.
- What did not work and why: n8n docs site (docs.n8n.io) renders as SPA with minimal extractable content. Multiple page fetches returned navigation indexes rather than actual content. GitHub READMEs remain the most reliable web source.
- What I would do differently: For SPA documentation sites, try fetching the raw markdown from the GitHub docs repo instead of the rendered site. For n8n, that would be `https://raw.githubusercontent.com/n8n-io/n8n/master/docs/`.

## Recommended Next Focus
1. **TikTok upload strategy**: Research the TikTok Content Posting API (official) and any community n8n nodes for TikTok. How does a video get from Pixelle-Video output to TikTok?
2. **Database and state design**: With n8n handling orchestration, what does the dashboard database schema look like? Content calendar, video metadata, platform accounts, analytics.
3. **Convergence synthesis**: 7 of 14 questions are now answered (Q1, Q3, Q5, Q7, Q9-Q14). The remaining questions (Q2, Q4, Q6, Q8) are deferred/secondary. Consider a consolidation iteration to synthesize all findings into a final recommendation.
