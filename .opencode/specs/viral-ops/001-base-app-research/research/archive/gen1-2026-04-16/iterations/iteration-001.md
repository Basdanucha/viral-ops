# Iteration 1: OSS SaaS Boilerplate Landscape Survey

## Focus
Survey the landscape of open-source SaaS boilerplates and starter kits. Identify top candidates that could serve as the "chassis" app for viral-ops, providing auth, billing, dashboard UI, API layer, job queue, and multi-tenant foundation.

## Findings

### 1. BoxyHQ SaaS Starter Kit — Best Enterprise-Ready Boilerplate
- **Stack**: Next.js + TypeScript + Prisma + PostgreSQL + NextAuth + Stripe
- **Stars**: 4.8k | **Forks**: 1.2k | **License**: Apache 2.0
- **Auth**: Email/password, magic link, SAML SSO, OAuth (GitHub, Google), Directory Sync (SCIM)
- **Multi-tenant**: First-class team management, RBAC, member invitations
- **Dashboard**: Included with Tailwind CSS
- **API**: REST-based with Svix webhooks
- **Job queue**: None built-in (gap for viral-ops)
- **Billing**: Listed as "Coming Soon" (gap)
- **Strengths**: Enterprise SSO, audit logs (Retraced), webhook orchestration (Svix), E2E tests (Playwright), Docker Compose setup
- **Weakness**: No billing integration yet; no background job system
- **Fit for viral-ops**: HIGH for multi-tenant foundation + auth; needs job queue and billing added
- [SOURCE: https://github.com/boxyhq/saas-starter-kit]

### 2. Open SaaS (Wasp) — Best All-In-One Starter
- **Stack**: Wasp framework (React + Node.js) + Prisma + PostgreSQL + ShadCN UI
- **Stars**: 14.1k | **Forks**: 1.7k | **License**: MIT
- **Auth**: Email verified + OAuth (Google, GitHub, Slack, Microsoft)
- **Multi-tenant**: Not explicitly built-in (user-level, not team-level)
- **Dashboard**: Admin dashboard with ShadCN UI
- **API**: Type-safe endpoints built into Wasp framework
- **Job queue**: Built-in cron jobs and queue system via Wasp config
- **Billing**: Stripe, Polar.sh, or Lemon Squeezy
- **Strengths**: One-command deploy, AI integration examples (OpenAI), end-to-end type safety, background jobs built-in, multiple payment providers
- **Weakness**: Wasp is a meta-framework (added abstraction layer, smaller ecosystem than raw Next.js); multi-tenant/team support not built-in
- **Fit for viral-ops**: HIGH for rapid start + job queue; Wasp lock-in is a risk for complex pipeline customization
- [SOURCE: https://github.com/wasp-lang/open-saas]

### 3. Saasfly — Modern Next.js Boilerplate
- **Stack**: Next.js (App Router, React 19) + Prisma + Kysely + PostgreSQL + Clerk + Stripe + tRPC + Turborepo
- **Stars**: 2.9k | **Forks**: 409 | **License**: MIT
- **Auth**: Clerk (default) or NextAuth.js (separate branch)
- **Multi-tenant**: Architecture designed for enterprise scalability (not deeply built-in team RBAC)
- **Dashboard**: Admin dashboard (alpha stage, static pages)
- **API**: tRPC for end-to-end typesafe APIs + TanStack React Query
- **Job queue**: None built-in
- **Billing**: Stripe integration
- **Strengths**: Modern stack (React 19, Bun, Turborepo monorepo), i18n built-in, Zustand state management, ShadCN UI + Framer Motion
- **Weakness**: Dashboard is alpha; Clerk dependency adds vendor lock-in; no background job system
- **Fit for viral-ops**: MEDIUM — modern stack but dashboard not mature, no job queue
- [SOURCE: https://github.com/saasfly/saasfly]

### 4. Midday — Most Polished Production App (Reference Architecture)
- **Stack**: Next.js + React + Supabase (DB + Auth) + Trigger.dev (jobs) + TypeScript + Tailwind + Bun
- **Stars**: 14.2k | **Forks**: 1.4k | **License**: AGPL-3.0 (commercial license required for commercial use)
- **Auth**: Supabase Auth
- **Multi-tenant**: Supported via Supabase
- **Dashboard**: Production-grade web dashboard
- **API**: Railway-hosted API
- **Job queue**: Trigger.dev for background jobs
- **Billing**: Polar
- **Additional**: Tauri (desktop), Expo (mobile), Typesense (search), OpenPanel (analytics), AI (Gemini + OpenAI)
- **Strengths**: Most complete production app; background jobs via Trigger.dev; search via Typesense; multi-platform (web + desktop + mobile)
- **Weakness**: AGPL-3.0 license requires commercial license for commercial use; tightly coupled to Supabase; it's a financial tool, not a generic SaaS shell
- **Fit for viral-ops**: MEDIUM as fork base (AGPL license + domain-specific), HIGH as reference architecture for Supabase + Trigger.dev patterns
- [SOURCE: https://github.com/midday-ai/midday]

### 5. Documenso — Reference for Prisma + Inngest Pattern
- **Stack**: Next.js + React + Prisma + PostgreSQL + NextAuth + Stripe + tRPC + ShadCN UI
- **Stars**: 12.7k | **Forks**: 2.5k | **License**: AGPL-3.0
- **Auth**: NextAuth
- **Multi-tenant**: Enterprise plan (not open-source multi-tenant)
- **Dashboard**: Production-grade document management UI
- **API**: tRPC
- **Job queue**: Inngest integration for scheduled reminders
- **Strengths**: Mature monorepo structure, Prisma + tRPC + ShadCN stack is very common, Inngest for background jobs
- **Weakness**: AGPL license; domain-specific (document signing); would require heavy gutting to repurpose
- **Fit for viral-ops**: LOW as fork base, MEDIUM as reference architecture for Prisma + Inngest + tRPC patterns
- [SOURCE: https://github.com/documenso/documenso]

### 6. Landscape Patterns Observed (Cross-Cutting)
- **Dominant stack**: Next.js + TypeScript + Prisma + PostgreSQL + Tailwind + ShadCN UI appears in 4/5 candidates
- **Auth convergence**: NextAuth (3/5) or Clerk (1/5) or Supabase Auth (1/5)
- **Billing**: Stripe dominates (4/5), with Polar and Lemon Squeezy as alternatives
- **Job queues**: This is the most divergent area — Trigger.dev, Inngest, Wasp built-in, or nothing at all
- **Multi-tenant gap**: Only BoxyHQ has first-class team/RBAC; most others are user-level only
- **License split**: MIT/Apache (BoxyHQ, Open SaaS, Saasfly) vs AGPL (Midday, Documenso)
- [INFERENCE: based on analysis of all 5 candidates]

## Ruled Out
- **Documenso as fork base**: Too domain-specific (document signing), AGPL license, would require extensive gutting. Useful only as reference architecture.
- **Midday as fork base**: AGPL license requires commercial license, tightly coupled to financial domain. Best used as reference for Supabase + Trigger.dev architecture.

## Dead Ends
None identified yet (first iteration, landscape survey).

## Sources Consulted
- https://github.com/boxyhq/saas-starter-kit
- https://github.com/wasp-lang/open-saas
- https://github.com/saasfly/saasfly
- https://github.com/midday-ai/midday
- https://github.com/documenso/documenso
- D:/Dev/Projects/viral-ops/research/notes-initial.md (existing research context)

## Assessment
- New information ratio: 0.90
- Questions addressed: Q1 (primary), Q3 (partial), Q7 (partial), Q8 (partial)
- Questions answered: None fully (need deeper evaluation of top 2-3 candidates)

## Reflection
- What worked and why: Fetching individual GitHub repo pages provided structured, reliable data on stack, features, and community metrics. Comparing 5 candidates in one iteration gave broad coverage.
- What did not work and why: Could not deeply evaluate job queue architectures or extensibility in a single landscape survey — need focused deep-dives in subsequent iterations.
- What I would do differently: Could have included 1-2 more candidates (e.g., Plausible, Cal.com, next-saas-stripe-starter) but tool budget constrained breadth. Will pick up in iteration 2.

## Recommended Next Focus
Deep-dive into the top 2 candidates for fork viability: **BoxyHQ SaaS Starter Kit** (best multi-tenant + MIT-like license) and **Open SaaS (Wasp)** (best all-in-one with job queue). Evaluate extensibility for viral-ops pipeline, investigate Wasp framework lock-in risks, and assess how easily BullMQ/Inngest could be added to BoxyHQ. Also investigate **next-saas-stripe-starter** and **Cal.com** as additional candidates not yet covered.
