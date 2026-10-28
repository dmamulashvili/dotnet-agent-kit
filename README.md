# dotnet-agent-kit

`dotnet new` template that adds AI coding agent config (Claude Code: `CLAUDE.md`, rules, skills, settings) to an ASP.NET Core project with a SvelteKit or Blazor frontend.

New to Claude Code? Start with [Getting started](docs/getting-started.md): install, adding the kit to an existing project, teaching it your domain, and day-to-day habits.

## Prerequisites

- .NET 10 SDK or later. The C# language server from the `dotnet` plugin runs through `dotnet dnx`.
- The `agent-browser` CLI: `npm i -g agent-browser && agent-browser install`.
- For `--frontend svelte`: Node.js, for the Svelte CLI (`npx @sveltejs/mcp`).

## Install

From NuGet (once published):

```bash
dotnet new install DotnetAgentKit
```

From a local clone:

```bash
dotnet new install ./template
```

## Use

Run in your project root:

```bash
dotnet new agent-kit --frontend svelte
dotnet new agent-kit --frontend blazor
dotnet new agent-kit --help
```

| Option | Values | Default |
|---|---|---|
| `--frontend` | `svelte`, `blazor` | `svelte` |

When you first open the project in Claude Code, accept the folder trust prompt. Claude Code then registers the marketplaces below and offers to install the plugins.

## Included

Copied into the project's `.claude/` folder:

| Kind | Name | What it does |
|---|---|---|
| Rule | `git` | Never commit, push, or run destructive git commands unless asked; work on a branch, stage specific files; suggest a Conventional Commits message after each change |
| Rule | `ef-migrations` | Never edit applied migrations, review generated migrations, flag data-losing changes, no `database update` outside local, deploy via idempotent scripts or bundles |
| Skill | `conventional-commits` | Writes and reviews Conventional Commits 1.0.0 messages |
| Skill | `tdd` | Red-green loop for ASP.NET Core and EF Core with xUnit, `WebApplicationFactory`, and Testcontainers |
| Skill | `api-design` | HTTP contract design: resources, status codes, pagination, ProblemDetails, versioning, rate limiting |
| Skill | `dotnet-architecture` | Solution shape (feature slices, modular monolith), domain and data access defaults, cross-cutting concerns |
| Skill | `grilling`, `grill-me` | Interviews you about a plan until every decision is settled (`/grill-me`) |
| Skill | `domain-modeling` | Keeps domain terms in `GLOSSARY.md` and hard-to-reverse decisions as ADRs in `docs/adr/` |
| Skill | `grill-with-docs` | `/grill-with-docs`: grilling that records terms and decisions as it goes |
| Skill | `retro` | `/retro`: reviews a session and proposes improvements to `CLAUDE.md`, review rules, checks, and docs |
| Skill | `writing-for-agents` | Style guide for writing skills, agents, and `CLAUDE.md`; used by `retro` |
| Skill | `diagnosing-bugs` | Structured loop for hard bugs and performance regressions, with a human-in-the-loop script template |
| Skill | `handoff` | `/handoff`: summarizes the session into a document a fresh agent can continue from |
| Skill | `pr` | Writes PR bodies: visual summary, before/after evidence, merge danger (one-way door, blast radius) |
| Skill | `codebase-design` | Deep-module vocabulary (module, interface, seam, adapter, depth), deepening by dependency category, design-it-twice with parallel subagents |
| Skill | `improve-codebase-architecture` | `/improve-codebase-architecture`: finds deepening opportunities in hot spots, renders an HTML report, then grills through the one you pick |
| Skill | `postgresql` | PostgreSQL gotchas by area: indexing, JSONB, `EXPLAIN ANALYZE`, row-level security, full-text search, partitioning, pooling, extensions, replication, pgvector |
| Agent | `architect` | Read-only planning: affected areas, API contract, data model, test plan, steps, risks |
| Agent | `code-reviewer` | Reviews the diff for C#, EF Core, and frontend pitfalls, ranked by severity |
| Agent | `security-reviewer` | Reviews auth, input handling, secrets, and data exposure |
| Settings | `settings.json` | Disables commit/PR attribution, git permission guardrails, blocks `dotnet ef database drop` and `database update 0`, `.env` read block, plugins below |

