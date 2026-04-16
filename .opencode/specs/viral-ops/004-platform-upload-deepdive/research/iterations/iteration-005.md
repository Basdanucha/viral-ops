# Iteration 5: Platform-Specific Quirks (Q9) & n8n Integration Patterns (Q10)

## Focus
Investigating the operational "gotchas" that cause production failures: TikTok's multi-layer duplicate content detection, Instagram container expiry behavior, YouTube post-upload processing states, and Facebook encoding quirks. Simultaneously researching n8n integration patterns for OAuth2 credentials, HTTP Request upload workflows, and error handling configuration.

## Findings

### Finding 1: TikTok Multi-Layer Duplicate Detection System
TikTok employs a sophisticated 4+ layer duplicate detection system that operates at scale:

**Layer 1 -- Visual Fingerprinting**: Deep learning + perceptual hashing analyzes pixel-level and structural matches. Scene recognition technology identifies reposts by analyzing composition elements (camera angles, object placement, background settings, visual flow patterns). Can detect duplicates even through filters, cropping, speed changes, and mirroring.

**Layer 2 -- Audio Fingerprinting**: Creates unique identifiers for music, sound effects, and visual elements. Detects matches even when pitch, timing, or audio effects have been modified. Can identify audio matches even when video content differs entirely -- changing visuals while keeping the same audio does NOT bypass detection. TikTok's SoundOn partners with ACRCloud specifically for intercepting unauthorized/manipulated audio tracks.

**Layer 3 -- C2PA Metadata Tracking**: Traces content origins, editing history, and cross-platform reposts by analyzing file creation dates, device information, and editing software signatures to identify potential duplicates and their source relationships. This is a newer layer added as part of content provenance efforts.

**Layer 4 -- Behavioral Pattern Analysis**: Monitors posting patterns (rapid sequential uploads of similar content from one account), cross-account duplication signals, and engagement pattern anomalies that suggest automated or manipulated distribution.

**Accuracy**: Reported 90%+ accuracy even when superficial edits are applied.

**Penalty**: Shadow suppression (reduced distribution) rather than immediate removal for most cases. Exact thresholds not publicly documented.

**API implications**: The Content Posting API returns `spam_risk_too_many_posts` when daily post cap is hit, and `spam_risk_user_banned_from_posting` for banned accounts. No specific "duplicate detected" error code exists in the API -- duplicate detection operates at the content moderation layer post-upload, not as an API gate.

