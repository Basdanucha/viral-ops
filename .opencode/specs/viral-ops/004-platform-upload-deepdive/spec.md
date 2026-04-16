# Spec: Upload Per-Platform Deep Dive

## Requirements
<!-- DR-SEED:REQUIREMENTS -->
Deep dive research into per-platform upload mechanics for viral-ops — covering OAuth/auth flows, rate limits, video content specifications, and error handling patterns for TikTok, YouTube, Instagram, and Facebook. Extends Layer 5 (Distribution) from the base architecture research (specs/001-base-app-research).

## Scope
<!-- DR-SEED:SCOPE -->
- TikTok Content Posting API vs TikTokAutoUploader — auth, upload flow, rate limits, quirks
- YouTube Data API v3 — resumable upload, quota system, scheduling
- Instagram Graph API — container-based upload, Reels vs Feed, token management
- Facebook Video API — 3-step upload, Reels, Business Suite integration
- Video content specs per platform (codec, resolution, aspect ratio, file size, duration)
- Error handling patterns (error codes, retry strategies, backoff, idempotency)
- Token management and multi-account handling
- n8n integration patterns for upload workflows
- Upload queue architecture and staggered posting

## Open Questions
All 12 questions answered across 7 autonomous iterations.

## Research Context
Deep research **complete**. Canonical findings in `research/research.md` (700+ lines).

<!-- BEGIN GENERATED: deep-research/spec-findings -->
## Research Findings Summary (7 iterations, 12 questions)

### Per-Platform Upload Comparison
| Platform | Auth | Upload Flow | Rate Limit | Max Size | Max Duration |
|----------|------|-------------|-----------|----------|-------------|
| **TikTok** | OAuth 2.0+PKCE (24h/365d) | FILE_UPLOAD (chunked) or PULL_FROM_URL | 6 req/min upload init | 4GB | 10 min |
| **YouTube** | Google OAuth (1h/permanent refresh) | Resumable (videos.insert) | 100 quota/upload (10K daily) | 256GB | 12h |
| **Instagram** | Meta OAuth (short→long→page) | 2-step container (create+publish) | 400 containers/24h | 1GB | 15 min (Reels) |
| **Facebook** | Meta OAuth (page token permanent) | 3-phase Reels (start/transfer/finish) | 30 Reels/Page/24h | 1GB | 90s (Reels) |

### Key Architectural Decisions
1. **Use official TikTok API** over TikTokAutoUploader (HIGH ban risk, TOS violation)
2. **YouTube only platform with native n8n node** — all others use HTTP Request + Generic OAuth2
3. **Instagram 24h container expiry** — upload queue must track timestamps, prioritize near-expiry
4. **Facebook Pages-only, Reels-favored** — no regular video scheduling via API
5. **rate_limit_tracker table required** — per-account, per-limit-type, joined in dequeue query
6. **n8n Retry On Fail bug** — silently ignored with Continue Error Output, must implement manual retry
7. **Token dual-storage sync** — n8n credentials + platform_accounts sync via n8n API
8. **Content must be genuinely unique per platform** — TikTok 4-layer duplicate detection (visual+audio+metadata+behavioral)

### Upload Queue Architecture
```
Schedule Trigger (2min) → Postgres query (priority DESC, check rate_limit_tracker)
  → Loop → Switch (platform) → Execute Sub-Workflow (per-platform upload)
    → Success: status='completed', INSERT platform_publishes
    → Failure: Tier 1 retry (backoff) | Tier 2 wait (rate reset) | Tier 3 fail (alert)
```

### Staggered Posting Order
TikTok T+0 → Instagram T+20min → YouTube T+40min (publishAt) → Facebook T+60min

### 3-Tier Retry Strategy
| Tier | Error Type | Strategy | Max Retries |
|------|-----------|----------|-------------|
| 1 | Server/network (5xx) | Exponential backoff + jitter | 5-10 |
| 2 | Rate limits | Fixed delay, wait for reset | 3 |
| 3 | Auth/validation/policy | Fail fast, alert operator | 0 |

### Ruled Out
- TikTokAutoUploader for production (HIGH ban risk)
- Facebook regular video scheduling via API (not available)
- Instagram standalone feed video upload (carousel-only)
- n8n built-in Retry On Fail with Continue Error Output (bug)
- Standard X-RateLimit-* headers (no platform uses them)
- TikTok Creator vs Business account API differences (none exist)
<!-- END GENERATED: deep-research/spec-findings -->