`grilling`, `grill-me`, `domain-modeling`, `grill-with-docs`, `retro`, `writing-for-agents`, `diagnosing-bugs`, `handoff`, `pr`, `codebase-design`, and `improve-codebase-architecture` are from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT), shipped unchanged with their license. Part of `pr` comes from HumanLayer's `show-me` skill in [humanlayer/skills](https://github.com/humanlayer/skills) (MIT); its license is included as `LICENSE-humanlayer.txt`. The `tdd` skill's loop rules are adapted from the same repo. The `postgresql` skill's references are the vendor-neutral PostgreSQL references from [microsoft/postgres-skills](https://github.com/microsoft/postgres-skills) (MIT, commit `9ba96ab`), with their pointers to Azure-only references removed; its `SKILL.md` is ours. The Azure Database for PostgreSQL and Apache AGE skills and the `postgres-mcp` server are not included.

## Why each piece is there

Skills marked *auto* load when the agent sees a matching task; their one-line description costs a little context on every turn. Skills marked `/name` load only when you type the command, so they cost nothing until used.

### Planning and design

- **`architect`** (agent): plans a feature before code exists, grounded in the solution as it is: which projects change, the API contract, the EF data model and migration safety, a test plan, and risks. Catches "this needs a migration that drops data" before anyone writes it.
- **`dotnet-architecture`** (auto): opinionated .NET 10 defaults for *where code goes*: feature slices over layers, modular monolith before microservices, `DbContext` without generic repositories, no MediatR/AutoMapper by default, `AddValidation()`, `HybridCache`, `TimeProvider`, resilience handlers, OpenTelemetry. Keeps the agent from scaffolding Clean Architecture ceremony into a small API.
- **`codebase-design`** (auto): decides *what shape* a module's interface should have. Its "one adapter is a hypothetical seam, two is a real one" test stops `IOrderService`-per-`OrderService` and pass-through repositories; "the interface is the test surface" pushes tests through `WebApplicationFactory` or public handlers instead of mocks of your own code.
- **`api-design`** (auto): settles the HTTP contract first (routes, status codes, ProblemDetails, pagination, versioning, idempotency), so endpoints stay consistent across the API and with what the frontend expects.
- **`grilling`**, **`/grill-me`**: the agent interviews you about a plan until every branch is decided. Cheap insurance before a large change.
- **`domain-modeling`** (auto), **`/grill-with-docs`**: keep a `GLOSSARY.md` of domain terms and ADRs in `docs/adr/` for hard-to-reverse decisions. The agent reads them before touching an area, so it names things the way the business does and doesn't re-argue settled decisions.
- **`/improve-codebase-architecture`**: finds refactors worth doing in the files that change most, renders an HTML report with before/after diagrams, then walks through the one you pick. Useful on older solutions with thin layers, mapping plumbing, or controllers that grew to hundreds of lines.

### Building

- **`tdd`** (auto): red-green loop with xUnit, `WebApplicationFactory`, and Testcontainers against the real database engine, not the in-memory provider. Tests survive refactors because they assert behavior at a seam.
- **`ef-migrations`** (rule, always on): migrations are created with `dotnet ef`, reviewed after generation, never edited once applied, and data-losing changes are flagged with a safe add-backfill-remove sequence. `database update` stays local; deployments use idempotent scripts or bundles. `settings.json` denies `dotnet ef database drop` and `database update 0` outright, so those don't depend on the agent following the rule.
- **`postgresql`** (auto): short lists of what models get wrong about PostgreSQL, one area per file, loaded only for the area at hand: GIN doesn't help `->>` equality, `JSON_TABLE` needs PG 17, the table owner bypasses RLS unless it's forced, and so on. Useful when EF Core's defaults aren't enough and you need the right index, a JSONB column, or tenant isolation in the database.
- **`diagnosing-bugs`** (auto): a phased loop for hard bugs and performance regressions: build a fast, reliable repro first, then hypothesise and instrument. Stops the agent from guessing at fixes.

### Reviewing