[SOURCE: https://napolify.com/blogs/news/duplicate-content-detection (search summary)]
[SOURCE: https://www.musicbusinessworldwide.com/tiktoks-distro-service-soundon-cracks-down-on-manipulated-audio-via-acrcloud-partnership/ (search summary)]
[SOURCE: https://developers.tiktok.com/doc/content-posting-api-reference-direct-post]

### Finding 2: Instagram Container Expiry -- 24-Hour Window
Instagram media containers expire after exactly **24 hours** from creation. Key details:

- The `status_code` field on a container returns `FINISHED` when video upload is complete and ready for publishing
- Containers must be published via `POST /{ig_user_id}/media_publish` before the 24h window closes
- **What happens to expired containers**: Not explicitly documented by Meta, but the container ID becomes invalid and publishing attempts will fail
- **Status polling**: Check `status_code` field on the container object. Only `FINISHED` is explicitly documented as a success value. Other states (IN_PROGRESS, ERROR, EXPIRED) are referenced in community docs but not in the official API reference
- **Reels-specific**: Reels containers cannot appear in carousels, and audio tagging applies only to original audio
- **Resumable uploads**: Return `id` and `uri` for subsequent steps, but failure recovery mechanisms are not documented beyond the initial upload

**Practical implication for viral-ops**: Upload queue must track container creation timestamps and prioritize publishing containers approaching the 24h boundary. A container that expires wastes the rate limit budget (400 containers/24h).

[SOURCE: https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media]

### Finding 3: YouTube Post-Upload Processing States
YouTube videos go through a well-defined processing pipeline after upload:

**Upload Status Values** (`status.uploadStatus`):
| Status | Meaning |
|--------|---------|
| `uploaded` | File transfer completed successfully |
| `processing` | YouTube is currently processing (transcoding, thumbnail generation) |
| `processed` | Processing finished successfully -- video ready for viewing |
| `failed` | Upload or processing encountered an error |
| `rejected` | YouTube rejected the video (policy violation) |
| `deleted` | Video was removed |

**Processing Progress Tracking** (`processingDetails`):
- `processingStatus`: `processing` | `succeeded` | `failed` | `terminated`
- `processingProgress.partsTotal`: Estimated total processing segments
- `processingProgress.partsProcessed`: Segments already completed
- `processingProgress.timeLeftMs`: Estimated milliseconds remaining
- `fileDetailsAvailability`: `available` when file details can be queried

**Upload Failure Reasons** (`status.failureReason`):
| Reason | Cause |
|--------|-------|
| `codec` | Unsupported video/audio codec |
| `conversion` | Transcoding error |
| `emptyFile` | Zero-byte file |
| `invalidFile` | Corrupted or unrecognized format |
| `tooSmall` | File below minimum size |
| `uploadAborted` | User cancelled or connection lost |

**Processing Failure Reasons** (`processingDetails.processingFailureReason`):
| Reason | Cause |
|--------|-------|
| `transcodeFailed` | Content transcoding error |
| `streamingFailed` | Cannot deliver to servers |
| `uploadFailed` | File delivery failure |
| `other` | Unspecified processing component failure |

**Rejection Reasons** (`status.rejectionReason`):
- `copyright`, `trademark`, `inappropriate`, `length`, `duplicate`, `termsOfUse`, `claim`, `legal`, `uploaderAccountClosed`, `uploaderAccountSuspended`

**Polling strategy**: Query `videos.list` with `part=processingDetails` while `processingStatus` is `processing`. Each poll costs 1 quota unit. Use `timeLeftMs` to set polling intervals rather than fixed polling.

**publishAt scheduling details**:
- Only works when `privacyStatus` = `private`
- Set ISO 8601 datetime for future publication
- Past dates trigger immediate publication
- Cannot be used if video was previously published
- Must set `privacyStatus` to `private` in update calls

[SOURCE: https://developers.google.com/youtube/v3/docs/videos]

### Finding 4: n8n OAuth2 Credential Architecture
n8n supports OAuth2 for HTTP Request nodes with the following architecture:

**Credential Types**:
- **Generic OAuth2 API**: Configurable with any OAuth2 provider (Authorization Code, Client Credentials, PKCE grant types)
- **Predefined credentials**: Built-in for Google (YouTube), Facebook, Instagram with pre-configured endpoints
- **HTTP Request credentials**: Supports OAuth1, OAuth2, Bearer, Header, Digest, Basic, Custom auth, SSL certificates

**Configuration fields** (Generic OAuth2 API):
- Grant Type (Authorization Code / Client Credentials / PKCE)
- Client ID, Client Secret
- Authorization URL, Access Token URL
- Scopes (space-separated)
- Redirect URL (n8n generates this)

**Token auto-refresh**: n8n automatically refreshes expired OAuth2 tokens when using the built-in credential system. For Google OAuth (YouTube), this is handled natively. For TikTok and Meta, the Generic OAuth2 API credential must be configured with the token endpoint and n8n handles refresh automatically when using Authorization Code grant.

**Multi-account**: Each credential is a separate entity. Multiple OAuth2 credentials can be created for the same service (e.g., 5 TikTok accounts = 5 separate OAuth2 credentials). Selection is per-node.

**Known issue with TikTok**: Community reports indicate the HTTP Request node sometimes does not send the Authorization header correctly when using connected OAuth2 credentials for TikTok API. Workaround: manually set `Authorization: Bearer {{$credentials.accessToken}}` in headers.

[SOURCE: https://docs.n8n.io/integrations/builtin/credentials/httprequest/]
[SOURCE: https://community.n8n.io/t/http-request-node-not-sending-authorization-header-despite-selecting-connected-oauth2-credential-tiktok-api/99963 (search summary)]

### Finding 5: n8n Error Handling for Upload Workflows
n8n provides a layered error handling system:

**Node-level settings**:
- **On Error**: `Stop Workflow` (default) | `Continue Regular Output` | `Continue Error Output`
- **Retry On Fail**: Enable with configurable retries count, wait between tries (ms)
- **CRITICAL BUG**: If Retry On Fail is ON and On Error is set to any Continue option, the retry settings (Max Tries, Wait Between Tries) are **silently ignored**. Retries only work when On Error = `Stop Workflow`.

**Error output branches**:
- When On Error = `Continue Error Output`, failed items route to the Error branch while successful items continue on the regular (Success) branch
- Error data accessible via `$json["error"]["message"]`, `$json["error"]["code"]`, `$json["requestUrl"]`

**Error Trigger workflow**:
- Error workflows must start with an Error Trigger node
- `execution.retryOf` field indicates if current execution is a retry
- Best practice: Disable node-level Retry On Fail and handle retries exclusively in the error workflow to prevent duplicate events

**Manual exponential backoff pattern** (for upload retries):
```
Wait Node delay = Math.pow(2, retryCount) * 1000  // 2s, 4s, 8s, 16s...
Max retry ceiling: 5 attempts recommended
```

**Practical upload workflow architecture**:
1. HTTP Request node (upload) with On Error = `Continue Error Output`
2. IF node checks error type (retryable vs fatal based on our Tier 1/2/3 strategy)
3. Retryable errors -> Wait node (exponential backoff) -> Loop back to HTTP Request
4. Fatal errors -> Error handler (log to DB, alert via webhook/email)

[SOURCE: https://flowgenius.in/n8n-partial-failure-handling/]
[SOURCE: https://github.com/n8n-io/n8n/issues/10763 (search summary)]
[SOURCE: https://docs.n8n.io/flow-logic/error-handling/ (partial)]

### Finding 6: n8n Community Nodes for Social Media Upload
**Upload-Post node** (`n8n-nodes-upload-post`):
- Official n8n community node, included by default in updated n8n versions
- Supports TikTok, Instagram, YouTube, LinkedIn, X, Facebook, Pinterest, Threads, Reddit, Bluesky
- Acts as middleware -- sends video to Upload-Post.com's API which handles the platform-specific upload complexity
- Simplifies workflow but adds a third-party dependency and potential single point of failure

**TikTok-specific nodes** (`@igabm/n8n-nodes-tiktok`):
- Community-built, marked "Work In Progress - Not Working Yet" on GitHub
- Unreliable for production use
- Community nodes break when APIs change

**YouTube**: Built-in n8n YouTube node handles upload natively via Google OAuth

**Recommended approach for viral-ops**: Use HTTP Request nodes with Generic OAuth2 for TikTok, Instagram, and Facebook (direct API control, no third-party dependency). Use built-in YouTube node for YouTube uploads.

[SOURCE: https://github.com/Upload-Post/n8n-nodes-upload-post (search summary)]
[SOURCE: https://github.com/igabm/n8n-nodes-tiktok (search summary)]
[SOURCE: https://www.eesel.ai/blog/tiktok-integrations-with-n8n (search summary)]

### Finding 7: Facebook Encoding & Checksum Behavior (Synthesis)
From prior iteration data and the Reels publishing documentation:

**Re-encoding**: Facebook re-encodes all uploaded video content through their transcoding pipeline. The `processing_phase` status in the 3-phase Reels upload reflects this. Original file specs (codec, bitrate) serve as input quality -- the output is always Facebook's optimized encoding.

**Checksum validation in finish phase**: The `POST /video_reels` with `upload_phase=finish` validates the uploaded binary against the `file_size` declared during initialization. If the transfer was incomplete or corrupted, the finish phase will reject it. This is offset-based validation, not cryptographic checksum.

**Processing states** (Facebook Reels):
- `uploading_phase`: File transfer in progress
- `processing_phase`: Server-side transcoding and validation
- `publishing_phase`: Content distribution to feed

**Status polling**: `GET /{video_id}?fields=status` returns the current phase. Poll during `processing_phase` before attempting to check final publish status.

[INFERENCE: based on iteration 2 Facebook Reels findings + YouTube processing model comparison]
[SOURCE: https://developers.facebook.com/docs/video-api/guides/reels-publishing (from iteration 2)]

## Ruled Out
- **TikTok duplicate detection via API error codes**: The API does not return a specific "duplicate content detected" error. Duplicate detection operates at the content moderation layer post-upload, separate from the API response. There is no pre-upload duplicate check endpoint.
- **n8n built-in TikTok node**: Does not exist. The community node (`@igabm/n8n-nodes-tiktok`) is abandoned and non-functional. HTTP Request with OAuth2 is the only viable path.
- **n8n Retry On Fail with Continue Error Output**: These settings conflict -- retries are silently ignored when any Continue option is enabled. Must use either retries OR error branching, not both.

## Dead Ends
- **Pre-upload duplicate detection for TikTok**: No API endpoint or tool exists to check if content will be flagged as duplicate before uploading. Detection is entirely post-upload at the moderation layer. This is a fundamental limitation for any upload automation system.

## Sources Consulted
- https://developers.tiktok.com/doc/content-posting-api-reference-direct-post
- https://developers.google.com/youtube/v3/docs/videos
- https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/media
- https://docs.n8n.io/integrations/builtin/credentials/httprequest/
- https://docs.n8n.io/flow-logic/error-handling/
- https://flowgenius.in/n8n-partial-failure-handling/
- https://community.n8n.io/t/http-request-node-not-sending-authorization-header-despite-selecting-connected-oauth2-credential-tiktok-api/99963
- https://github.com/n8n-io/n8n/issues/10763
- https://github.com/Upload-Post/n8n-nodes-upload-post
- https://github.com/igabm/n8n-nodes-tiktok
- https://napolify.com/blogs/news/duplicate-content-detection (via search summary)
- https://www.musicbusinessworldwide.com/tiktoks-distro-service-soundon-cracks-down-on-manipulated-audio-via-acrcloud-partnership/ (via search summary)

## Assessment
- New information ratio: 0.79
- Questions addressed: Q9, Q10
- Questions answered: Q9 (substantially), Q10 (substantially)

## Reflection
- What worked and why: Combining official API documentation fetches (YouTube videos resource, Instagram media reference) with web search for community-sourced knowledge (TikTok duplicate detection, n8n error handling patterns) yielded complementary data. YouTube's official docs were exceptionally well-structured for processing states. The web search for TikTok duplicate detection surfaced rich community analysis that the official API docs completely lack.
- What did not work and why: Two source pages returned HTTP 403 (Napolify article, gwaa.net article) -- these sites likely block automated fetching. The n8n documentation pages rendered with truncated content, missing the detailed configuration fields. n8n's docs appear to use client-side rendering that doesn't fully expose to WebFetch.
- What I would do differently: For n8n-specific details, target the n8n GitHub source code or community forum threads rather than the official docs site which renders poorly. For TikTok content moderation internals, target research papers or TikTok's transparency reports rather than blog articles.

## Recommended Next Focus
1. **Q11 (Upload queue architecture)**: How upload_queue table integrates with n8n workflows, priority scheduling, staggered posting implementation with Wait nodes, failure retry with backoff, status tracking through the upload lifecycle. This is the architectural glue between our database schema and n8n execution.
2. **Q12 (Multi-account management)**: How platform_accounts table connects to OAuth tokens, per-channel credential storage, token rotation across multiple accounts, n8n credential selection per account.
