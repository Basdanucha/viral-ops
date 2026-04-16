# Iteration 2: Boilerplate Replacement Candidates + Tremor Status

## Focus
Investigate boilerplate replacement candidates for next-saas-stripe-starter (Q1) and determine Tremor's maintenance status and Tailwind v4 compatibility (Q6). These are the two highest-priority open items from iteration 1.

## Findings

### Boilerplate Replacement Candidates

#### 1. next-forge (haydenbleasel/next-forge) -- RECOMMENDED
- **Description**: Production-grade Turborepo template for Next.js SaaS applications
- **Stars**: 7,000
- **License**: MIT
- **Latest release**: v6.0.2 (March 20, 2026) -- actively maintained
- **Commits**: 1,495 on main, 367 total releases, 8 open PRs
- **Tech stack**:
  - ORM: Prisma
  - Auth: Clerk
  - UI: Tailwind CSS + TWBlocks
  - Payments: Stripe
- **Structure**: Turborepo monorepo with apps (web, app, api, docs, email, storybook) + shared packages
- **Batteries included**: Marketing site, main app with auth, RESTful API, documentation, email templates, component library, payments, analytics, observability, security, CMS, AI utilities, webhooks, i18n
- **Gap vs viral-ops needs**: Uses Clerk (not Auth.js), no ShadCN UI mentioned (uses TWBlocks), Tailwind version not confirmed
- **Assessment**: STRONG CANDIDATE. Active, MIT, Prisma+Stripe, monorepo structure. Auth provider (Clerk vs Auth.js) is swappable.
[SOURCE: https://github.com/haydenbleasel/next-forge]

#### 2. create-t3-app (t3-oss/create-t3-app) -- SECONDARY OPTION
- **Description**: Interactive CLI to start a full-stack, typesafe Next.js app
- **Stars**: 28,800 (very popular)
- **License**: MIT
- **Latest release**: v7.40.0 (November 5, 2025) -- 5 months ago, yellow flag for maintenance
- **Commits**: 1,378 on main, 139 total releases
- **Tech stack**:
  - ORM: Prisma or Drizzle (user choice)
  - Auth: NextAuth.js
  - UI: Tailwind CSS
  - tRPC for type-safe APIs
  - TypeScript
- **No billing/payments included** (explicitly excluded from scope)
- **No ShadCN UI bundled** (just Tailwind)
- **Gap vs viral-ops needs**: No Stripe integration, last release 5 months old, no Next.js 16 confirmation
- **Assessment**: SECONDARY. Very popular but scaffold-only (no batteries), no payments, maintenance gap. Good for typesafety focus (tRPC) but needs significant additions.
[SOURCE: https://github.com/t3-oss/create-t3-app]

#### 3. Comparative Assessment
| Criteria | next-forge | create-t3-app | viral-ops needs |
|----------|-----------|---------------|-----------------|
| Last release | Mar 2026 | Nov 2025 | Active in 2026 |
| Stars | 7k | 28.8k | - |
| Prisma | Yes | Yes (or Drizzle) | Yes |
| Auth | Clerk | NextAuth.js | Auth.js preferred |
| Payments | Stripe | None | Stripe required |
| UI | TWBlocks | Tailwind only | ShadCN UI preferred |
| Monorepo | Turborepo | No | Nice to have |
| tRPC | No | Yes | Not required |
| Next.js 16 confirmed | Not explicit (v6.0.2 Mar 2026 likely) | Not confirmed | Required |
| License | MIT | MIT | MIT required |

**Recommendation**: next-forge is the stronger candidate for viral-ops due to Stripe integration, active maintenance (Mar 2026), Prisma, and batteries-included approach. Auth swap from Clerk to Auth.js is a known migration pattern. Need to confirm Next.js 16 + Tailwind v4 in next iteration.

### Tremor Status Investigation

#### 4. Tremor (@tremor/react) -- LIKELY DEPRECATED/STALLED
- **npm registry**: Returned 403 (access blocked for direct scraping)
- **GitHub releases page**: Shows "There aren't any releases here" -- zero GitHub releases published
- **tremor-raw (tremorlabs/tremor-raw)**: Only 3 stars, 2 commits, 0 releases. README says "This repository has moved: https://github.com/tremorlabs/tremor" -- merged back into main repo
- **Previous data (iteration 1)**: Only 84 commits on main, 3.4k stars, 148 forks
- **No Tailwind v4 mentions** found anywhere
- **Assessment**: HIGH RISK. Tremor appears to have very low development activity. Zero GitHub releases, tremor-raw abandoned and merged back. The 84-commit count from iteration 1 combined with zero releases strongly suggests the project is stalled or has shifted to a different publishing model. Tailwind v4 compatibility is UNCONFIRMED and likely absent.
[SOURCE: https://github.com/tremorlabs/tremor/releases]
[SOURCE: https://github.com/tremorlabs/tremor-raw]

#### 5. Tremor Replacement Strategy
If Tremor is dead/incompatible with Tailwind v4, alternatives include:
- **shadcn/ui charts** (shadcn added chart components based on Recharts -- preferred since we want ShadCN UI anyway)
- **Recharts** directly (Tremor was a wrapper around Recharts)
- **nivo** (React charting, good for dashboards)
- **Apache ECharts / echarts-for-react** (enterprise-grade)
- **Recommendation**: shadcn/ui charts is the natural replacement since viral-ops already targets ShadCN UI. This eliminates the Tremor dependency entirely and aligns the charting with the component library.
[INFERENCE: based on gen1 architecture (Tremor wraps Recharts) + shadcn/ui adding chart components]

## Ruled Out
- **npm direct scraping for Tremor**: Returns 403, need alternative approach (GitHub API or registry.npmjs.org API)
- **taxonomy (shadcn/taxonomy)**: Not investigated this iteration due to tool budget -- defer to iteration 3
- **Makerkit, SaaS-Starter-Kit, SaaSBold, Shipfast**: Not investigated this iteration -- defer to iteration 3 if next-forge doesn't pan out

## Dead Ends
- **tremor-raw as alternative to Tremor**: Confirmed dead. Only 2 commits, redirects to main tremor repo. Not a viable separate path.

## Sources Consulted
- https://github.com/haydenbleasel/next-forge (fetched: stars, releases, structure, tech stack)
- https://github.com/t3-oss/create-t3-app (fetched: stars, releases, tech stack, features)
- https://github.com/tremorlabs/tremor/releases (fetched: zero releases confirmed)
- https://github.com/tremorlabs/tremor-raw (fetched: abandoned, merged back)
- https://www.npmjs.com/package/@tremor/react (attempted: 403 blocked)

## Assessment
- New information ratio: 0.80
- Questions addressed: Q1 (boilerplate replacement), Q6 (Tremor + ShadCN + Tailwind v4 compat)
- Questions answered: None fully (Q1 has strong candidate but needs version confirmation; Q6 Tremor risk confirmed but replacement decision pending)

## Reflection
- What worked and why: Fetching GitHub repo pages directly gave rich metadata (stars, releases, commit count, tech stack) for boilerplate evaluation. Checking both the main tremor repo releases AND the tremor-raw repo gave a clear picture of project health.
- What did not work and why: npm registry direct fetch returned 403. Next time, use registry.npmjs.org API endpoint or `npm view` CLI command instead.
- What I would do differently: For npm package info, use `npm view @tremor/react` via Bash instead of web fetching npmjs.com.

## Recommended Next Focus
1. **Confirm next-forge versions (Q1 finalization)**: Check next-forge's package.json or docs for exact Next.js version, Tailwind version, and whether it supports Tailwind v4. This determines if it's the final answer for Q1.
2. **shadcn/ui charts investigation (Q6 resolution)**: Confirm shadcn/ui has chart components and evaluate them as Tremor replacement. Check shadcn/ui Tailwind v4 compatibility.
3. **Remaining component versions (Q5, Q7, Q8, Q9)**: Auth.js, TypeScript, PostgreSQL, ShadCN UI, Pixelle-Video, ComfyUI, Edge-TTS -- use npm/CLI checks for speed.
