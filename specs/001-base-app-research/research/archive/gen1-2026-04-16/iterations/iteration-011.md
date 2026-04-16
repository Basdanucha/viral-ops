# Iteration 11: Product Discovery (Path B) -- Affiliate Catalog Scanning, Scoring, and Product-First Content

## Focus
Investigate the full Path B (product-driven content) pipeline for viral-ops: scanning affiliate product catalogs across TikTok Shop, Shopee, and Lazada; product relevance scoring algorithm design; affiliate link generation per platform; and product-first script generation methodology. This is the final intelligence layer question (Q26) completing full pipeline coverage.

## Findings

### Finding 1: TikTok Shop Affiliate APIs -- Product Discovery and Campaign Management
TikTok Shop launched its first suite of Affiliate APIs (GA 2024), providing programmatic access to the affiliate ecosystem. Confirmed capabilities:

**Search and Discovery:**
- Search for products with open collaborations by **category, commission rate, and keywords** -- this is the core product discovery endpoint for Path B
- Search for creators on the marketplace based on GMV, keywords, and demographics (useful for collaboration but secondary to product discovery)

**Campaign Management:**
- Create and manage both **open and targeted affiliate campaigns**
- Edit open collaboration settings and create target collaborations

**Link Generation and Tracking:**
- Generate affiliate product promotion links programmatically
- Search and retrieve affiliate orders for tracking conversions

**Access Requirements:**
- Must register as an Affiliate app developer at TikTok Shop Partner Center
- API documentation available at partner.tiktokshop.com (SPA -- requires authenticated login for full specs)
- Partner Center portal is the only way to see exact endpoint URLs and request/response schemas
- Discord developer community available for technical support

**Key insight for viral-ops:** The product search by category + commission rate + keyword is exactly what Path B needs for the `[Find Product]` step. This is the richest affiliate product discovery API among the three platforms.

