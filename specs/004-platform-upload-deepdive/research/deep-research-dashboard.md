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
- Topic: Upload per-platform deep dive — auth flows (OAuth/API keys/scopes/token refresh), rate limits (quotas, throttling, backoff), content specs (video format/resolution/aspect ratio/file size/duration), error handling (error codes, retry strategies, failover patterns) for TikTok, YouTube, Instagram, Facebook
- Started: 2026-04-17T15:30:00Z
- Status: INITIALIZED
- Iteration: 7 of 20
- Session ID: dr-004-platform-upload
- Parent Session: none
- Lifecycle Mode: new
- Generation: 1
- continuedFromRun: none

<!-- /ANCHOR:status -->
<!-- ANCHOR:progress -->
## 3. PROGRESS

| # | Focus | Track | Ratio | Findings | Status |
|---|-------|-------|-------|----------|--------|
| 1 | Platform API Survey -- TikTok Content Posting API & YouTube Data API v3 | platform-api-survey | 0.83 | 6 | complete |
| 2 | Instagram Graph API & Facebook Video API -- Platform Survey Completion | platform-api-survey | 0.94 | 8 | complete |
| 3 | Video Content Specs (Q5) & Rate Limits Deep Dive (Q6) | content-specs-rate-limits | 0.72 | 9 | complete |
| 4 | Error Handling Patterns (Q7) & Token Management (Q8) | error-handling-tokens | 0.79 | 7 | complete |
| 5 | Platform-specific quirks (Q9) and n8n integration patterns (Q10) | platform-quirks-n8n | 0.79 | 7 | complete |
| 6 | Upload queue architecture (Q11) and Multi-account management (Q12) | queue-architecture-multi-account | 0.71 | 7 | complete |
| 7 | Formal closure of Q1-Q4 -- sub-gap fill (account types, scheduling, content types, regular video upload) | platform-auth-gaps | 0.69 | 8 | complete |

- iterationsCompleted: 7
- keyFindings: 235
- openQuestions: 12
- resolvedQuestions: 0

<!-- /ANCHOR:progress -->
<!-- ANCHOR:questions -->
## 4. QUESTIONS
- Answered: 0/12
- [ ] Q1: TikTok Content Posting API — what is the official OAuth 2.0 flow (scopes, token lifecycle, Creator vs Business account differences)? How does TikTokAutoUploader compare to official API?
- [ ] Q2: YouTube Data API v3 upload — resumable upload flow, OAuth scopes, quota cost per upload, daily quota limits, publishAt scheduling details?
- [ ] Q3: Instagram Graph API video upload — 2-step container flow (create + publish), OAuth/long-lived token lifecycle, rate limits (200 calls/user/hour), Reels vs Feed video differences?
- [ ] Q4: Facebook Video API — 3-step upload (init + transfer + finish), page access token vs user token, rate limits, Reels vs regular video, Business Suite vs Graph API?
- [ ] Q5: Video content specs per platform — exact codec (H.264/HEVC), resolution limits, aspect ratios, file size caps, duration min/max, thumbnail requirements, caption/subtitle formats?
- [ ] Q6: Rate limits deep dive — per-platform daily/hourly quotas, upload-specific rate limits vs general API limits, how to detect rate limiting (HTTP status codes, headers)?
- [ ] Q7: Error handling patterns — common error codes per platform, retry strategies (exponential backoff, jitter), idempotency (can you retry a failed upload?), partial upload recovery?
- [ ] Q8: Token management — refresh token rotation policies per platform, token storage security, multi-account token management, token expiration handling in n8n?
- [ ] Q9: Platform-specific quirks — TikTok duplicate detection (4-layer), Instagram container expiry, YouTube processing states, Facebook encoding requirements?
- [ ] Q10: n8n integration patterns — how to implement upload workflows in n8n (HTTP Request nodes, OAuth2 credentials, error branches, retry logic), per-platform n8n workflow templates?
- [ ] Q11: Upload queue architecture — how upload_queue table integrates with n8n, priority scheduling, staggered posting (15-30min), failure retry with backoff, status tracking?
- [ ] Q12: Multi-account management — how platform_accounts table connects to OAuth tokens, per-channel credentials, token rotation across multiple accounts?

<!-- /ANCHOR:questions -->
<!-- ANCHOR:trend -->
## 5. TREND
- Last 3 ratios: 0.79 -> 0.71 -> 0.69
- Stuck count: 0
- Guard violations: none recorded by the reducer pass
- convergenceScore: 0.69
- coverageBySources: {"code":2,"community.n8n.io":1,"developers.facebook.com":6,"developers.google.com":7,"developers.tiktok.com":7,"docs.n8n.io":12,"flowgenius.in":1,"github.com":3,"googleapis.github.io":2,"napolify.com":2,"other":1,"support.google.com":1,"www.musicbusinessworldwide.com":1,"www.tokportal.com":2}

