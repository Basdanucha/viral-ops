# Iteration 2: Deep-Dive Fork Viability — BoxyHQ, Open SaaS (Wasp), next-saas-stripe-starter, Cal.com

## Focus
Deep-dive into the top 2 candidates from iteration 1 (BoxyHQ SaaS Starter Kit and Open SaaS/Wasp) for fork viability, plus evaluate two additional uncovered candidates (next-saas-stripe-starter and Cal.com/Cal.diy). Addresses Q3 (pipeline architecture support), Q5 (extensibility), and Q8 (licensing/community).

## Findings

### 1. BoxyHQ SaaS Starter Kit — Codebase Architecture
BoxyHQ uses **Next.js Pages Router** (not App Router) with a clean single-app structure (not monorepo). Key directories: `pages/`, `components/`, `hooks/`, `lib/`, `models/`, `prisma/`, `types/`. API routes live in `pages/api/`. TypeScript is 94.9% of codebase. Uses Svix for webhook orchestration, Retraced for audit logs, and SAML Jackson for enterprise SSO. **No background job/queue system exists** — all processing is synchronous request-response or webhook-driven via Svix. Adding BullMQ or Inngest would require: (a) adding Redis dependency for BullMQ or Inngest SDK, (b) creating a worker process or serverless function handler, (c) wiring API routes to enqueue jobs. The modular `pages/api/` + `lib/` structure makes this feasible but it is net-new infrastructure, not an extension of existing patterns.
[SOURCE: https://github.com/boxyhq/saas-starter-kit]

### 2. BoxyHQ — Multi-Tenant & Enterprise Features
Multi-tenancy is implemented via team-based isolation (create team, manage members, team settings). This is genuine RBAC with team scoping, not just user roles. Enterprise features include SAML SSO, Directory Sync (SCIM), audit logs (Retraced), and webhooks (Svix). **Stripe integration exists but billing/subscriptions marked "coming soon"** — payments are partially implemented. 4,800+ stars, 1,200+ forks, latest release v1.6.0 (Dec 2024). Apache 2.0 license confirmed.
[SOURCE: https://github.com/boxyhq/saas-starter-kit]

### 3. Open SaaS (Wasp) — Framework Lock-In Assessment
Wasp is a **Domain-Specific Language (DSL)** that generates React + Node.js + Prisma code. You write `.wasp` configuration files plus standard React/Node code. The DSL handles routing, auth, and job declarations. **Lock-in risk is MODERATE-HIGH**: (a) the `.wasp` file is a custom DSL, not standard JS/TS, (b) Wasp compiles to a `.wasp/out/` directory with generated code, (c) while the generated output is standard React+Node+Prisma, maintaining the ejected code means losing Wasp's tooling (hot reload, type generation, job declarations). **There is no official `wasp eject` command documented** — you would need to manually extract from `.wasp/out/`. The job system uses **pg-boss** (PostgreSQL-based job queue), which is simpler than BullMQ but tied to Postgres. Custom npm packages can be used, and custom API endpoints are supported, but all routing and entity definitions must go through the `.wasp` DSL file.
[SOURCE: https://wasp.sh/docs] [INFERENCE: based on Wasp architecture description — DSL generates React+Node+Prisma, .wasp/out contains compiled output]

### 4. next-saas-stripe-starter — Strong Contender Emerges
**next-saas-stripe-starter** (by mickasmt) is a **Next.js 14 App Router** starter with a modern stack: Auth.js v5, Prisma + Neon (serverless Postgres), Stripe, Shadcn/ui, Tailwind, Resend email, Contentlayer. Uses the App Router pattern with `actions/`, `app/`, `components/`, `hooks/`, `lib/`, `prisma/` directories. Includes admin panel with dashboard, user roles/RBAC, pricing table, OG image generation, and email templates. **No background jobs or multi-tenant support** — but uses standard Next.js patterns that are trivially extensible. MIT license. 3,000+ stars, 608 forks, latest v1.0.0 (June 2024). Key advantage: **App Router** (modern Next.js pattern) vs BoxyHQ's Pages Router (legacy pattern). TypeScript 81.3%.
[SOURCE: https://github.com/mickasmt/next-saas-stripe-starter]

### 5. Cal.com (Cal.diy) — Ruled Out as Fork Base
Cal.com/Cal.diy has an impressive technical foundation (Turborepo monorepo, tRPC, Prisma, NextAuth, Tailwind, 41.2k stars, MIT license) but is **deeply domain-specific to scheduling/booking**. Stripping the scheduling logic would leave minimal scaffolding. The monorepo structure with Turborepo is over-engineered for a solo-dev SaaS start. Enterprise features (teams, orgs, SSO) were removed in the Cal.diy fork. **Better used as architecture reference (tRPC patterns, monorepo setup) than as a fork base.**
[SOURCE: https://github.com/calcom/cal.com]

### 6. Comparative Fork Viability Matrix

| Criterion | BoxyHQ | Open SaaS (Wasp) | next-saas-stripe-starter |
|-----------|--------|-------------------|--------------------------|
| Router | Pages (legacy) | Generated | App Router (modern) |
| Auth | NextAuth + SAML SSO | Wasp built-in | Auth.js v5 |
| Multi-tenant | Yes (team-based RBAC) | No | No (has user roles) |
| Job queue | None | pg-boss (built-in) | None |
| Billing | Stripe (partial) | Stripe (full) | Stripe (full) |
| Lock-in risk | None (standard Next.js) | HIGH (Wasp DSL) | None (standard Next.js) |
| Extensibility | High (standard patterns) | Medium (DSL constraint) | High (standard patterns) |
| Stars | 4,800 | 8,000+ (Wasp total) | 3,000 |
| License | Apache 2.0 | MIT | MIT |
| Last activity | Dec 2024 | Active | June 2024 |

## Ruled Out
- **Cal.com/Cal.diy as fork base**: Too domain-specific (scheduling/booking), stripping would leave minimal scaffolding. Turborepo monorepo is over-engineered for solo-dev start. Better as architecture reference only.

## Dead Ends
- Cal.com as fork base is definitively eliminated — the domain coupling is fundamental, not superficial.

## Sources Consulted
- https://github.com/boxyhq/saas-starter-kit (GitHub repo page)
- https://wasp.sh/docs (Wasp framework documentation)
- https://github.com/mickasmt/next-saas-stripe-starter (GitHub repo page)
- https://github.com/calcom/cal.com (GitHub repo page, redirected to Cal.diy)

## Assessment
- New information ratio: 0.83
- Questions addressed: Q3 (pipeline/job queue support), Q5 (extensibility), Q8 (licensing/community)
- Questions answered: None fully — Q3 and Q5 partially answered with comparative data, Q8 substantially progressed

## Reflection
- What worked and why: Fetching individual GitHub repo pages continued to yield structured, reliable data on architecture, features, and extensibility. Comparing candidates side-by-side with a viability matrix crystallized trade-offs effectively.
- What did not work and why: Open SaaS website (opensaas.sh) returned minimal content — the site is likely a SPA that doesn't render well for scraping. Wasp docs landing page was too introductory for deep technical details on ejection/lock-in. Would need to fetch specific sub-pages (e.g., /docs/advanced/jobs).
- What I would do differently: Target specific documentation sub-pages rather than top-level docs pages. For Wasp, fetch `/docs/advanced/jobs` and `/docs/project/customizing` directly.

## Recommended Next Focus
1. **Resolve the BoxyHQ vs next-saas-stripe-starter decision**: BoxyHQ has multi-tenant RBAC but uses legacy Pages Router; next-saas-stripe-starter has modern App Router but no multi-tenancy. Since viral-ops starts solo-use, multi-tenancy can be added later — making App Router potentially more important.
2. **Deep-dive into job queue integration patterns**: How to add BullMQ or Inngest to a standard Next.js app. Compare pg-boss vs BullMQ vs Inngest for the viral-ops content pipeline.
3. **Investigate Saasfly more deeply** — it was flagged in iteration 1 as having i18n and modern stack but wasn't deeply evaluated.
4. **Address Q2 and Q6**: Dashboard UI framework decision (Shadcn vs Tremor vs Refine for data-heavy ops dashboard).
