# Iteration 7: Affiliate/Shopping API Deep-Dive — Cart Pin ("ปักตะกร้า") Across All 4 Platforms

## Focus
Research the Shopping/Affiliate APIs for TikTok, YouTube, Instagram, and Facebook to determine whether "ปักตะกร้า" (cart pin / product tagging) can be done programmatically via API. Evaluate OSS libraries for Shopping APIs. This follows iteration 6's discovery that all four platforms SEPARATE content upload APIs from shopping/commerce APIs.

## Findings

### Finding 1: TikTok Shop Affiliate APIs — Programmatic Cart Pin IS Possible (via Affiliate API, not Content API)
TikTok launched Affiliate APIs in GA (announced 2024, available through TikTok Shop Partner Center). The Affiliate APIs cover three functional areas:
1. **Collaboration Management**: Create/manage open and targeted affiliate campaigns, edit open collaboration settings, create target collaborations
2. **Search & Discovery**: Search for creators by GMV/keywords/demographics; find products with open collaborations by category/commission rate/keywords
3. **Performance Tracking**: Generate affiliate product promotion links; search and retrieve affiliate orders for conversion tracking

**Critical finding**: The Affiliate APIs can "Generate affiliate product promotion links" — this is the programmatic equivalent of getting a product link that can be associated with content. However, the actual "pin to video" action (ปักตะกร้า) appears to still require the TikTok Creator Center UI or TikTok Shop Seller Center for the final attachment step. The API provides the affiliate link and campaign management, but the video-product binding is done through the TikTok app/web interface.

**Authentication**: Requires TikTok Shop Partner Center account, OAuth 2.0 authorization. Sellers need approved TikTok Shop, creators need approved affiliate status.

**API Documentation**: Available at `partner.tiktokshop.com/docv2/` — note the docs site requires JavaScript rendering (SPA), making automated extraction difficult.

