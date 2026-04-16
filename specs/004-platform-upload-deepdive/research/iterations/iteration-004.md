# Iteration 4: Error Handling Patterns (Q7) & Token Management (Q8)

## Focus
Investigate per-platform error code catalogs, retry/backoff strategies, upload recovery mechanisms, and token lifecycle management. This directly addresses Q7 (error handling patterns) and Q8 (token management), the two highest-priority remaining questions after video specs (Q5) and rate limits (Q6) were answered in iteration 3.

## Findings

### Finding 1: TikTok Content Posting API Error Catalog
[SOURCE: https://developers.tiktok.com/doc/content-posting-api-reference-direct-post]

TikTok uses a structured error response with `error.code`, `error.message`, and `error.log_id`.

**Error codes by HTTP status:**

| HTTP | Error Code | Description | Retryable? |
|------|-----------|-------------|------------|
| 400 | `invalid_param` | Validation failure (check message for details) | No -- fix request |
| 401 | `access_token_invalid` | Token expired or invalid | No -- refresh token |
| 401 | `scope_not_authorized` | Missing `video.publish` scope | No -- re-authorize |
| 403 | `spam_risk_too_many_posts` | Daily post cap reached for user | Yes -- wait for daily reset |
| 403 | `spam_risk_user_banned_from_posting` | User banned from posting | No -- account issue |
| 403 | `reached_active_user_cap` | Daily quota for active publishing users from client reached | Yes -- wait for daily reset |
| 403 | `unaudited_client_can_only_post_to_private_accounts` | Unaudited app restriction | No -- complete audit |
| 403 | `url_ownership_unverified` | PULL_FROM_URL domain not verified | No -- verify domain first |
| 403 | `privacy_level_option_mismatch` | Privacy level not allowed by creator | No -- fix request |
| 429 | `rate_limit_exceeded` | API rate limit hit | Yes -- backoff |
| 5xx | (various) | Server infrastructure failures | Yes -- backoff |

**Critical discovery:** The `/v2/post/publish/video/init/` endpoint is limited to **6 requests per minute per access token**. This is far more restrictive than the general 600 req/min API rate limit documented in iteration 1. Upload URLs expire after **1 hour**.

### Finding 2: YouTube Data API v3 Error Catalog
[SOURCE: https://developers.google.com/youtube/v3/docs/errors]

YouTube uses a domain/reason/message structure. Upload-specific errors (`videos.insert`):

| HTTP | Error Reason | Description | Retryable? |
|------|-------------|-------------|------------|
| 400 | `invalidVideoMetadata` | Missing title or categoryId | No -- fix metadata |
| 400 | `invalidTitle` | Empty or invalid title | No -- fix request |
| 400 | `invalidDescription` | Invalid description format | No -- fix request |
| 400 | `invalidTags` | Invalid keywords | No -- fix request |
| 400 | `invalidFilename` | Bad Slug header | No -- fix request |
| 400 | `invalidPublishAt` | Bad scheduled time | No -- fix request |
| 400 | `mediaBodyRequired` | No video content in request | No -- fix request |
| 400 | `uploadLimitExceeded` | User exceeded upload count | No -- daily limit |
| 400 | `processingFailure` | Server failed to process | Yes -- retry with backoff |
| 401 | `authorizationRequired` | Missing or invalid auth | No -- re-authenticate |
| 401 | `youtubeSignupRequired` | No YouTube channel; Service Accounts unsupported | No -- user must create channel |
| 403 | `forbidden` | Insufficient authorization | No -- check scopes |
| 403 | `insufficientPermissions` | OAuth scopes insufficient | No -- re-authorize with correct scope |
| 403 | `forbiddenPrivacySetting` | Invalid privacy setting | No -- fix request |
| 403 | `forbiddenLicenseSetting` | Invalid license setting | No -- fix request |
| 403 | `quotaExceeded` | Daily quota exhausted | Yes -- wait for quota reset (midnight PT) |
| 403 | `authenticatedUserAccountClosed` | Account closed | No -- permanent |
| 403 | `authenticatedUserAccountSuspended` | Account suspended | No -- permanent |
| 404 | `videoNotFound` | Video ID doesn't exist | No -- fix ID |
| 429 | `uploadRateLimitExceeded` | Too many thumbnails recently | Yes -- backoff |

### Finding 3: YouTube Resumable Upload Recovery
[SOURCE: https://developers.google.com/youtube/v3/guides/uploading_a_video]

YouTube's official sample code defines explicit retry infrastructure:

```python
RETRIABLE_STATUS_CODES = [500, 502, 503, 504]
MAX_RETRIES = 10
# Exponential backoff with jitter:
max_sleep = 2 ** retry  # 1, 2, 4, 8, 16, 32, 64, 128, 256, 512 seconds
sleep_seconds = random.random() * max_sleep
```

**Retryable exceptions** (network-level): `HttpLib2Error`, `IOError`, `NotConnected`, `IncompleteRead`, `ImproperConnectionState`, `CannotSendRequest`, `CannotSendHeader`, `ResponseNotReady`, `BadStatusLine`.

**Gap identified:** The official docs do NOT document:
- Resume URI persistence duration
- How to check status of an interrupted upload
- Post-upload processing states (processing/processed/failed/rejected)
- Idempotency guarantees for re-uploading to same URI

These are critical gaps for a production upload system. The Google API Client Libraries handle resume URIs internally, but viral-ops using n8n HTTP Request nodes would need to implement this manually.

### Finding 4: Meta (Facebook + Instagram) Graph API Error System
[SOURCE: https://developers.facebook.com/docs/graph-api/guides/error-handling]

Meta uses a unified error system for both Facebook and Instagram with `error.code`, `error.type`, `error.error_subcode`, and `error.fbtrace_id`.

**Core error codes:**

| Code | Name | Category | Retryable? | Action |
|------|------|----------|------------|--------|
| 1 | API Unknown | General | Yes | Retry after delay |
| 2 | API Service | Infrastructure | Yes | Retry after delay |
| 3 | API Method | Capability | No | Check permissions |
| 4 | API Too Many Calls | Rate Limit | Yes | Backoff + reduce volume |
| 10 | API Permission Denied | Permission | No | Request permissions |
| 17 | API User Too Many Calls | Rate Limit | Yes | Backoff + reduce volume |
| 102 | API Session | Auth | No | New access token |
| 190 | Access Token Expired | Auth | No | Refresh/exchange token |
| 200-299 | API Permission (range) | Permission | No | Handle missing permissions |
| 341 | Application Limit Reached | Rate/System | Yes | Backoff |
| 368 | Temporarily Blocked | Policy | Yes | Backoff (policy throttle) |
| 506 | Duplicate Post | Content | No | Modify content |

**OAuthException subcodes (for code 190):**

| Subcode | Meaning | Resolution |
|---------|---------|------------|
| 458 | App Not Installed | Re-authenticate user |
| 459 | User Checkpointed | User must log in manually |
| 460 | Password Changed | Re-authenticate |
| 463 | Token Expired | Exchange for new token |
| 464 | Unconfirmed User | User must verify account |
| 467 | Invalid Access Token | Get new token |
| 492 | Invalid Session | User lacks page role |

**Key insight:** Error code 506 (Duplicate Post) is non-retryable and directly relevant to TikTok's duplicate detection concern (Q9). This means Meta also detects and blocks duplicate content at the API level.

### Finding 5: Unified Retry Strategy Design
[INFERENCE: based on Findings 1-4 and YouTube's official backoff pattern]

Based on the error catalogs from all 4 platforms, here is a unified retry strategy for viral-ops:

**Retry classification (3 tiers):**

| Tier | Error Type | Strategy | Max Retries | Examples |
|------|-----------|----------|-------------|---------|
| **Tier 1: Immediate retry** | Network/server errors | Exponential backoff + jitter | 10 | 5xx, IOError, connection drops |
| **Tier 2: Delayed retry** | Rate limits, quotas | Fixed delay + check reset time | 3 | 429, error 4/17, `spam_risk_too_many_posts`, `quotaExceeded` |
| **Tier 3: No retry** | Validation, auth, policy | Fail fast, log, alert | 0 | 400 validation, 401 expired token, 403 permission, 506 duplicate |

**Exponential backoff formula (following YouTube's official pattern):**
```
delay = min(random() * (2^attempt), MAX_DELAY)
// attempt 1: 0-2s, attempt 2: 0-4s, attempt 3: 0-8s, ...
// MAX_DELAY: 512s (YouTube) or 300s (practical cap for n8n)
```

**Per-platform max retries:**
- TikTok: 5 retries (conservative due to 6 req/min init limit)
- YouTube: 10 retries (Google's official recommendation)
- Instagram: 5 retries (container creation is 2-step, each step can fail)
- Facebook: 5 retries (3-phase upload, each phase retried independently)

### Finding 6: Token Lifecycle Management Per Platform
[INFERENCE: based on iterations 1-2 auth findings + Finding 4 error codes]

**Token refresh rotation policies:**

| Platform | Access Token TTL | Refresh Token TTL | Rotation Policy | Auto-refresh |
|----------|-----------------|-------------------|-----------------|--------------|
| TikTok | 24 hours | 365 days | Refresh token does NOT rotate on use (same token reusable) | Must implement |
| YouTube/Google | ~1 hour | Never expires (unless revoked) | No rotation; refresh token is permanent | Google client lib handles |
| Meta (IG+FB) | Short-lived: 1h, Long-lived: 60 days | N/A (use token exchange) | Must exchange short→long→page token | Page tokens are permanent |

**Critical token management considerations:**
1. **TikTok**: Refresh token valid 365 days but access token only 24h. Must have a cron job refreshing access tokens daily. If refresh token expires (user doesn't use app for 365 days), full re-authorization required.
2. **YouTube**: Refresh tokens are the most stable -- they never expire unless user revokes. However, testing apps (unverified) have tokens that expire after 7 days and are limited to 100 test users.
3. **Meta (IG+FB)**: The token exchange chain is: short-lived (1h) → long-lived (60d) → page token (permanent). For server-to-server, system user tokens are permanent. Page tokens obtained via `GET /{page-id}?fields=access_token` with a long-lived user token are **permanent** and never expire.

### Finding 7: Token Error Detection and Recovery Flow
[INFERENCE: based on Findings 1-4 error codes cross-referenced]

**Unified token error detection:**

| Platform | Error Signal | Token Action |
|----------|-------------|-------------|
| TikTok | HTTP 401 + `access_token_invalid` | Refresh using refresh_token → POST `/v2/oauth/token/` with `grant_type=refresh_token` |
| YouTube | HTTP 401 + `authorizationRequired` | Auto-refresh via Google OAuth client (refresh_token → new access_token) |
| Instagram | HTTP 400 + error code 190 + subcode 463 | Exchange for new long-lived token or re-authenticate |
| Facebook | HTTP 400 + error code 190 + subcode 463/467 | Exchange for new long-lived token; page tokens are permanent |

**n8n credential handling:**
- n8n's built-in OAuth2 credential type handles auto-refresh for Google (YouTube) natively
- For TikTok, Meta: n8n HTTP Request node with OAuth2 Generic credentials can auto-refresh if configured with token refresh URL
- Multi-account: Each platform account gets its own n8n credential, stored encrypted in n8n's credential store
- Token refresh failures should trigger alerts (not silent failures) since a dead token means the entire upload pipeline stops for that account

## Ruled Out
- Looking for Instagram-specific error codes separate from the Meta Graph API system -- Instagram uses the exact same error code system as Facebook (confirmed in Finding 4). No separate error catalog exists.
- Looking for YouTube resume URI persistence documentation in the official upload guide -- Google's sample code focuses on the client library abstraction and does not expose the raw resume URI lifecycle.

## Dead Ends
- **YouTube resume URI internals**: The official Google documentation deliberately abstracts resume URI management into the client library. For n8n HTTP Request nodes, we would need to reverse-engineer the Google API client or use the raw Resumable Upload Protocol (not documented in the YouTube-specific docs, but available in the generic Google API upload docs at a different URL). This is a gap that should be investigated in a future iteration focused on n8n integration (Q10).

## Sources Consulted
- https://developers.tiktok.com/doc/content-posting-api-reference-direct-post (TikTok error codes)
- https://developers.google.com/youtube/v3/docs/errors (YouTube error catalog)
- https://developers.google.com/youtube/v3/guides/uploading_a_video (YouTube retry strategy)
- https://developers.facebook.com/docs/graph-api/guides/error-handling (Meta error system)

## Assessment
- New information ratio: 0.79
- Questions addressed: Q7 (error handling patterns), Q8 (token management)
- Questions answered: Q7 (substantially answered -- error catalogs + retry strategy designed), Q8 (partially answered -- token lifecycle clear, n8n integration details deferred to Q10)

## Reflection
- **What worked and why:** Targeting the official error reference pages (not general API docs) for each platform yielded dense, structured error catalogs. The Meta error handling guide was especially valuable as a single page covering the entire error taxonomy for both Instagram and Facebook.
- **What did not work and why:** YouTube's upload guide is code-sample-oriented (Python client library) rather than protocol-oriented, so resume URI mechanics are hidden behind the library abstraction. The raw Google Resumable Upload Protocol docs would be a better source for n8n HTTP Request implementation.
- **What I would do differently:** For the YouTube gap (resume URI lifecycle), fetch the generic Google API resumable upload protocol docs (`developers.google.com/api-client-library/...`) rather than the YouTube-specific guide which wraps everything in client library calls.

## Recommended Next Focus
1. **Platform-specific quirks (Q9):** TikTok duplicate detection (4-layer system mentioned in gen1), Instagram container expiry timing, YouTube processing states after upload, Facebook encoding requirements. These are the operational gotchas that will cause production issues.
2. **n8n integration patterns (Q10):** How to implement the retry strategy in n8n workflow nodes, OAuth2 credential management for multi-account, error branch routing. The YouTube resume URI gap from this iteration should be addressed here using the generic Google Resumable Upload Protocol docs.