- **`code-reviewer`** (agent, run after every code change per `CLAUDE.md`): .NET-specific review: blocking async, missing `CancellationToken`, DI lifetime bugs, N+1 and unbounded EF queries, broken module seams, abstractions without a need, plus frontend checks.
- **`security-reviewer`** (agent, run for security-sensitive changes): auth and ownership checks, tenant query filters, validation, SQL and path injection, secrets, CORS, and unsafe HTML output.

### Shipping

- **`git`** (rule, always on): the agent never commits, pushes, or runs destructive git commands unless asked, and works on a branch.
- **`conventional-commits`** (auto): commit messages and PR titles in Conventional Commits format, which makes changelogs and SemVer bumps mechanical.
- **`pr`** (auto): PR bodies with a visual summary, before/after evidence, and merge danger (one-way doors, blast radius), so reviewers know where to look.

### Sessions

- **`/handoff`**: condenses a long session into a document a fresh agent can continue from, instead of losing context.
- **`/retro`**: after a session, proposes concrete improvements to `CLAUDE.md`, review rules, and docs, so the same mistake isn't made twice.
- **`writing-for-agents`** (auto): the style guide used when editing skills, agents, or `CLAUDE.md`; `retro` relies on it.

## Day-to-day workflow

New to coding agents? Start with [Getting started](docs/getting-started.md): install, permission modes, steering, and writing a good request.

Match the ceremony to the size of the change. Most work is the first two cases; the rest are for when the stakes or the confusion are higher.

### How things get invoked

You type requests in plain language in the Claude Code prompt. The kit adds four kinds of help, and only two of them need you to do anything:

| Kind | How it runs | What you do |
|---|---|---|
| Rules (`git`, `ef-migrations`) | Always loaded | Nothing |
| Auto skills (`tdd`, `api-design`, `dotnet-architecture`, ...) | The agent loads one when your request matches it | Nothing; mention the skill by name if it didn't load ("use the tdd skill") |
| Slash commands (`/grill-me`, `/handoff`, `/retro`, ...) | Only when you type them | Type `/` and pick from the list |
| Agents (`architect`, `code-reviewer`, `security-reviewer`) | The agent may delegate on its own; the reviewers run after code changes because `CLAUDE.md` says so | To force one, type `@` and pick it, or write `@agent-architect` |

### Small change or obvious bug

Just ask. Per `CLAUDE.md`, the agent runs the `code-reviewer` agent on its changes before finishing. Per the `git` rule, it then suggests a commit message but doesn't commit unless you ask.

> Add a `CreatedAt` column to `Order` and return it from `GET /orders/{id}`.

The `ef-migrations` rule makes it create the migration with `dotnet ef`, read the generated `Up`/`Down`, and stop short of applying it anywhere but your local database.

### New feature

1. **Settle the plan.** `/grill-with-docs` for anything touching domain rules, `/grill-me` for purely technical plans. Stop when the answers stop surprising you.
   > /grill-with-docs We need partial refunds on orders. Customers can refund individual lines, up to 30 days after delivery.

   New terms (`Refund`, `RefundableLine`) land in `GLOSSARY.md`; a decision like "refunds are a separate aggregate, not a status on Order" lands in `docs/adr/`.
2. **Plan the change.**
   > @agent-architect plan partial refunds, based on the grilling above.

   Read the plan: affected slices, endpoints, the migration and whether it loses data, the test plan. Push back now; it is cheaper than after the code exists.
3. **Build test-first.**
   > Implement step 1 of the plan with TDD.

   `tdd` writes a failing `WebApplicationFactory` test against a Testcontainers database, then the code. `api-design` and `dotnet-architecture` load on their own when endpoints or structure come up.
4. **Review.** `code-reviewer` runs before the agent says it's done, and `security-reviewer` too here, since refunds touch money and ownership checks. Read the findings; Critical and High get fixed in the same session.
5. **Ship.** Ask for a commit message, then:
   > Write the PR description.

   `pr` produces a summary, evidence, and the merge danger (here: a new table, additive migration, low blast radius).

### Hard bug or slow endpoint

> Diagnose: `GET /orders` takes 4 seconds for customers with many orders.

