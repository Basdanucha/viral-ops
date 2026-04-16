# Iteration 12: Multi-Channel Identity & Persona Management (Q27)

## Focus
Investigate how viral-ops should manage multiple channel identities/personas to ensure each channel has a distinct, consistent identity -- preventing algorithm penalties from duplicate/similar content across channels. This directly addresses the user's critical insight: "If all channels produce identical content, algorithms will penalize -- channel identity is core, not a feature."

## Findings

### 1. Pixelle-Video API Supports Per-Request Channel Configuration (All Three Endpoints)
The Pixelle-Video FastAPI router source code confirms that all three critical endpoints accept per-request configuration:

- **TTS (`POST /api/tts/synthesize`)**: Accepts `text`, `workflow` (TTS workflow identifier), `ref_audio` (reference audio for voice cloning), and `voice_id` per request. This means each channel can specify a different voice per API call -- channel A uses `th-TH-NiwatNeural`, channel B uses `th-TH-PremwadeeNeural`, without any global config changes.
- **LLM (`POST /api/llm/chat`)**: Accepts `prompt` and `temperature` per request. System prompt is NOT directly exposed as a parameter -- it is globally configured. This is a **gap**: per-channel persona prompts must be injected at the n8n orchestration layer by prepending the channel's system prompt to the `prompt` field before calling the LLM endpoint.
- **Image (`POST /api/image/generate`)**: Accepts `prompt`, `width`, `height`, and `workflow` (ComfyUI workflow filename) per request. This means each channel can use a different visual style by specifying a different ComfyUI workflow JSON file (e.g., channel A = `flux-cinematic.json`, channel B = `flux-minimal.json`).

**Key architectural insight**: The per-request `workflow` parameter on both TTS and image endpoints is the primary mechanism for channel differentiation at the video generation layer. The LLM endpoint's lack of system prompt parameter means persona injection must happen at the orchestration layer.

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/tts.py]
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/llm.py]
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/image.py]

### 2. TikTok Duplicate Content Detection is Severe and Multi-Layered (2025)
TikTok's 2025 algorithm update uses four detection layers that make same-content-across-channels extremely risky:

1. **Visual Analysis**: AI-based image recognition, scene matching, and object detection scan for visual similarities even after cropping, filtering, or color-adjusting. Scene recognition analyzes camera angles, object placement, background settings, and visual flow patterns.
2. **Audio Fingerprinting**: Identifies identical or similar soundtracks by analyzing pitch, timing, and audio patterns. Changing visuals but keeping same audio is detected.
3. **C2PA Metadata Tracking**: Traces content origins, editing history, and cross-platform reposts by analyzing file creation dates, device information, and editing software signatures.
4. **Behavioral Analysis**: Examines synchronized posting patterns, repeated captions, and network coordination across accounts. Detects clusters of accounts sharing identical or near-identical content.

**Penalties**: Range from reach suppression (shadowban within 1-6 hours of posting) to permanent account bans. TikTok's May 2025 IP Rights report documented 16,000+ permanent bans and 550,000+ video removals for IP/duplication violations in a six-month period. Penalties affect not just the flagged video but the entire account's future visibility.

**Critical for viral-ops**: Posting the same video on multiple TikTok accounts is explicitly detected and penalized. Even "slightly edited" reposts are caught with 90%+ accuracy using perceptual hashing and deep learning.