<!-- /ANCHOR:trend -->
<!-- ANCHOR:dead-ends -->
## 6. DEAD ENDS
- None for this iteration (first survey pass) (iteration 1)
- None identified yet (iteration 1)
- None. All four research actions (4 WebFetch calls to official Meta docs) returned substantive data. (iteration 2)
- The access token guide does not document Instagram-specific token considerations separately -- they share the same Meta token infrastructure. (iteration 2)
- The generic Facebook Video API publishing guide (`/docs/video-api/guides/publishing`) describes the upload-session protocol but omits video-specific rate limits, codec requirements, and resolution specs. The Reels-specific page is far more complete for our use case. (iteration 2)
- Looking for standardized `X-RateLimit-*` headers across platforms -- none of the 4 platforms document these standard headers. Rate limit detection is platform-specific via error codes. (iteration 3)
- Searching for unified rate limit header standards across social platforms -- each uses a proprietary signaling mechanism. A cross-platform upload system must implement per-platform rate limit detection logic. (iteration 3)
- TikTok's Direct Post API reference page (`content-posting-api-reference-direct-post`) for video specs -- it focuses on API workflow, not technical specs. The Media Transfer Guide is the correct source for TikTok video specifications. (iteration 3)
- Looking for Instagram-specific error codes separate from the Meta Graph API system -- Instagram uses the exact same error code system as Facebook (confirmed in Finding 4). No separate error catalog exists. (iteration 4)
- Looking for YouTube resume URI persistence documentation in the official upload guide -- Google's sample code focuses on the client library abstraction and does not expose the raw resume URI lifecycle. (iteration 4)
- **YouTube resume URI internals**: The official Google documentation deliberately abstracts resume URI management into the client library. For n8n HTTP Request nodes, we would need to reverse-engineer the Google API client or use the raw Resumable Upload Protocol (not documented in the YouTube-specific docs, but available in the generic Google API upload docs at a different URL). This is a gap that should be investigated in a future iteration focused on n8n integration (Q10). (iteration 4)
- **n8n built-in TikTok node**: Does not exist. The community node (`@igabm/n8n-nodes-tiktok`) is abandoned and non-functional. HTTP Request with OAuth2 is the only viable path. (iteration 5)
- **n8n Retry On Fail with Continue Error Output**: These settings conflict -- retries are silently ignored when any Continue option is enabled. Must use either retries OR error branching, not both. (iteration 5)
- **Pre-upload duplicate detection for TikTok**: No API endpoint or tool exists to check if content will be flagged as duplicate before uploading. Detection is entirely post-upload at the moderation layer. This is a fundamental limitation for any upload automation system. (iteration 5)
- **TikTok duplicate detection via API error codes**: The API does not return a specific "duplicate content detected" error. Duplicate detection operates at the content moderation layer post-upload, separate from the API response. There is no pre-upload duplicate check endpoint. (iteration 5)
- **n8n built-in retry for upload error handling**: Confirmed again -- the Retry On Fail + Continue Error Output bug (iteration 5) means all retry logic must be queue-level (database status + scheduled_at manipulation), not node-level. (iteration 6)
- **n8n webhook trigger for queue processing**: Webhooks trigger immediately on external calls, bypassing priority ordering and rate limit checks. Cron-poll is the correct pattern for a queue with priority and scheduling semantics. (iteration 6)
- None identified this iteration. All design decisions are constructive (no external sources returned "this approach doesn't work"). (iteration 6)
- **Facebook Business Suite API integration**: Business Suite scheduling is UI-only. No programmatic API for Business Suite scheduling features exists for third-party apps. (iteration 7)
- **Facebook regular video scheduling via Graph API**: No `scheduled_publish_time` parameter exists for regular video uploads. Only Reels support native scheduling. Regular video scheduling must be handled at the queue level. (iteration 7)
- **Instagram standalone feed video upload**: Feed videos can only exist as carousel items (`is_carousel_item=true`). There is no standalone feed video upload -- use Reels for single video posts. (iteration 7)
- **TikTok Creator vs Business account API differences**: The Content Posting API does not differentiate between account types. The distinction is at the app level (audited vs unaudited), not the account level. (iteration 7)
- **YouTube publishAt maximum scheduling window**: No maximum documented. Attempted to find limits in both official docs and Java client library reference -- none exist. This is either unlimited or undocumented. (iteration 7)

<!-- /ANCHOR:dead-ends -->
<!-- ANCHOR:next-focus -->
## 7. NEXT FOCUS
With Q1-Q12 now all formally addressed, the next iteration should be a **convergence/synthesis iteration** to: (1) verify all 12 questions have complete answers, (2) close out open gaps in research.md Section 10, and (3) produce a final consolidated view suitable for implementation planning.

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
