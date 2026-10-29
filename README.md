# dotnet-agent-kit

`dotnet new` template that adds AI coding agent config (Claude Code: `CLAUDE.md`, rules, skills, settings) to an ASP.NET Core project with SvelteKit, Blazor, or no frontend.

## Prerequisites

- .NET 10 SDK or later. The C# language server from the `dotnet` plugin runs through `dotnet dnx`.
- For `--frontend svelte` or `blazor`: the `agent-browser` CLI, `npm i -g agent-browser && agent-browser install`.
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
dotnet new agent-kit --frontend blazor --database sqlserver
dotnet new agent-kit --frontend none --database other
dotnet new agent-kit --help
```

| Option | Values | Default |
|---|---|---|
| `--frontend` | `svelte`, `blazor`, `none` (API only) | `svelte` |
| `--database` | `postgres`, `sqlserver`, `other` (no database-specific guidance) | `postgres` |

`--database` sets the EF Core provider and Testcontainers module named in `CLAUDE.md`, and ships the `postgresql` skill only for `postgres`.

When you first open the project in Claude Code, accept the folder trust prompt. Claude Code then registers the marketplaces below and offers to install the plugins.

## Add to an existing project

Generate the files with `dotnet new` rather than copying them from the template folder: `CLAUDE.md` contains `<!--#if -->` blocks and the `MyApp` placeholder that only `dotnet new` resolves.

If the project has no `CLAUDE.md` or `.claude/` folder yet, run it in the project root:

```bash
dotnet new agent-kit --frontend blazor --dry-run   # preview the files it creates
dotnet new agent-kit --frontend blazor             # MyApp becomes the folder name; -n Orders to choose
```

If files already exist, `dotnet new` lists the conflicts and stops. Don't pass `--force`: it overwrites your `CLAUDE.md` and settings. Generate into a temporary folder instead and merge:

```bash
dotnet new agent-kit --frontend blazor -n Orders -o ../kit-tmp
```

Copy these from `../kit-tmp` into the project root:

| Copy | Notes |
|---|---|
| `CLAUDE.md` | Merge by hand if the project already has one |
| `.claude/rules/` | `git.md`, `ef-migrations.md` |
| `.claude/skills/` | All folders, including their `LICENSE*.txt` files |
| `.claude/agents/` | `architect`, `code-reviewer`, `security-reviewer` |
| `.claude/settings.json` | Merge if one exists. Personal overrides go in `.claude/settings.local.json`, which stays out of git |

Commit this on a branch before Claude changes anything, so every later edit to `CLAUDE.md` shows up as a diff you can review. If a Claude Code session is already open in the project, exit it; `claude -c` starts a new one that loads the kit and continues the last conversation.

### Let Claude learn the project

Start `claude`, accept the trust prompt and plugins, then:

1. **Run `/init`.** It analyzes the codebase and, since `CLAUDE.md` exists, suggests improvements instead of overwriting it: real build and test commands, folder layout, conventions it finds. For an interactive version that asks follow-up questions and shows a proposal before writing, set `CLAUDE_CODE_NEW_INIT=1` before starting `claude`.
2. **Reconcile the kit with the codebase.** The kit's defaults are opinions; find where your project differs:
   > Compare `CLAUDE.md`, `.claude/rules/`, and the `dotnet-architecture` skill with how this codebase actually works. List every place they disagree (for example: we use controllers, MediatR, repositories, SQL Server not PostgreSQL). For each, propose whether to change `CLAUDE.md` to describe what we do, or keep the kit default as the direction for new code. Don't edit yet.

   Decide each point, then let it apply the edits.

### Teach it the domain

`/init` learns structure from code, but it guesses business meaning from names, and guesses are often wrong: an "account" becomes a user login when it's really the customer organization that is billed and that many users belong to. Wrong guesses written into `CLAUDE.md` mislead every later session, so correct them early.

In a fresh session, have it explain the product back to you first. Its mistakes show you what to teach:

```
I want you to learn this product's domain and business before we change anything.

First, explain the product to me as you understand it from the code and docs:
- Who uses it and what problem it solves for them
- The main concepts (for example account, order) and how they relate
- The main flows: what a user does, what happens with the data

For each concept and flow, tell me how confident you are and where it comes from (code, docs, or guessed from a name). Don't edit any files.
```

