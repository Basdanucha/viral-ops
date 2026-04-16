# Iteration 3: next-forge Version Confirmation + shadcn/ui Charts + Remaining Component Versions

## Focus
Confirm next-forge's exact dependency versions (Next.js, Tailwind, React), verify shadcn/ui charts as Tremor replacement, and pin remaining stack component versions (TypeScript, PostgreSQL, Auth.js).

## Findings

1. **next-forge v6.0.2 uses Next.js 16.1.6, Tailwind CSS 4.2.1, React 19.2.4** -- The root package.json is a Turborepo monorepo; actual framework deps live in `apps/web/package.json`. Confirmed: Next.js 16.1.6 (not 15.x), Tailwind CSS 4.2.1 (v4, not v3), React 19.2.4. Also uses Zod 4.3.6, Sentry 10.42.0, date-fns 4.1.0, sharp 0.34.5. TypeScript ^5.9.3 pinned in root devDependencies. [SOURCE: https://raw.githubusercontent.com/haydenbleasel/next-forge/main/apps/web/package.json]

2. **next-forge monorepo structure uses workspace packages for auth, design-system, CMS, email, analytics** -- Auth is in `@repo/auth` (not directly Clerk in web app), design system in `@repo/design-system` (likely wraps shadcn/ui), Prisma presumably in a database package. No Prisma or Clerk directly in `apps/web/package.json`. Uses Arcjet for security, Fumadocs for docs, MDX bundler. [SOURCE: https://raw.githubusercontent.com/haydenbleasel/next-forge/main/apps/web/package.json]

3. **shadcn/ui has full chart support built on Recharts v3** -- Six chart types available: Bar, Line, Area, Pie, Radar, Radial. Custom components: `ChartContainer`, `ChartTooltip`, `ChartTooltipContent`, `ChartLegend`, `ChartLegendContent`. Uses configuration-based `ChartConfig` system. Install via `pnpm dlx shadcn@latest add chart`. Does NOT wrap Recharts -- allows direct use of Recharts components with optional custom wrappers. Sufficient for analytics dashboard (covers all chart types needed). [SOURCE: https://ui.shadcn.com/docs/components/chart]

4. **Auth.js has merged into / been absorbed by Better Auth** -- The authjs.dev homepage now states "The Auth.js project is now part of Better Auth." This is a significant change from gen1 where Auth.js v5 was planned. Need to evaluate Better Auth as replacement or decide whether to use next-forge's built-in Clerk auth instead. [SOURCE: https://authjs.dev]

5. **TypeScript 6.0 is the current stable release** -- Major version jump from 5.x to 6.0. next-forge pins ^5.9.3 in root devDeps (compatible with 5.9.x but not auto-upgrading to 6.0). Viral-ops should decide: pin 5.9.x for stability with next-forge, or upgrade to 6.0 (may require next-forge compatibility check). [SOURCE: https://www.typescriptlang.org/download/]

6. **PostgreSQL 18.3 is the latest stable (Feb 2026)** -- PG 18 is the current major version, not PG 17 as expected. Supported versions: 18.3, 17.9, 16.13, 15.17, 14.22. Gen1 planned PG 16.x; upgrading to PG 17.x or 18.x is recommended. Prisma 7.4 compatibility with PG 18 needs verification but Prisma typically supports latest PG within weeks of release. [SOURCE: https://www.postgresql.org/]

7. **next-forge uses Bun 1.3.10 as package manager** -- Root package.json specifies `packageManager: bun@1.3.10`. This is notable since gen1 assumed npm/pnpm. Bun is compatible with Node.js 18+ (engine requirement). [SOURCE: https://raw.githubusercontent.com/haydenbleasel/next-forge/main/package.json]

## Ruled Out
- Direct npm registry scraping (already BLOCKED from iteration 2)
- Checking individual next-forge workspace packages (e.g., `@repo/auth`, `@repo/design-system`) for exact Clerk/Prisma versions -- deferred due to tool budget. The web app package.json confirmed the framework versions which was the priority.

## Dead Ends
- **Auth.js v5 as auth solution**: Auth.js has been absorbed into "Better Auth" project. The authjs.dev site confirms this. Auth.js v5 as a standalone maintained project is effectively deprecated. This eliminates Auth.js as a direct dependency choice -- must either adopt Better Auth, use Clerk (next-forge default), or evaluate alternatives.

## Sources Consulted
- https://raw.githubusercontent.com/haydenbleasel/next-forge/main/package.json (root monorepo config)
- https://raw.githubusercontent.com/haydenbleasel/next-forge/main/apps/web/package.json (web app deps)
- https://ui.shadcn.com/docs/components/chart (shadcn/ui charts documentation)
- https://authjs.dev (Auth.js homepage -- Better Auth merger notice)
- https://www.typescriptlang.org/download/ (TypeScript latest version)
- https://www.postgresql.org/ (PostgreSQL latest version)

## Assessment
- New information ratio: 0.86
- Questions addressed: Q1, Q5, Q6, Q8
- Questions answered: Q1 (next-forge confirmed with versions), Q6 (shadcn/ui charts confirmed as Tremor replacement), Q8 (TypeScript 6.0, PostgreSQL 18.3 pinned)

## Reflection
- What worked and why: Fetching raw GitHub file URLs for package.json gave exact version numbers immediately -- much more reliable than rendered GitHub pages. The shadcn/ui docs page was well-structured and gave comprehensive chart coverage info in one fetch.
- What did not work and why: The root next-forge package.json did not contain framework deps (monorepo pattern) -- needed a second fetch for the web app's package.json. This cost an extra tool call.
- What I would do differently: For monorepos, go directly to `apps/*/package.json` first rather than root.

## Recommended Next Focus
1. **Verify next-forge workspace packages** -- Check `@repo/auth` (Clerk version), `@repo/design-system` (shadcn/ui version), and database package (Prisma version) to fully pin next-forge's internal dependency versions.
2. **Evaluate Better Auth vs Clerk** -- Auth.js is dead; next-forge uses Clerk. Decide if Clerk is acceptable for viral-ops or if Better Auth should be evaluated.
3. **Remaining unchecked: Pixelle-Video (Q7), ComfyUI + Edge-TTS (Q9)** -- These AI/media components still need version checks.
4. **Architecture compatibility check (Q10)** -- With all versions pinned, verify the 3-service localhost architecture still works.
