# Deep Research Strategy - Session Tracking

<!-- ANCHOR:overview -->
## 1. OVERVIEW

### Purpose
Deep dive into per-platform upload mechanics for viral-ops — covering auth flows, rate limits, content specifications, and error handling for all 4 target platforms (TikTok, YouTube, Instagram, Facebook).

### Usage
- **Init:** Orchestrator creates this file with topic, key questions, known context
- **Per iteration:** Agent reads Next Focus, writes iteration evidence, reducer refreshes machine-owned sections
- **Mutability:** Mutable — analyst-owned sections stable, machine-owned sections rewritten by reducer

---

<!-- /ANCHOR:overview -->
<!-- ANCHOR:topic -->
## 2. TOPIC
Upload per-platform deep dive — auth flows (OAuth/API keys/scopes/token refresh), rate limits (quotas, throttling, backoff), content specs (video format/resolution/aspect ratio/file size/duration), error handling (error codes, retry strategies, failover patterns) for TikTok, YouTube, Instagram, Facebook. Building on gen1 architecture from `specs/001-base-app-research`.

---

<!-- /ANCHOR:topic -->
<!-- ANCHOR:key-questions -->
## 3. KEY QUESTIONS (remaining)
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

<!-- /ANCHOR:key-questions -->
<!-- ANCHOR:non-goals -->
## 4. NON-GOALS
- Implementation code (this is research only)
- Shopping/affiliate integration (covered separately in gen1 Layer 6)
- Analytics API integration (covered in gen1 Layer 7)
- Content generation pipeline (covered in gen1 Layer 4 + spec 003)
- Trend discovery mechanics (covered in gen1 Layer 1-2)

---

<!-- /ANCHOR:non-goals -->
<!-- ANCHOR:stop-conditions -->
## 5. STOP CONDITIONS
- All 12 questions answered with platform-specific details
- Auth flows documented with exact OAuth endpoints + scopes per platform
- Rate limits documented with exact numbers per platform
- Content specs documented with exact format requirements per platform
- Error handling patterns defined with retry strategies

---

<!-- /ANCHOR:stop-conditions -->
<!-- ANCHOR:answered-questions -->
## 6. ANSWERED QUESTIONS
[None yet]

<!-- /ANCHOR:answered-questions -->
<!-- MACHINE-OWNED: START -->
<!-- ANCHOR:what-worked -->
## 7. WHAT WORKED
- Fetching official developer documentation pages directly yielded high-quality structured data. The TikTok token management page was particularly rich with exact numeric values (24h access, 365d refresh). YouTube quota page provided exact unit costs. (iteration 1)
- Targeting specific Meta developer doc pages (media reference, reels-publishing, access-tokens) yielded dense structured data with exact numbers. The Reels publishing page was exceptionally well-structured with error codes, specs, and rate limits all on one page. (iteration 2)
- Targeting the TikTok Media Transfer Guide (referenced from the Direct Post API page) yielded the specific video specs that were missing from the API reference page. YouTube's support page (not API docs) had the detailed codec/bitrate tables. Following documentation cross-references proved more productive than guessing URLs. (iteration 3)
- Combining official API documentation fetches (YouTube videos resource, Instagram media reference) with web search for community-sourced knowledge (TikTok duplicate detection, n8n error handling patterns) yielded complementary data. YouTube's official docs were exceptionally well-structured for processing states. The web search for TikTok duplicate detection surfaced rich community analysis that the official API docs completely lack. (iteration 5)
- Synthesizing prior iteration findings (rate limits from iter 1-3, error tiers from iter 4, n8n patterns from iter 5) with gen1 DB schema produced a concrete architectural design. The gen1 schema was the most valuable source -- it provided the exact fields, relationships, and constraints to design around. The queue architecture is essentially a state machine layered on top of the existing `upload_queue` table with n8n as the execution engine. (iteration 6)
- Combining official doc fetches (4 parallel WebFetch calls) with targeted web searches (2 calls) provided both authoritative specs and gap-filling context. The Instagram media reference page was exceptionally dense -- one fetch yielded Reels vs Stories vs Carousel differences, container polling, and account type information all at once. (iteration 7)