[SOURCE: https://developers.tiktok.com/blog/2024-tiktok-shop-affiliate-apis-launch-developer-opportunity]
[SOURCE: https://partner.tiktokshop.com/docv2/page/affiliate-seller-api-overview]

### Finding 2: Instagram Product Tagging API — FULL Programmatic Support Including Reels
This is the most complete Shopping API of all four platforms. The Instagram Graph API provides full programmatic product tagging with these endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/{ig-user-id}` | GET | Check `shopping_product_tag_eligibility` |
| `/{ig-user-id}/available_catalogs` | GET | Retrieve product catalogs |
| `/{ig-user-id}/catalog_product_search` | GET | Search for taggable products |
| `/{ig-user-id}/media` | POST | Create tagged media containers (including REELS) |
| `/{ig-user-id}/media_publish` | POST | Publish tagged containers |
| `/{ig-media-id}/product_tags` | GET | Retrieve tags on published media |
| `/{ig-media-id}/product_tags` | POST | **Add/update tags on EXISTING published media** |
| `/{ig-user-id}/product_appeal` | GET/POST | Appeal product rejections |

**Key capabilities**:
- **Reels support**: YES — use `media_type=REELS` with up to **30 product tags** per Reel
- **Post-publication tagging**: YES — `POST /{ig-media-id}/product_tags` can add up to 5 tags to already-published media
- **Rate limit**: 25 tagged media posts per 24 hours

**Prerequisites**:
- Approved Instagram Shop with product catalog in Meta Commerce Manager
- Admin role on Business Manager
- `instagram_shopping_tag_products` and `catalog_management` OAuth permissions
- Products must have `review_status` of "approved"

**For viral-ops**: This means n8n can: (1) upload Reel via Instagram Content Publishing API, (2) then immediately call `POST /{ig-media-id}/product_tags` to attach products — full automation is possible.

[SOURCE: https://developers.facebook.com/docs/instagram-platform/instagram-api-with-facebook-login/product-tagging/]

### Finding 3: YouTube Shopping — Creator-Manual Tagging, No Direct API for Product Attachment
YouTube Shopping works through the YouTube Shopping affiliate program integrated with Google Merchant Center:

**How it works**:
1. Merchants upload product data feed through Google Merchant Center
2. Merchants enable the "YouTube Shopping" destination in their data source
3. Approved creators can tag products from participating merchants in videos, Shorts, and livestreams
4. When viewers click product tags, they can purchase through the merchant's store

**Programmatic capabilities**:
- **Product catalog upload**: YES — via Google Merchant Center API (Content API for Shopping)
- **Product tagging in videos**: NO direct API — creators tag products manually through YouTube Studio
- **AI auto-tagging (2026)**: YouTube is rolling out AI-powered automatic product tagging using computer vision to identify products in videos and add dynamic tags in real time

**Prerequisites**:
- YouTube Partner Program membership (1,000+ subscribers, 4,000+ watch hours)
- Google Merchant Center account with approved product catalog
- YouTube Shopping affiliate program enrollment
- Shopify integration available for streamlined catalog sync

**For viral-ops**: YouTube Shopping product tagging cannot be automated via API in Phase 1. The YouTube Data API v3 handles video uploads but has no product tagging endpoints. This is a manual step through YouTube Studio. AI auto-tagging may change this in 2026.

[SOURCE: https://support.google.com/merchants/answer/14815513?hl=en]
[SOURCE: https://support.google.com/youtube/answer/12257682?hl=en]
[SOURCE: https://feedonomics.com/blog/youtube-shopping-product-feeds/]

### Finding 4: Facebook Shops / Reels — Shares Instagram's Meta Commerce Infrastructure
Facebook Shops and Reels product tagging share the same Meta Commerce Manager infrastructure as Instagram:

- **Product catalog**: Same Meta Commerce Manager catalog used for Instagram Shopping
- **Facebook Shops API**: Uses the Marketing API and Catalog API (`/{catalog-id}/products`, `/{catalog-id}/product_sets`)
- **Reels product tagging**: Facebook Reels support product tags pulled from Facebook Shops catalog
- **Programmatic tagging**: The Facebook Graph API supports product tags on posts, but Reels-specific product tagging API documentation is less explicit than Instagram's

**Key difference from Instagram**: While Instagram has dedicated `product_tags` endpoints for Reels, Facebook Reels product tagging is more tightly coupled with Facebook Shops checkout flow. The API surface for FB Reels product tags is less mature than Instagram's.

**For viral-ops**: Use the same Meta Commerce Manager catalog for both Instagram and Facebook. Product catalog management is shared. However, FB Reels product tagging automation is less well-documented than Instagram's and may require manual steps in Phase 1.

[SOURCE: https://almcorp.com/blog/meta-in-app-sales-tools-facebook-instagram/]
[INFERENCE: based on shared Meta Commerce Manager infrastructure between IG and FB from multiple sources]

### Finding 5: OSS Libraries Assessment — Lundehund/tiktok-shop-api Is Inadequate
**Lundehund/tiktok-shop-api (Python)**:
- Only 12 stars, 3 forks, 7 total commits — extremely immature
- Only 4 methods: `get_seller_products()`, `get_product_detail()`, `get_product_reviews()`, `search_products()`
- READ-ONLY: No affiliate APIs, no order management, no product-to-video linking
- Uses RapidAPI (third-party proxy), NOT direct TikTok Shop authentication
- **Verdict: NOT viable for viral-ops**

**ipfans/tiktok (Go SDK)**: Not directly evaluated this iteration (Go SDK, viral-ops stack is Python + Node.js). Lower priority given Go is not in the primary stack.

**Better alternatives identified**:
- **TikTok Shop Official SDK**: TikTok provides official API documentation through Partner Center. Direct HTTP integration via n8n HTTP Request nodes is more practical than wrapping in a thin OSS library.
- **EcomPHP/tiktokshop-php**: PHP-based, not directly usable but architecture patterns are transferable.

**For viral-ops**: Skip OSS wrappers. Use n8n HTTP Request nodes to call TikTok Shop Affiliate APIs directly. The APIs are REST-based and well-suited for n8n's HTTP Request node pattern.

[SOURCE: https://github.com/Lundehund/tiktok-shop-api]
[SOURCE: https://partner.tiktokshop.com/doc/page/63fd743c715d622a338c4e54]

### Finding 6: Architecture Integration — Platform Cart Pin Automation Matrix

| Platform | Cart Pin via API? | Method | Phase | n8n Integration |
|----------|-------------------|--------|-------|-----------------|
| **TikTok** | PARTIAL | Affiliate API generates links + manages campaigns; final video-product binding via UI | Phase 2 | HTTP Request → TikTok Shop Affiliate API |
| **Instagram** | YES (FULL) | Product Tagging API on Reels, including post-publication tagging | Phase 1 | HTTP Request → `POST /{ig-media-id}/product_tags` |
| **YouTube** | NO | Manual tagging in YouTube Studio; AI auto-tag coming 2026 | Phase 2+ | N/A (manual step) |
| **Facebook** | PARTIAL | Shared Meta Commerce catalog; FB Reels tagging less documented | Phase 1-2 | HTTP Request → Graph API (shared with IG) |

**Updated n8n Workflow** (extends iteration 6 architecture):
```
Video Upload Complete (any platform)
  ├── TikTok: Upload via TikTokAutoUploader → Manual cart pin in TikTok app (or Affiliate API link in description)
  ├── Instagram: Upload via Meta Graph API → POST product_tags → AUTOMATED cart pin ✓
  ├── YouTube: Upload via YouTube Data API v3 → Manual product tag in YouTube Studio
  └── Facebook: Upload via Video API → Attempt product tag via Graph API → May need manual step
```

**DB Schema Update** (extends iteration 6 `affiliate_links` table):
```sql
ALTER TABLE affiliate_links ADD COLUMN cart_pin_method VARCHAR(20) 
  CHECK (cart_pin_method IN ('api_auto', 'api_partial', 'manual', 'pending'));
-- api_auto = Instagram (full API automation)
-- api_partial = TikTok (affiliate link via API, binding via UI) / Facebook
-- manual = YouTube (all manual in YouTube Studio)
-- pending = not yet attempted
```

**Prerequisites checklist per platform**:
- TikTok: Approved TikTok Shop + Affiliate Partner Center account + OAuth app
- Instagram: Meta Business account + Commerce Manager catalog + approved shop + `instagram_shopping_tag_products` permission
- YouTube: YPP membership (1k subs) + Google Merchant Center + Shopping affiliate enrollment
- Facebook: Meta Business account + Facebook Shop + Commerce Manager catalog (shared with IG)

[INFERENCE: based on synthesis of all 4 platform findings + iteration 6 DB schema]

## Ruled Out
- **Lundehund/tiktok-shop-api** as viable library: Only 12 stars, 7 commits, read-only RapidAPI wrapper. Does not cover Affiliate APIs or any write operations.
- **YouTube Shopping via API for Phase 1**: No API exists for programmatic product tagging in YouTube videos/Shorts. Must be manual.
- **Unified cart pin approach across all platforms**: Each platform has fundamentally different levels of API support (full, partial, none). Architecture must handle all three modes.

## Dead Ends
- **OSS wrapper libraries for Shopping APIs**: The available OSS libraries (Lundehund, ipfans, EcomPHP) are all either too immature, wrong language, or read-only. Direct HTTP API calls via n8n is the correct approach for all platforms.

## Sources Consulted
- https://developers.tiktok.com/blog/2024-tiktok-shop-affiliate-apis-launch-developer-opportunity
- https://partner.tiktokshop.com/docv2/page/affiliate-seller-api-overview
- https://developers.facebook.com/docs/instagram-platform/instagram-api-with-facebook-login/product-tagging/
- https://support.google.com/merchants/answer/14815513?hl=en
- https://support.google.com/youtube/answer/12257682?hl=en
- https://feedonomics.com/blog/youtube-shopping-product-feeds/
- https://github.com/Lundehund/tiktok-shop-api
- https://almcorp.com/blog/meta-in-app-sales-tools-facebook-instagram/

## Assessment
- New information ratio: 0.92
- Questions addressed: Q19, Q20, Q21
- Questions answered: Q19 (partially — varies by platform), Q20 (fully), Q21 (fully — OSS libraries inadequate, use direct API)

## Reflection
- What worked and why: WebSearch for each platform's shopping API docs returned high-quality, authoritative results. The TikTok developer blog gave clear Affiliate API capability summary. The Instagram Product Tagging API docs page was the highest-value source — it contains complete endpoint documentation with parameters, making it immediately actionable. Fetching the Lundehund GitHub repo quickly confirmed it was inadequate, saving time.
- What did not work and why: TikTok Shop Partner Center docs site is an SPA that returns minimal content via WebFetch. The actual API endpoint specifications for TikTok Shop require authenticated access to the Partner Center portal.
- What I would do differently: For TikTok Shop, would try fetching the raw API reference pages or looking for community-written integration guides rather than the official SPA docs site.

## Recommended Next Focus
1. **Convergence synthesis**: With Q1-Q21 now substantially addressed (14/18 original + 3 new answered), a consolidation iteration synthesizing all findings into a final architecture recommendation would be high value.
2. **n8n workflow node mapping**: Map specific n8n nodes (built-in vs HTTP Request) for each platform's upload + cart pin workflow.
3. **Phase 1 MVP scope definition**: Define exactly what is automated vs manual in Phase 1, based on API availability findings from iterations 6-7.
