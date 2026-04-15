# Initial Research Notes

Starting references collected during scaffold/exploration (before formal `/research` flow). Use these as seeds when running `/research create` in Claude Code.

## User-provided leads

**Video generation / benchmarks:**
- <https://github.com/AIDC-AI/Pixelle-Video> — ComfyUI-based short video engine (Apache 2.0)
- <https://github.com/gyoridavid/short-video-maker> — Remotion + Whisper + Kokoro TTS, MCP server built-in (MIT)
- <https://www.autofeed.ai/> — commercial text-to-video + auto-post (reference/benchmark)

**TikTok uploaders:**
- <https://github.com/haziq-exe/TikTokAutoUploader> — Python + Phantomwright, scheduling, Telegram bot, multi-account (active Feb 2026)
- <https://github.com/makiisthenes/TiktokAutoUploader> — requests-based, no Selenium (CLI, automated video edit)
- <https://github.com/wkaisertexas/tiktok-uploader> — cookie-based auth, duplicates browser session

**Discussion / competitor landscape:**
- <https://www.reddit.com/r/n8n_ai_agents/comments/1qm9ntu/> — "fully automated AI video factory" (n8n workflow discussion)
- <https://autofaceless.ai/blog/autofeed-ai-alternatives> — AutoFeed alternatives
- <https://www.reddit.com/r/DigitalMarketing/comments/1ovkqa7/> — "tested 6 AI text-to-video tools" ranking

## Discovered while searching

### Video generation (OSS)
- [short-video-maker (gyoridavid)](https://github.com/gyoridavid/short-video-maker) — MIT, 1.1k★, MCP-ready
- [TikTok-Forge (ezedinff)](https://github.com/ezedinff/TikTok-Forge) — MIT, Remotion + n8n + OpenAI + Postgres + MinIO
- [Pixelle-Video (AIDC-AI)](https://github.com/AIDC-AI/Pixelle-Video) — Apache 2.0, ComfyUI-based
- [Shotty](https://www.scriptbyai.com/short-video-generator-tiktok-instagram/) — TikTok/IG-specific
- [ClawVid (Remotion + fal.ai pipeline)](https://medium.com/composiohq/i-built-a-faceless-ai-video-pipeline-using-openclaw-composio-remotion-clawvid-heres-05618dc79705) — tutorial + pattern

### Multi-platform upload (non-TikTok)
TikTok uploaders now listed under "User-provided leads" above.
- YouTube Shorts: official Google YouTube Data API
- Instagram / Facebook Reels: Meta Graph API
- [upload-post.com](https://upload-post.com/) — paid unified API for 5 platforms (used in n8n workflow 3442)

### TikTok Shop affiliate
- [Lundehund/tiktok-shop-api](https://github.com/Lundehund/tiktok-shop-api) — Python unofficial
- [ipfans/tiktok](https://github.com/ipfans/tiktok) — Go SDK official Open Platform
- [EcomPHP/tiktokshop-php](https://github.com/EcomPHP/tiktokshop-php) — PHP, API v202309+

### n8n workflows (orchestration reference)
- [3442: Full AI video gen + multi-platform publishing (5 platforms)](https://n8n.io/workflows/3442-fully-automated-ai-video-generation-and-multi-platform-publishing/) — Google Sheets + OpenAI + PiAPI (Flux + Kling) + ElevenLabs + Creatomate + upload-post.com
- [5338: Seedance + TT/YT/IG](https://n8n.io/workflows/5338-generate-ai-viral-videos-with-seedance-and-upload-to-tiktok-youtube-and-instagram/)
- [10212: Sora 2 → TikTok](https://n8n.io/workflows/10212-generate-funny-ai-videos-with-sora-2-and-auto-publish-to-tiktok/)

### Commercial (benchmark/UX reference only — not deps)
- [AutoFeed.ai](https://www.autofeed.ai/) — $9-109/mo, 13 AI models, text-to-video + auto-post
- [AutoFaceless.ai](https://autofaceless.ai/) — credits-based, 50k viral hooks analyzed, YT Shorts auto
- ShortsPro, Pictory, VideoGen — range $9-99/mo

## Pattern observed across leads

```
Topic → Script (LLM) → Visuals (Flux/Kling/Sora/Veo OR Pexels stock)
       → TTS (ElevenLabs/Kokoro) → Captions (Whisper)
       → Composition (Remotion/Creatomate/FFmpeg)
       → Multi-platform upload (upload-post.com OR platform-specific APIs)
       → Affiliate pin (TikTok Shop / Meta Shop)
```

## Open questions to resolve via `/research`

1. Video gen: self-host (short-video-maker/Pixelle) vs API-based (fal.ai/Sora)?
2. Orchestration: n8n (visual, existing workflows) vs custom (code-first, more control)?
3. Upload: build per-platform (direct APIs) vs use upload-post.com (paid unified API)?
4. Voice: English-only (Kokoro) vs multi-lingual (ElevenLabs paid)?
5. Thai language support: where's the gap? (most OSS assumes EN)
6. Affiliate pin UX: how does "ปักตะกร้า" actually work per platform, what's the API surface?

## Next

Start structured research in Claude Code:
```
/research create viral-ops stack decision
```