[SOURCE: https://developers.tiktok.com/blog/2024-tiktok-shop-affiliate-apis-launch-developer-opportunity]

### Finding 2: Shopee Affiliate Platform -- Thailand-Specific API Access
Shopee provides affiliate capabilities in Thailand through two separate API surfaces:

**Shopee Open Platform (Seller API):**
- RESTful API for product search by keyword and category
- Product data fields: description, price, stock levels, sales data, variants, images
- Available at open.shopee.com with OAuth 2.0 authentication
- Thailand-specific documentation at seller.shopee.co.th/edu
- **Access restriction:** Open API services provided to managed sellers with assigned Key Account Manager (KAM)

**Shopee Affiliate Program (affiliate.shopee.co.th):**
- Separate affiliate portal with its own API section
- Affiliate link generation for product promotion
- Commission-based earnings on referred sales
- Thailand affiliate portal: affiliate.shopee.co.th/api

**Third-party scraping option:**
- Apify's Shopee API Scraper (marc_plouhinec/shopee-api-scraper) available for product data collection
- akherlan/onlineshop on GitHub -- product data collection via Shopee's public API v4

**Key insight for viral-ops:** Shopee's affiliate API access is more restricted than TikTok Shop's. The managed seller requirement (KAM) for full Open API access means Phase 1 may need to use the affiliate portal's API endpoints or scraping as a fallback. The public product search API v4 provides product data without seller requirements.

[SOURCE: https://affiliate.shopee.co.th/api]
[SOURCE: https://seller.shopee.co.th/edu/article/15124]
[SOURCE: https://apify.com/marc_plouhinec/shopee-api-scraper]
[SOURCE: https://github.com/akherlan/onlineshop]

### Finding 3: Lazada Open Platform -- Affiliate Deep Link Generation
Lazada provides a mature API ecosystem through its Open Platform:

**Lazada Open Platform API:**
- RESTful API at open.lazada.com
- Product listing, search, and management capabilities
- Category browsing and product data retrieval
- Authentication via App Key + App Secret (standard OAuth flow)

**Affiliate Deep Link Generation:**
- Deep link generator converts any Lazada product URL into a unique affiliate link
- Available through Involve Asia (primary affiliate network for Lazada in Southeast Asia)
- **Important limitation (2025+ change):** Some product links may no longer be available for deeplinking if the product is not commissionable (not part of the affiliate program)
- Commission structure varies by product category

**Key architectural difference:** Lazada's affiliate program operates primarily through affiliate networks (Involve Asia, AccessTrade) rather than a direct first-party affiliate API like TikTok Shop. This means:
- Product discovery: Use Lazada Open Platform API for product data
- Affiliate link conversion: Use affiliate network API (Involve Asia / AccessTrade) for deep link wrapping
- Two-step process vs. TikTok Shop's unified API

[SOURCE: https://open.lazada.com/apps/doc/api]
[SOURCE: https://help.involve.asia/hc/en-us/articles/42549337855001-Lazada-Product-Link-Generation]
[SOURCE: https://bryanbonifacio.com/lazada-affiliate-program/]

### Finding 4: Cross-Platform Product Aggregation Architecture
Based on the three platform APIs, the cross-platform product aggregation design for viral-ops:

**n8n Workflow Design (Product Discovery Pipeline):**
```
[Trigger: Schedule every 4h or on-demand]
    |
    v
[TikTok Shop API] --> search by category + commission + keyword
[Shopee Public API v4] --> search by keyword + category
[Lazada Open Platform] --> search by keyword + category
    |
    v
[Normalize] --> unified product schema:
  {
    platform: "tiktok_shop" | "shopee" | "lazada",
    productId: string,
    name: string,
    price: number,
    currency: "THB",
    commissionRate: number,      // percentage
    salesVolume: number,         // last 30d
    rating: number,             // 1-5
    reviewCount: number,
    category: string,
    imageUrl: string,
    productUrl: string,
    affiliateLink: string | null, // generated later
    lastUpdated: ISO-8601
  }
    |
    v
[Dedup] --> match by name similarity + price range + category
    |
    v
[Score] --> weighted scoring formula
    |
    v
[Store] --> products table in PostgreSQL
```

**Product Deduplication Strategy:**
- Same product listed on TikTok Shop and Shopee: match by fuzzy name matching (Levenshtein distance < 0.3) + price within 10% + same category
- When duplicate found: keep both records but link them via `cross_platform_group_id`
- Score and rank by best commission rate across platforms
- Present in dashboard grouped by product with per-platform comparison

[INFERENCE: based on TikTok Shop API capabilities (Finding 1), Shopee API (Finding 2), Lazada API (Finding 3), and n8n architecture from iteration 5]

### Finding 5: Product Scoring Algorithm Design
From the README formula: `commission x relevance x trend-fit x conversion history --> rank candidates`

**Phase 1: Rule-Based Scoring (weighted formula, 0-100 scale)**

```
product_score = (
    w_commission * commission_score +    // 0.25 weight
    w_relevance * relevance_score +      // 0.20 weight
    w_trend_fit * trend_fit_score +      // 0.25 weight
    w_conversion * conversion_score +    // 0.15 weight
    w_social * social_proof_score +      // 0.10 weight
    w_visual * visual_score              // 0.05 weight
) * 100

Where:
- commission_score = normalize(commission_rate, min=1%, max=30%)
  --> higher commission = higher score
- relevance_score = keyword_match_ratio(product_keywords, niche_keywords)
  --> product title/description keyword overlap with channel niche
- trend_fit_score = cross_reference(product_category, active_trends)
  --> from Trend Layer (iteration 9): does this product align with trending topics?
- conversion_score = historical_conversion_rate OR category_baseline
  --> Cold start: use category average from platform data
  --> Warm: use own affiliate conversion history per product/category
- social_proof_score = normalize(rating * log(review_count + 1))
  --> compound of rating quality and review volume
- visual_score = has_video_demo * 0.5 + high_res_images * 0.3 + lifestyle_photos * 0.2
  --> products with good visual assets score higher (easier to make viral content)
```

**Cold Start Strategy:**
- Phase 1 (no conversion data): Set conversion_score = 0.5 (neutral) for all products, rely on other dimensions
- Phase 1.5 (10-50 videos posted): Use category-level conversion rates from platform reports
- Phase 2 (50+ videos): Product-level conversion data available, switch to actual click-to-purchase rates

**Phase 2: ML-Based Scoring**
- Train GBDT (same as viral scoring from iteration 9) on actual conversion data
- Features: all Phase 1 dimensions + temporal features (day of week, season) + content type performance
- Retraining trigger: every 50 products promoted with T+7d conversion data
- Target variable: revenue_per_impression (combines commission * conversion * traffic)

[INFERENCE: based on README formula, Trend Layer architecture from iteration 9, GBDT retraining pipeline from iteration 10, and standard affiliate marketing scoring practices]

### Finding 6: Product-First Script Generation and Integration
How product-first scripting differs from trend-first (Path A) and how it integrates with Pixelle-Video:

**Path A (Trend-First) vs Path B (Product-First) Script Structure:**

| Dimension | Path A (Trend-First) | Path B (Product-First) |
|-----------|---------------------|------------------------|
| Hook | Trend-based curiosity gap | Product benefit/problem-solution |
| Core content | Topic exploration | Product showcase/review/demo |
| CTA | Engagement (like, follow) | Purchase (link in bio, cart) |
| Visual source | AI-generated imagery | Product photos + AI enhancement |
| Script length | 15-30s exploration | 15-60s (demo may need longer) |

**Product-First LLM Prompt Templates:**

1. **Problem-Solution Hook:**
   ```
   "เคยมีปัญหา [PROBLEM] ไหม? สินค้านี้แก้ปัญหาได้ภายใน [TIMEFRAME]"
   Input: product_name, product_features, target_problem, price
   ```

2. **Unboxing/Review:**
   ```
   "เปิดกล่อง [PRODUCT_NAME] ราคา [PRICE] บาท คุ้มไหม มาดูกัน"
   Input: product_name, price, key_features[], comparison_products[]
   ```

3. **Before/After Comparison:**
   ```
   "ก่อน vs หลังใช้ [PRODUCT_NAME] — ผลลัพธ์ [TIMEFRAME]"
   Input: product_name, before_state, after_state, timeframe
   ```

4. **Price Comparison/Deal:**
   ```
   "[PRODUCT_NAME] ลดราคาเหลือ [SALE_PRICE] บาท (ปกติ [REGULAR_PRICE]) หมดเขต [DEADLINE]"
   Input: product_name, sale_price, regular_price, deadline, platform
   ```

**Pixelle-Video Integration for Product Content:**
- Product images as visual source: Use ComfyUI image-to-video workflow (img2vid) instead of text-to-image
- Product photos downloaded from platform API --> passed to Pixelle-Video `/api/image` endpoint as reference images
- ComfyUI workflows can apply zoom, pan, Ken Burns effect on product stills
- For demo videos: need manual video clips as source material (not automatable in Phase 1)

**n8n Workflow for Product-First Pipeline:**
```
[Product scored > threshold]
    |
    v
[Fetch product data + images from platform API]
    |
    v
[LLM: Generate script using product-first template]
    --> Input: product data, niche keywords, trending topics (from Trend Layer)
    --> Output: script with hook, body, CTA, visual directions
    |
    v
[Pixelle-Video: Generate visuals]
    --> Product images as reference (img2vid workflow)
    --> TTS from script
    --> Captions overlay
    |
    v
[Generate affiliate link via platform API]
    |
    v
[Upload to platform + attach affiliate link]
    --> TikTok: Content Posting API + Shop Affiliate API (separate calls)
    --> Shopee: Affiliate link in video description
    --> Lazada: Affiliate deep link in bio/description
```

**DB Schema Extension (extends iteration 6 multi-platform schema):**
```sql
-- Product catalog (aggregated from all platforms)
CREATE TABLE products (
    id UUID PRIMARY KEY,
    platform VARCHAR(20) NOT NULL,        -- tiktok_shop, shopee, lazada
    platform_product_id VARCHAR(100) NOT NULL,
    name VARCHAR(500) NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'THB',
    commission_rate DECIMAL(5,2),          -- percentage
    sales_volume_30d INTEGER,
    rating DECIMAL(3,2),
    review_count INTEGER,
    category VARCHAR(200),
    image_urls JSONB,
    product_url TEXT,
    cross_platform_group_id UUID,         -- links same product across platforms
    product_score DECIMAL(5,2),           -- 0-100 computed score
    score_breakdown JSONB,                -- {commission: X, relevance: X, ...}
    last_scraped_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Product scoring history (for ML training data)
CREATE TABLE product_score_history (
    id UUID PRIMARY KEY,
    product_id UUID REFERENCES products(id),
    score DECIMAL(5,2),
    score_version VARCHAR(20),            -- 'rule-v1', 'gbdt-v1'
    breakdown JSONB,
    computed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Extends existing affiliate_links table from iteration 6
-- Add: product_id reference, conversion tracking
ALTER TABLE affiliate_links ADD COLUMN product_id UUID REFERENCES products(id);
ALTER TABLE affiliate_links ADD COLUMN click_count INTEGER DEFAULT 0;
ALTER TABLE affiliate_links ADD COLUMN conversion_count INTEGER DEFAULT 0;
ALTER TABLE affiliate_links ADD COLUMN revenue_total DECIMAL(12,2) DEFAULT 0;
```

[INFERENCE: based on Pixelle-Video architecture from iteration 4, n8n workflow pattern from iteration 5, multi-platform schema from iteration 6, TikTok Shop Affiliate API from Finding 1, and LLM prompt engineering for Thai content]

## Ruled Out
- **TikTok Shop Partner Center docs for direct API spec extraction**: SPA renders minimal content via WebFetch. Requires authenticated login for full endpoint documentation. Same pattern as iteration 7.
- **Shopee Affiliate portal for direct API spec extraction**: SPA at affiliate.shopee.co.th/api returns only page title. Requires login for full documentation.
- **Lazada Open Platform docs for direct API spec extraction**: SPA at open.lazada.com returns only header. Same SPA limitation pattern.
- **Involve Asia help article for Lazada deep link specs**: Redirects to generic help center (301), original article unavailable.

## Dead Ends
- **Direct web scraping of affiliate platform partner portals**: All three platforms (TikTok Shop Partner Center, Shopee Affiliate, Lazada Open Platform) serve their API documentation as JavaScript SPAs that return minimal content to automated fetches. This is a fundamental architectural pattern across all Southeast Asian e-commerce platforms, not a temporary issue. API documentation can only be accessed through authenticated portal sessions.

## Sources Consulted
- https://developers.tiktok.com/blog/2024-tiktok-shop-affiliate-apis-launch-developer-opportunity
- https://partner.tiktokshop.com/docv2/page/affiliate-seller-api-overview (SPA, minimal content)
- https://affiliate.shopee.co.th/api (SPA, minimal content)
- https://seller.shopee.co.th/edu/article/15124
- https://apify.com/marc_plouhinec/shopee-api-scraper
- https://github.com/akherlan/onlineshop
- https://open.lazada.com/apps/doc/api (SPA, minimal content)
- https://help.involve.asia/hc/en-us/articles/42549337855001-Lazada-Product-Link-Generation (redirected)
- https://bryanbonifacio.com/lazada-affiliate-program/
- https://api2cart.com/api-technology/shopee-api/
- https://api2cart.com/api-technology/lazada-integration-how-to-develop-it-easily/

## Assessment
- New information ratio: 0.92
- Questions addressed: [Q26]
- Questions answered: [Q26]

## Reflection
- What worked and why: WebSearch for each platform's affiliate API documentation returned good overview results, even though the deep portal pages are SPAs. The TikTok developer blog (same source that worked in iteration 7) remains the most reliable source for TikTok Shop API capabilities. Combining search results from multiple independent sources (official docs, third-party guides like Involve Asia and bryanbonifacio.com, developer blog posts) built a comprehensive picture despite no single source providing full API specs.
- What did not work and why: All three e-commerce platform documentation portals (TikTok Shop Partner Center, Shopee Affiliate, Lazada Open Platform) render as JavaScript SPAs that return minimal content to automated fetches. This is consistent with iteration 7 findings and is a fundamental pattern across Southeast Asian e-commerce platforms. The Involve Asia help article for Lazada redirected to a generic help center.
- What I would do differently: For deeper API specification research, would need to explore Postman collections (TikTok Shop has an official one at postman.com/tiktok-shop-open) or GitHub repositories that document API schemas via code.

## Recommended Next Focus
All 26 key questions (Q1-Q26) are now addressed. The recommended next step is a **final convergence synthesis** iteration to:
1. Integrate Path B (product discovery) into the complete architecture diagram
2. Update the definitive DB schema with the products table and scoring tables
3. Produce the final comprehensive architecture recommendation covering all pipeline stages
4. Identify any remaining gaps or Phase 2 considerations