`diagnosing-bugs` makes the agent build a reliable repro before touching code, then hypothesise and measure. Expect it to find an N+1 or a missing index, not to guess. `dotnet-diag` adds trace and dump collection when the cause is below EF.

### Long session, or switching context

> /handoff

Writes a document a fresh session can start from. Use it before the context fills up, at the end of the day mid-feature, or when handing work to a colleague.

### After a session that went wrong

> /retro

Use it when the agent repeated a mistake, ignored a convention, or you had to correct it more than once. It proposes concrete edits to `CLAUDE.md`, rules, or review checklists. Accept the ones that would have prevented the problem; this is how the kit gets better for your codebase.

### Older code that's hard to change

> /improve-codebase-architecture

Run it every few weeks or when a feature was painful to add. It looks at the files that change most, renders an HTML report of deepening opportunities (pass-through services, mapping plumbing, controllers doing everything), then grills you through the one you pick. Treat the result as a planned refactor, not a drive-by.

## Plugins

The generated `.claude/settings.json` enables these plugins. They install from their upstream marketplaces and stay up to date, so nothing third-party is copied into your project.

| Plugin | Frontend | Marketplace | What it adds | License |
|---|---|---|---|---|
| `dotnet` | all | [dotnet/skills](https://github.com/dotnet/skills) | C# language server (go to definition, references, diagnostics), C# refactoring, MSBuild guidance | MIT |
| `dotnet-aspnetcore` | all | [dotnet/skills](https://github.com/dotnet/skills) | Web API endpoints with correct HTTP semantics, OpenAPI metadata, and error handling | MIT |
| `dotnet-data` | all | [dotnet/skills](https://github.com/dotnet/skills) | EF Core query performance and correctness reviews, data-driven scaffolding | MIT |
| `frontend-design` | all | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | Guidance for distinctive, non-generic UI design | See the plugin |
| `dotnet-test` | all | [dotnet/skills](https://github.com/dotnet/skills) | Running, generating, and analyzing tests, coverage, and testability | MIT |
| `dotnet-diag` | all | [dotnet/skills](https://github.com/dotnet/skills) | Performance analysis, `dotnet-trace` and dump collection, microbenchmarking | MIT |
| `dotnet-msbuild` | all | [dotnet/skills](https://github.com/dotnet/skills) | Build failure diagnosis from binlogs, build performance, `Directory.Build.props` organization, MSBuild anti-patterns | MIT |
| `dotnet-nuget` | all | [dotnet/skills](https://github.com/dotnet/skills) | Converting a solution to Central Package Management | MIT |
| `docker-skills` | all | [docker/skills](https://github.com/docker/skills) | Dockerfile, build, and Docker Compose patterns, confirmation before destructive Docker operations (also ships Sandboxes and Docker Agent skills) | Apache-2.0 |
| `agent-browser` | all | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) | Lets the agent drive a real browser to check its own UI changes | Apache-2.0 |
| `svelte` | svelte | [sveltejs/ai-tools](https://github.com/sveltejs/ai-tools) | Svelte 5 best practices, docs lookup and `svelte-autofixer` (skills and MCP server), a `svelte-file-editor` subagent | MIT |
| `dotnet-blazor` | blazor | [dotnet/skills](https://github.com/dotnet/skills) | Blazor components, render modes, prerendering, auth, forms, JS interop | MIT |

To turn one off for yourself, set it to `false` in `.claude/settings.local.json`, for example `"enabledPlugins": { "agent-browser@agent-browser": false }`.

## Develop

After editing files under `template/`, reinstall and regenerate:

```bash
dotnet new uninstall ./template
dotnet new install ./template
dotnet new agent-kit --frontend svelte -o ./sandbox/svelte
dotnet new agent-kit --frontend blazor -o ./sandbox/blazor
```

Each frontend has its own settings file, `template/.claude/settings.<frontend>.json`, which is renamed to `.claude/settings.json` on generation. Shared parts (attribution, git permissions, the `dotnet*` plugins) are duplicated in each file, so change them in every file.

Pack:

```bash
dotnet pack -c Release
```

## License

MIT. The skills from mattpocock/skills and the references from microsoft/postgres-skills keep their own MIT license, shipped next to each `SKILL.md`.