Then correct it, starting with the biggest mistake:

```
/grill-with-docs Correct your model of the domain, starting with "account". An account is not a user: it's the customer organization we bill; users belong to it. Ask me one question at a time, push on edge cases, and record each settled term in GLOSSARY.md.
```

- Answer edge-case questions concretely ("an account outlives its users; removing the last user doesn't close the account"). Those answers become the glossary entries and ADRs in `docs/adr/`.
- Wrong aliases go under `_Avoid_` in the glossary entry (`_Avoid_: User`), which stops the same mistake from coming back.
- Paste what you already have: product overview, PRDs, onboarding notes.
- One area per session (accounts and orders, then billing, ...). The glossary carries the knowledge into the next session, so `/clear` freely.

Finish by aligning the instructions with the glossary:

```
Update the CLAUDE.md files and rules to match GLOSSARY.md: fix contradictions, and replace domain definitions with a pointer to the glossary. Show me the diff first.
```

To stop new guesses, add this to the Conventions in `CLAUDE.md`: "Don't infer what a domain term means from its name or code. Check `GLOSSARY.md`; if a term is missing or unclear, ask me instead of guessing."

### Keep it accurate

- Keep `CLAUDE.md` under about 200 lines. Instructions for one area go in a nested `CLAUDE.md` (e.g. `web/CLAUDE.md`) or a rule with `paths:` frontmatter; both load only when files there are touched.
- After a session where you had to correct the agent, run `/retro` and accept the edits that would have prevented it.
- Review the first few `CLAUDE.md` edits closely; a wrong instruction there misleads every later session.

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
| Skill | `postgresql` | With `--database postgres`. PostgreSQL gotchas by area: indexing, JSONB, `EXPLAIN ANALYZE`, row-level security, full-text search, partitioning, pooling, extensions, replication, pgvector |
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
- **`postgresql`** (auto, `--database postgres` only): short lists of what models get wrong about PostgreSQL, one area per file, loaded only for the area at hand: GIN doesn't help `->>` equality, `JSON_TABLE` needs PG 17, the table owner bypasses RLS unless it's forced, and so on. Useful when EF Core's defaults aren't enough and you need the right index, a JSONB column, or tenant isolation in the database.
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
| `frontend-design` | svelte, blazor | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | Guidance for distinctive, non-generic UI design | See the plugin |
| `dotnet-test` | all | [dotnet/skills](https://github.com/dotnet/skills) | Running, generating, and analyzing tests, coverage, and testability | MIT |
| `dotnet-diag` | all | [dotnet/skills](https://github.com/dotnet/skills) | Performance analysis, `dotnet-trace` and dump collection, microbenchmarking | MIT |
| `dotnet-msbuild` | all | [dotnet/skills](https://github.com/dotnet/skills) | Build failure diagnosis from binlogs, build performance, `Directory.Build.props` organization, MSBuild anti-patterns | MIT |
| `dotnet-nuget` | all | [dotnet/skills](https://github.com/dotnet/skills) | Converting a solution to Central Package Management | MIT |
| `docker-skills` | all | [docker/skills](https://github.com/docker/skills) | Dockerfile, build, and Docker Compose patterns, confirmation before destructive Docker operations (also ships Sandboxes and Docker Agent skills) | Apache-2.0 |
| `agent-browser` | svelte, blazor | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) | Lets the agent drive a real browser to check its own UI changes | Apache-2.0 |
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
dotnet new agent-kit --frontend none -o ./sandbox/none
```

`template/.claude/settings.jsonc` is one file for every `--frontend` value, generated as `.claude/settings.json`. Frontend-only marketplaces and plugins sit in `//#if (isSvelte)`, `//#if (isBlazor)`, or `//#if (!isNone)` blocks, which `dotnet new` resolves and removes; the `.jsonc` extension keeps editors from flagging those lines. Keep conditional entries above the shared ones in each object, so every entry inside a block ends with a comma and the output stays valid JSON.

Pack:

```bash
dotnet pack -c Release
```

## License

MIT. The skills from mattpocock/skills and the references from microsoft/postgres-skills keep their own MIT license, shipped next to each `SKILL.md`.