<!-- /ANCHOR:what-worked -->
<!-- ANCHOR:what-failed -->
## 8. WHAT FAILED
- Some documentation pages are fragmented -- TikTok splits content posting, token management, and rate limits across many separate pages, making it hard to get a complete picture in one fetch. YouTube upload guide focuses on code samples rather than specifications. (iteration 1)
- The generic Video API publishing guide was sparse on video-specific details (no codec/resolution/rate limits) -- it describes a general file upload protocol rather than video publishing specifics. This is likely because Meta separates "upload infrastructure" from "content type specs." (iteration 2)
- The TikTok Direct Post API reference page was workflow-focused, not spec-focused. Had to make a second fetch to the Media Transfer Guide to get actual video specifications. (iteration 3)
- Two source pages returned HTTP 403 (Napolify article, gwaa.net article) -- these sites likely block automated fetching. The n8n documentation pages rendered with truncated content, missing the detailed configuration fields. n8n's docs appear to use client-side rendering that doesn't fully expose to WebFetch. (iteration 5)
- n8n documentation pages continue to render with minimal content (client-side rendering issue). However, this was less impactful than prior iterations because the architectural design relies more on synthesizing known constraints (rate limits, error tiers, token lifecycles) than on discovering new n8n features. (iteration 6)
- TikTok official docs do not document Creator vs Business differences at all -- the distinction simply does not exist for the Content Posting API. YouTube publishAt scheduling window limits are not documented anywhere (tried official docs, Java client lib, Python client lib). (iteration 7)

<!-- /ANCHOR:what-failed -->
<!-- ANCHOR:exhausted-approaches -->
## 9. EXHAUSTED APPROACHES (do not retry)
### **Facebook Business Suite API integration**: Business Suite scheduling is UI-only. No programmatic API for Business Suite scheduling features exists for third-party apps. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **Facebook Business Suite API integration**: Business Suite scheduling is UI-only. No programmatic API for Business Suite scheduling features exists for third-party apps.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Facebook Business Suite API integration**: Business Suite scheduling is UI-only. No programmatic API for Business Suite scheduling features exists for third-party apps.

### **Facebook regular video scheduling via Graph API**: No `scheduled_publish_time` parameter exists for regular video uploads. Only Reels support native scheduling. Regular video scheduling must be handled at the queue level. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **Facebook regular video scheduling via Graph API**: No `scheduled_publish_time` parameter exists for regular video uploads. Only Reels support native scheduling. Regular video scheduling must be handled at the queue level.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Facebook regular video scheduling via Graph API**: No `scheduled_publish_time` parameter exists for regular video uploads. Only Reels support native scheduling. Regular video scheduling must be handled at the queue level.

### **Instagram standalone feed video upload**: Feed videos can only exist as carousel items (`is_carousel_item=true`). There is no standalone feed video upload -- use Reels for single video posts. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **Instagram standalone feed video upload**: Feed videos can only exist as carousel items (`is_carousel_item=true`). There is no standalone feed video upload -- use Reels for single video posts.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Instagram standalone feed video upload**: Feed videos can only exist as carousel items (`is_carousel_item=true`). There is no standalone feed video upload -- use Reels for single video posts.

### Looking for Instagram-specific error codes separate from the Meta Graph API system -- Instagram uses the exact same error code system as Facebook (confirmed in Finding 4). No separate error catalog exists. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: Looking for Instagram-specific error codes separate from the Meta Graph API system -- Instagram uses the exact same error code system as Facebook (confirmed in Finding 4). No separate error catalog exists.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Looking for Instagram-specific error codes separate from the Meta Graph API system -- Instagram uses the exact same error code system as Facebook (confirmed in Finding 4). No separate error catalog exists.

### Looking for standardized `X-RateLimit-*` headers across platforms -- none of the 4 platforms document these standard headers. Rate limit detection is platform-specific via error codes. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: Looking for standardized `X-RateLimit-*` headers across platforms -- none of the 4 platforms document these standard headers. Rate limit detection is platform-specific via error codes.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Looking for standardized `X-RateLimit-*` headers across platforms -- none of the 4 platforms document these standard headers. Rate limit detection is platform-specific via error codes.

