# MyApp

## Stack
- Backend: ASP.NET Core Web API (.NET 10), EF Core.
<!--#if (isPostgres) -->
- Database: PostgreSQL via `Npgsql.EntityFrameworkCore.PostgreSQL`; integration tests use `Testcontainers.PostgreSql`.
<!--#elseif (isSqlServer) -->
- Database: SQL Server via `Microsoft.EntityFrameworkCore.SqlServer`; integration tests use `Testcontainers.MsSql`.
<!--#endif -->
<!--#if (isSvelte) -->
- Frontend: SvelteKit with Svelte 5 runes, in `/web`.
<!--#elseif (isBlazor) -->
- Frontend: Blazor Web App.
<!--#elseif (isNone) -->
- Frontend: none; this is an API-only project.
<!--#endif -->

## Commands
- Build: `dotnet build`
- Test: `dotnet test`
<!--#if (isSvelte) -->
- Frontend dev server: `cd web && npm run dev`
- Frontend check: `cd web && npm run check`
<!--#elseif (isBlazor) -->
- Frontend dev server: `dotnet watch` in the Blazor project
<!--#endif -->

## Docs
- Domain terms: `GLOSSARY.md`. Decisions: `docs/adr/`. Read the relevant entries before changing an area; both are maintained with the `domain-modeling` skill.

## Conventions
- Keep endpoints thin; put logic in handlers, services, or entities (see the `dotnet-architecture` skill).
- Use async all the way; pass `CancellationToken` through.
<!--#if (isSvelte) -->
- Svelte: use `$state`, `$derived`, `$props`. Never use `export let` or `$:`.
- For any `.svelte` / `.svelte.ts` file, follow the `svelte-core-bestpractices` skill and run `svelte-autofixer` from the `svelte-code-writer` skill; fix every issue it reports.
<!--#elseif (isBlazor) -->
- Blazor: set an interactive render mode only on components that need interactivity; keep components small and move logic into injected services.
<!--#endif -->
<!--#if (!isNone) -->
- After UI changes, start the dev server and verify the page with the `agent-browser` skill before finishing.
<!--#endif -->
- After code changes, run the `code-reviewer` agent before finishing; also run `security-reviewer` when the change touches auth, input handling, data access, secrets, or external calls. Fix Critical and High findings.