[SOURCE: https://napolify.com/blogs/news/duplicate-content-detection (via WebSearch summary)]
[SOURCE: https://napolify.com/blogs/news/tiktok-duplicate-penalty (via WebSearch summary)]

### 3. Differentiation Requirements: What Must Be Different Per Channel
Based on the detection technology analysis, the minimum differentiation needed between channels to avoid algorithm penalties:

| Dimension | Same OK? | Must Differ? | Why |
|-----------|----------|-------------|-----|
| Topic/niche | Yes (same niche OK) | Prefer different sub-niches | Same broad niche is fine; exact same product/topic risky |
| Script/hooks | NO | YES | Audio fingerprinting + behavioral analysis catches same scripts |
| Voice/TTS | NO | YES | Audio fingerprinting identifies identical voice signatures |
| Visual style | Partially | YES | Scene matching detects same composition patterns |
| ComfyUI workflow | N/A | YES | Different workflows = different visual output = avoids visual fingerprinting |
| Background music | NO | YES | Audio fingerprinting catches identical soundtracks |
| Posting schedule | N/A | STAGGER | Synchronized posting triggers behavioral analysis |
| Captions/text overlays | NO | YES | Text detection is part of scene analysis |

**Bottom line**: Each channel MUST produce fundamentally different video output. Same topic is acceptable, but the script, voice, visual style, and posting time must all differ. This validates the user's insight that channel identity is core architecture, not a feature toggle.

[SOURCE: https://napolify.com/blogs/news/duplicate-content-detection (via WebSearch summary)]
[SOURCE: https://houseofmarketers.com/stop-duplicate-content-go-viral-tiktok-algorithm/]

### 4. Per-Channel Persona DB Schema Design
Based on the README's per-channel requirements and the Pixelle-Video API capabilities confirmed in Finding 1, the `channels` table schema:

```sql
CREATE TABLE channels (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          VARCHAR(100) NOT NULL,           -- "SaraHealth", "TechBroThai"
  slug          VARCHAR(50) UNIQUE NOT NULL,      -- URL-safe identifier
  niche         VARCHAR(100) NOT NULL,           -- "health-fitness", "tech-gadgets"
  sub_niche     VARCHAR(100),                    -- "weight-loss-thai", "budget-phones"
  target_audience TEXT NOT NULL,                  -- "Thai women 25-40 interested in diet"
  
  -- Pixelle-Video per-request config
  tts_voice     VARCHAR(100) NOT NULL,           -- "th-TH-PremwadeeNeural"
  tts_workflow  VARCHAR(100),                    -- Custom TTS workflow if any
  comfyui_workflow VARCHAR(100) NOT NULL,        -- "flux-cinematic.json"
  image_width   INT DEFAULT 1080,
  image_height  INT DEFAULT 1920,
  
  -- LLM persona config (injected by n8n, not Pixelle-Video)
  persona_name  VARCHAR(100) NOT NULL,           -- "Sara", "TechBro"
  persona_prompt TEXT NOT NULL,                  -- Full system prompt for LLM
  tone_adjectives VARCHAR(255),                  -- "friendly,warm,expert"
  language_register VARCHAR(20) DEFAULT 'informal', -- formal/informal/slang
  forbidden_topics TEXT[],                        -- ["politics","religion"]
  preferred_hooks VARCHAR(20)[] DEFAULT '{}',     -- ["curiosity","fear","humor"]
  
  -- Content calendar
  posting_frequency JSONB NOT NULL DEFAULT '{}', -- {"tiktok": "3/day", "youtube": "1/day"}
  best_times       JSONB NOT NULL DEFAULT '{}',  -- {"tiktok": ["09:00","12:00","19:00"]}
  timezone         VARCHAR(50) DEFAULT 'Asia/Bangkok',
  
  -- Brand rules
  brand_rules   TEXT NOT NULL DEFAULT '',         -- "never use profanity; always mention benefits first"
  monetization_mode VARCHAR(20) NOT NULL,         -- 'viral-only' | 'cart-focused' | 'mixed'
  approval_mode VARCHAR(20) NOT NULL DEFAULT 'manual', -- 'auto' | 'manual' | 'experimental'
  
  -- Metadata
  is_active     BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- Link channels to platform accounts (many-to-many)
CREATE TABLE channel_platform_accounts (
  channel_id    UUID REFERENCES channels(id),
  platform_account_id UUID REFERENCES platform_accounts(id),
  PRIMARY KEY (channel_id, platform_account_id)
);

-- Persona prompt versioning (track changes over time)
CREATE TABLE channel_persona_history (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id    UUID REFERENCES channels(id),
  persona_prompt TEXT NOT NULL,
  version       INT NOT NULL,
  changed_reason VARCHAR(255),
  created_at    TIMESTAMPTZ DEFAULT now()
);
```

**Design rationale**:
- `tts_voice` + `comfyui_workflow` map directly to Pixelle-Video per-request parameters (Finding 1)
- `persona_prompt` stored in DB and injected by n8n (not Pixelle-Video) because LLM endpoint lacks system prompt param
- `preferred_hooks` as array enables the Viral Brain to weight hook selection per channel
- `posting_frequency` and `best_times` as JSONB because different platforms have different optimal schedules
- `channel_persona_history` enables tracking prompt versions -- essential for correlating persona changes with performance shifts
- `forbidden_topics` and `brand_rules` serve as negative constraints for LLM prompt engineering

[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/tts.py -- voice_id per request]
[SOURCE: https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/image.py -- workflow per request]
[INFERENCE: based on Pixelle-Video API capabilities + TikTok detection requirements + README channel spec]

### 5. N8N Workflow Architecture: Single Universal Pipeline with Channel Config Injection
The recommended architecture is a **single universal n8n pipeline with dynamic channel config injection**, not separate workflows per channel:

**Why single pipeline, not per-channel workflows**:
- Separate workflows create maintenance nightmare (N channels x M pipeline steps = N*M nodes to maintain)
- Bug fixes must be replicated across all channel workflows
- Single pipeline with channel-specific parameters is the standard pattern for multi-brand content automation

**n8n implementation pattern**:
```
[Cron Trigger per channel] 
    → [DB Lookup: channels WHERE is_active AND next_post_due] 
    → [Loop over due channels]
        → [HTTP Request: POST /api/llm/chat with channel.persona_prompt prepended to prompt]
        → [HTTP Request: POST /api/tts/synthesize with channel.tts_voice]
        → [HTTP Request: POST /api/image/generate with channel.comfyui_workflow]
        → [HTTP Request: POST /api/video/compose]
        → [Branch by channel.approval_mode]
            → auto: [Schedule upload at channel.best_times]
            → manual: [Queue for dashboard review]
```

**Channel config injection method**: n8n's HTTP Request node sends the channel-specific parameters in the request body. The channel config is loaded from PostgreSQL at the start of each pipeline run via n8n's built-in Postgres node.

**Scheduling**: Each channel has its own cron expression derived from `posting_frequency` and `best_times`. n8n supports dynamic cron expressions, so the dashboard can update schedules without redeploying workflows. For a channel posting to 4 platforms vs 1 platform, the upload step branches using n8n's Switch node based on the channel's linked platform accounts.

**Staggered posting**: To avoid TikTok's synchronized posting detection (Finding 2), uploads for different channels on the same platform are staggered by 15-30 minute intervals using n8n's Wait node.

[SOURCE: n8n HTTP Request node architecture from iteration 5]
[SOURCE: TikTok behavioral analysis detection from Finding 2]
[INFERENCE: based on n8n capabilities + multi-brand automation patterns + anti-fingerprinting requirements]

### 6. LLM System Prompt Structure for Per-Channel Persona Consistency
A structured per-channel system prompt template that ensures consistent persona output over time:

```
You are {persona_name}, a {tone_adjectives} content creator for the {niche} niche on {platform}.

## Identity
- Name: {persona_name}
- Audience: {target_audience}
- Language: Thai ({language_register} register)
- Niche expertise: {sub_niche}

## Voice Rules
- Tone: {tone_adjectives}
- Hook preferences: {preferred_hooks} (use these hook patterns most often)
- NEVER use these hooks: {inverse of preferred_hooks for other channels}
- Language style: {"Use casual Thai with trending slang" | "Use polished Thai with minimal slang" | etc.}

## Brand Rules
{brand_rules}

## Forbidden Topics
NEVER mention or reference: {forbidden_topics}

## Output Format
Generate a viral short-form video script with:
1. Hook (first 3 seconds) -- use one of: {preferred_hooks}
2. Value delivery (15-45 seconds)
3. CTA (last 5 seconds)

## Anti-Duplication Rules
- This script must be UNIQUE to this channel.
- Do NOT reuse hooks, phrases, or structures from other channels.
- Channel signature phrase: "{channel_signature_phrase}"
```

**Key design decisions**:
- `preferred_hooks` per channel ensures different channels use different hook patterns (curiosity vs fear vs humor), which directly addresses the audio fingerprinting concern
- `language_register` differentiates formal Thai from slang-heavy Thai, creating distinct vocal identities
- `forbidden_topics` prevents cross-channel content bleeding
- Anti-duplication rules in the prompt itself serve as a final safety net
- Prompt versioning via `channel_persona_history` table enables A/B testing of persona configurations and correlating persona changes with performance metrics

**Storage recommendation**: Store in database (`channels.persona_prompt`), not in files. Rationale: the dashboard needs to edit personas without deploying code, and persona versioning requires DB tracking for performance correlation.

[SOURCE: https://www.mirra.my/en/blog/ai-persona-marketing-brand-voice-guide-2026 -- workspace-based persona settings pattern]
[SOURCE: https://www.atomwriter.com/blog/ai-brand-voice-b2b-saas/ -- brand voice consistency methodology]
[INFERENCE: based on LLM system prompt engineering patterns + TikTok anti-duplication requirements]

## Ruled Out
- **Pixelle-Video LLM endpoint for direct system prompt injection**: The `/api/llm/chat` endpoint does NOT expose a `system_prompt` parameter. Persona prompts must be prepended to the `prompt` field at the n8n orchestration layer. This is a workaround, not a limitation -- the LLM still receives the full persona context.
- **Separate n8n workflows per channel**: Maintenance overhead scales linearly with channel count. A single universal pipeline with dynamic config injection is the standard pattern for multi-brand automation.

## Dead Ends
None this iteration -- all research avenues produced useful results.

## Sources Consulted
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/tts.py (TTS endpoint schema)
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/llm.py (LLM endpoint schema)
- https://raw.githubusercontent.com/AIDC-AI/Pixelle-Video/main/api/routers/image.py (Image endpoint schema)
- https://github.com/AIDC-AI/Pixelle-Video/tree/main/api/routers (router directory listing)
- https://napolify.com/blogs/news/duplicate-content-detection (TikTok fingerprinting tech)
- https://napolify.com/blogs/news/tiktok-duplicate-penalty (TikTok penalty data)
- https://houseofmarketers.com/stop-duplicate-content-go-viral-tiktok-algorithm/ (differentiation requirements)
- https://www.mirra.my/en/blog/ai-persona-marketing-brand-voice-guide-2026 (AI persona marketing patterns)
- https://www.atomwriter.com/blog/ai-brand-voice-b2b-saas/ (brand voice consistency)

## Assessment
- New information ratio: 0.92
- Questions addressed: [Q27]
- Questions answered: [Q27]

## Reflection
- What worked and why: Fetching Pixelle-Video router source code directly from GitHub raw URLs gave definitive per-request API capability data that no README or documentation page would have shown. The two WebSearch queries produced complementary results -- one for the content automation pattern (persona management) and one for the technical detection mechanisms (fingerprinting).
- What did not work and why: Napolify blocks automated fetches (403), but the WebSearch summaries from their articles were sufficiently detailed to extract the technical fingerprinting information. The initial WebFetch on app.py only showed router mounts, not implementations -- had to discover the actual router filenames via the GitHub directory listing.
- What I would do differently: Start with the GitHub directory listing to discover exact filenames before attempting raw file fetches, avoiding the 404 errors on incorrectly guessed filenames.

## Recommended Next Focus
All 27 key questions (Q1-Q27) are now addressed. The recommended next iteration is a **final convergence synthesis** to:
1. Integrate multi-channel identity architecture into the complete system diagram
2. Produce the definitive DB schema combining all tables from iterations 6, 7, 10, 11, and 12
3. Update the comprehensive architecture recommendation covering all pipeline stages including Path A, Path B, and multi-channel management
4. Identify remaining Phase 2+ considerations and open design decisions