### Looking for YouTube resume URI persistence documentation in the official upload guide -- Google's sample code focuses on the client library abstraction and does not expose the raw resume URI lifecycle. -- BLOCKED (iteration 4, 1 attempts)
- What was tried: Looking for YouTube resume URI persistence documentation in the official upload guide -- Google's sample code focuses on the client library abstraction and does not expose the raw resume URI lifecycle.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Looking for YouTube resume URI persistence documentation in the official upload guide -- Google's sample code focuses on the client library abstraction and does not expose the raw resume URI lifecycle.

### **n8n built-in retry for upload error handling**: Confirmed again -- the Retry On Fail + Continue Error Output bug (iteration 5) means all retry logic must be queue-level (database status + scheduled_at manipulation), not node-level. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **n8n built-in retry for upload error handling**: Confirmed again -- the Retry On Fail + Continue Error Output bug (iteration 5) means all retry logic must be queue-level (database status + scheduled_at manipulation), not node-level.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **n8n built-in retry for upload error handling**: Confirmed again -- the Retry On Fail + Continue Error Output bug (iteration 5) means all retry logic must be queue-level (database status + scheduled_at manipulation), not node-level.

### **n8n built-in TikTok node**: Does not exist. The community node (`@igabm/n8n-nodes-tiktok`) is abandoned and non-functional. HTTP Request with OAuth2 is the only viable path. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **n8n built-in TikTok node**: Does not exist. The community node (`@igabm/n8n-nodes-tiktok`) is abandoned and non-functional. HTTP Request with OAuth2 is the only viable path.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **n8n built-in TikTok node**: Does not exist. The community node (`@igabm/n8n-nodes-tiktok`) is abandoned and non-functional. HTTP Request with OAuth2 is the only viable path.

### **n8n Retry On Fail with Continue Error Output**: These settings conflict -- retries are silently ignored when any Continue option is enabled. Must use either retries OR error branching, not both. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **n8n Retry On Fail with Continue Error Output**: These settings conflict -- retries are silently ignored when any Continue option is enabled. Must use either retries OR error branching, not both.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **n8n Retry On Fail with Continue Error Output**: These settings conflict -- retries are silently ignored when any Continue option is enabled. Must use either retries OR error branching, not both.

### **n8n webhook trigger for queue processing**: Webhooks trigger immediately on external calls, bypassing priority ordering and rate limit checks. Cron-poll is the correct pattern for a queue with priority and scheduling semantics. -- BLOCKED (iteration 6, 1 attempts)
- What was tried: **n8n webhook trigger for queue processing**: Webhooks trigger immediately on external calls, bypassing priority ordering and rate limit checks. Cron-poll is the correct pattern for a queue with priority and scheduling semantics.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **n8n webhook trigger for queue processing**: Webhooks trigger immediately on external calls, bypassing priority ordering and rate limit checks. Cron-poll is the correct pattern for a queue with priority and scheduling semantics.

### None. All four research actions (4 WebFetch calls to official Meta docs) returned substantive data. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: None. All four research actions (4 WebFetch calls to official Meta docs) returned substantive data.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None. All four research actions (4 WebFetch calls to official Meta docs) returned substantive data.

### None for this iteration (first survey pass) -- BLOCKED (iteration 1, 1 attempts)
- What was tried: None for this iteration (first survey pass)
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None for this iteration (first survey pass)

### None identified this iteration. All design decisions are constructive (no external sources returned "this approach doesn't work"). -- BLOCKED (iteration 6, 1 attempts)
- What was tried: None identified this iteration. All design decisions are constructive (no external sources returned "this approach doesn't work").
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None identified this iteration. All design decisions are constructive (no external sources returned "this approach doesn't work").

### None identified yet -- BLOCKED (iteration 1, 1 attempts)
- What was tried: None identified yet
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: None identified yet

### **Pre-upload duplicate detection for TikTok**: No API endpoint or tool exists to check if content will be flagged as duplicate before uploading. Detection is entirely post-upload at the moderation layer. This is a fundamental limitation for any upload automation system. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **Pre-upload duplicate detection for TikTok**: No API endpoint or tool exists to check if content will be flagged as duplicate before uploading. Detection is entirely post-upload at the moderation layer. This is a fundamental limitation for any upload automation system.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **Pre-upload duplicate detection for TikTok**: No API endpoint or tool exists to check if content will be flagged as duplicate before uploading. Detection is entirely post-upload at the moderation layer. This is a fundamental limitation for any upload automation system.

### Searching for unified rate limit header standards across social platforms -- each uses a proprietary signaling mechanism. A cross-platform upload system must implement per-platform rate limit detection logic. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: Searching for unified rate limit header standards across social platforms -- each uses a proprietary signaling mechanism. A cross-platform upload system must implement per-platform rate limit detection logic.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: Searching for unified rate limit header standards across social platforms -- each uses a proprietary signaling mechanism. A cross-platform upload system must implement per-platform rate limit detection logic.

### The access token guide does not document Instagram-specific token considerations separately -- they share the same Meta token infrastructure. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: The access token guide does not document Instagram-specific token considerations separately -- they share the same Meta token infrastructure.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: The access token guide does not document Instagram-specific token considerations separately -- they share the same Meta token infrastructure.

### The generic Facebook Video API publishing guide (`/docs/video-api/guides/publishing`) describes the upload-session protocol but omits video-specific rate limits, codec requirements, and resolution specs. The Reels-specific page is far more complete for our use case. -- BLOCKED (iteration 2, 1 attempts)
- What was tried: The generic Facebook Video API publishing guide (`/docs/video-api/guides/publishing`) describes the upload-session protocol but omits video-specific rate limits, codec requirements, and resolution specs. The Reels-specific page is far more complete for our use case.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: The generic Facebook Video API publishing guide (`/docs/video-api/guides/publishing`) describes the upload-session protocol but omits video-specific rate limits, codec requirements, and resolution specs. The Reels-specific page is far more complete for our use case.

### **TikTok Creator vs Business account API differences**: The Content Posting API does not differentiate between account types. The distinction is at the app level (audited vs unaudited), not the account level. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **TikTok Creator vs Business account API differences**: The Content Posting API does not differentiate between account types. The distinction is at the app level (audited vs unaudited), not the account level.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **TikTok Creator vs Business account API differences**: The Content Posting API does not differentiate between account types. The distinction is at the app level (audited vs unaudited), not the account level.

### **TikTok duplicate detection via API error codes**: The API does not return a specific "duplicate content detected" error. Duplicate detection operates at the content moderation layer post-upload, separate from the API response. There is no pre-upload duplicate check endpoint. -- BLOCKED (iteration 5, 1 attempts)
- What was tried: **TikTok duplicate detection via API error codes**: The API does not return a specific "duplicate content detected" error. Duplicate detection operates at the content moderation layer post-upload, separate from the API response. There is no pre-upload duplicate check endpoint.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **TikTok duplicate detection via API error codes**: The API does not return a specific "duplicate content detected" error. Duplicate detection operates at the content moderation layer post-upload, separate from the API response. There is no pre-upload duplicate check endpoint.

### TikTok's Direct Post API reference page (`content-posting-api-reference-direct-post`) for video specs -- it focuses on API workflow, not technical specs. The Media Transfer Guide is the correct source for TikTok video specifications. -- BLOCKED (iteration 3, 1 attempts)
- What was tried: TikTok's Direct Post API reference page (`content-posting-api-reference-direct-post`) for video specs -- it focuses on API workflow, not technical specs. The Media Transfer Guide is the correct source for TikTok video specifications.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: TikTok's Direct Post API reference page (`content-posting-api-reference-direct-post`) for video specs -- it focuses on API workflow, not technical specs. The Media Transfer Guide is the correct source for TikTok video specifications.

### **YouTube publishAt maximum scheduling window**: No maximum documented. Attempted to find limits in both official docs and Java client library reference -- none exist. This is either unlimited or undocumented. -- BLOCKED (iteration 7, 1 attempts)
- What was tried: **YouTube publishAt maximum scheduling window**: No maximum documented. Attempted to find limits in both official docs and Java client library reference -- none exist. This is either unlimited or undocumented.
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **YouTube publishAt maximum scheduling window**: No maximum documented. Attempted to find limits in both official docs and Java client library reference -- none exist. This is either unlimited or undocumented.

### **YouTube resume URI internals**: The official Google documentation deliberately abstracts resume URI management into the client library. For n8n HTTP Request nodes, we would need to reverse-engineer the Google API client or use the raw Resumable Upload Protocol (not documented in the YouTube-specific docs, but available in the generic Google API upload docs at a different URL). This is a gap that should be investigated in a future iteration focused on n8n integration (Q10). -- BLOCKED (iteration 4, 1 attempts)
- What was tried: **YouTube resume URI internals**: The official Google documentation deliberately abstracts resume URI management into the client library. For n8n HTTP Request nodes, we would need to reverse-engineer the Google API client or use the raw Resumable Upload Protocol (not documented in the YouTube-specific docs, but available in the generic Google API upload docs at a different URL). This is a gap that should be investigated in a future iteration focused on n8n integration (Q10).
- Why blocked: Repeated iteration evidence ruled this direction out.
- Do NOT retry: **YouTube resume URI internals**: The official Google documentation deliberately abstracts resume URI management into the client library. For n8n HTTP Request nodes, we would need to reverse-engineer the Google API client or use the raw Resumable Upload Protocol (not documented in the YouTube-specific docs, but available in the generic Google API upload docs at a different URL). This is a gap that should be investigated in a future iteration focused on n8n integration (Q10).

<!-- /ANCHOR:exhausted-approaches -->
<!-- ANCHOR:ruled-out-directions -->
## 10. RULED OUT DIRECTIONS
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

<!-- /ANCHOR:ruled-out-directions -->
<!-- ANCHOR:next-focus -->
## 11. NEXT FOCUS
With Q1-Q12 now all formally addressed, the next iteration should be a **convergence/synthesis iteration** to: (1) verify all 12 questions have complete answers, (2) close out open gaps in research.md Section 10, and (3) produce a final consolidated view suitable for implementation planning.

<!-- /ANCHOR:next-focus -->
<!-- MACHINE-OWNED: END -->
<!-- ANCHOR:known-context -->
## 12. KNOWN CONTEXT

### From gen1 research (specs/001-base-app-research)
**Layer 5: Distribution** (high-level coverage):
- YouTube: Data API v3 upload (built-in n8n node, native scheduling via publishAt)
- TikTok: HTTP Request -> TikTokAutoUploader (Phantomwright stealth, scheduling up to 10 days)
- Instagram: HTTP Request -> Meta Graph API (2-step upload: create + publish, 100 posts/24h)
- Facebook: HTTP Request -> Video API (3-step upload: init + upload + finish, 30 Reels/24h)
- Staggered posting: 15-30min intervals via n8n Wait node to avoid behavioral fingerprinting
- DB tables: platform_publishes, upload_queue, platform_accounts

**Known gaps (reason for this deep dive):**
- No auth flow details (OAuth endpoints, scopes, token refresh)
- No exact rate limit numbers beyond basic daily caps
- No video format specifications (codec, resolution, file size)
- No error code catalogs per platform
- No retry/backoff strategy details
- TikTokAutoUploader vs official TikTok API not compared

---

<!-- /ANCHOR:known-context -->
<!-- ANCHOR:research-boundaries -->
## 13. RESEARCH BOUNDARIES
- Max iterations: 20
- Convergence threshold: 0.05
- Per-iteration budget: 12 tool calls, 10 minutes
- Progressive synthesis: true
- research/research.md ownership: workflow-owned canonical synthesis output
- Machine-owned sections: reducer controls Sections 3, 6, 7-11
- Canonical pause sentinel: research/.deep-research-pause
- Current generation: 1
- Started: 2026-04-17T15:30:00Z
<!-- /ANCHOR:research-boundaries -->
