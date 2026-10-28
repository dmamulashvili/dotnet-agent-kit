# Getting started with Claude Code

For .NET developers who haven't used a coding agent before, working in a project set up with `dotnet new agent-kit`. Read this once, then use the [day-to-day workflow](../README.md#day-to-day-workflow) in the README.

## What changes when you work with an agent

Claude Code is not autocomplete. You describe a task in plain language; it reads the code, edits files, runs commands (`dotnet build`, `dotnet test`, `git diff`), looks at the results, and keeps going until the task is done or it needs you.

Your job shifts from typing code to three things:

1. **Saying precisely what you want**, including what "done" means.
2. **Steering** when it heads the wrong way.
3. **Reviewing** what it produced. You own every line that gets merged, exactly as if you wrote it.

## Install and start

Install the CLI (pick one):

```powershell
# Windows PowerShell
irm https://claude.ai/install.ps1 | iex

# or WinGet (doesn't auto-update; run `winget upgrade Anthropic.ClaudeCode` now and then)
winget install Anthropic.ClaudeCode
```

```bash
# macOS, Linux, WSL
curl -fsSL https://claude.ai/install.sh | bash
```

On Windows, install [Git for Windows](https://git-scm.com/downloads/win) too, so Claude Code can use Bash.

Open a new terminal, check `claude --version`, then start it in the project root:

```bash
cd path/to/your/project
claude
```

The first run asks you to log in through the browser. Claude Code also runs inside [JetBrains IDEs](https://code.claude.com/docs/en/jetbrains) (including Rider), [VS Code](https://code.claude.com/docs/en/vs-code), and a desktop app if you prefer not to live in a terminal.

The first time you open a project made with this kit, accept the folder trust prompt. Claude Code then offers to install the plugins listed in the README; accept them.

## Adding the kit to an existing project

Generate the files with `dotnet new` rather than copying them from the template folder: `CLAUDE.md` contains `<!--#if -->` blocks and the `MyApp` placeholder that only `dotnet new` resolves.

```bash
dotnet new agent-kit --frontend blazor -n Orders -o ../kit-tmp   # -n replaces "MyApp"
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
3. **Teach it what the code can't show:** business terms, past decisions, the reasons behind odd code.
   > /grill-with-docs Interview me about this domain and its key decisions.

   This builds `GLOSSARY.md` and ADRs in `docs/adr/`, which `CLAUDE.md` tells the agent to read.

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

- Answer edge-case questions concretely ("an account outlives its users; removing the last user doesn't close the account"). Those answers become the glossary entries and ADRs.
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

## Permission modes: how much it does without asking

Press `Shift+Tab` to cycle modes.

| Mode | What it does without asking | Use it when |
|---|---|---|
| Manual (`default`) | Only reads files | Your first week, or sensitive work. You approve every edit and command |
| `acceptEdits` | Reads and edits files | You trust the plan and want to review the diff at the end |
| `plan` | Reads and explores, edits nothing | You want a plan before any code changes. Also `/plan <prompt>` for one prompt |
| `auto` | Everything, with a safety classifier checking risky actions | Longer tasks once you're comfortable |

Start in Manual or plan mode until you've seen how it works. Whatever the mode, the kit's deny rules still apply: no force pushes, no `git reset --hard`, no `dotnet ef database drop`, no reading `.env`.

## Your first hour

Try these in order, in your own project:

1. **Ask questions.** Nothing changes; you learn how it explores.
   > How does an order get created, from the HTTP request to the database?

   > Which endpoints don't require authorization?
2. **Plan without editing.** Switch to plan mode (`Shift+Tab`), then:
   > Plan how to add a `Notes` field to orders, editable through the API.

   Read the plan. Disagree with something and say so; watch it adjust.
3. **Make a small change.** Approve the plan, or switch to Manual and ask for it. Approve each edit and command as it comes, reading what it asks to do.
4. **Review the result.** Look at the diff in Rider or with `git diff`. Read the generated migration. Run the tests yourself. The agent also runs the `code-reviewer` agent before finishing and shows you its findings.
5. **Commit.** It suggests a commit message; you commit, or ask it to.

## Steering

- **`Esc`** stops it mid-action and keeps everything so far. Use it the moment it drifts: wrong file, wrong approach, a test it's "fixing" by weakening the assertion.
- **`Esc` twice on an empty prompt** (or `/rewind`) rolls the code, the conversation, or both back to an earlier prompt. Trying a bolder approach is cheap because you can undo it.
- **`/clear`** starts a fresh conversation. Do it between unrelated tasks, and after correcting the same thing twice without success: start over with one better prompt rather than a third correction.
- **`Ctrl+C`** interrupts; pressed twice on an empty prompt, it exits.
- **`claude -c`** continues the most recent conversation in this folder; `/resume` picks an older one.

## Writing a good request

Vague requests get plausible code for a problem you don't have. Say what, where, and how you'll know it works.

| Instead of | Write |
|---|---|
| "fix the orders bug" | "`GET /orders/{id}` returns 500 when the order has no customer. It should return the order with `customer: null`. Add a test that reproduces it first." |
| "add caching" | "Cache `GET /products` for 5 minutes with `HybridCache`. Invalidate on product create and update. Show me the test that proves invalidation works." |
| "make it faster" | "`GET /orders?customerId=` takes 4s for customers with 2k orders. Find out why before changing anything." |

Also useful:
- Point at files or examples: "follow the pattern in `Features/Orders/CreateOrder.cs`". Type `@` to reference a file.
- Give it a check to run: a failing test, a curl command, an expected response.
- Break big work into steps, or ask for a plan first.

## What the kit adds

The kit adds rules, skills, agents, and plugins on top of plain Claude Code. Most of it works without you doing anything; see [How things get invoked](../README.md#how-things-get-invoked) for the four kinds and [Why each piece is there](../README.md#why-each-piece-is-there) for what each one does. Type `/` in the prompt to see the commands available.

## Habits worth keeping

- **Review like it's a colleague's PR.** It writes confident code that compiles and is sometimes wrong. Check the logic, not just that tests pass, and check that tests test something.
- **Read every migration** before applying it, even locally. The `ef-migrations` rule makes the agent flag data loss, but you approve it.
- **One task per conversation.** Long, mixed conversations make it slower and less accurate. `/clear` is free.
- **Don't paste secrets** into the prompt. Use user-secrets; the kit blocks reading `.env` files.
- **When it keeps making the same mistake, fix the instructions, not just the code.** Run `/retro` and accept the change to `CLAUDE.md` or a rule, so the next session (and your teammates') doesn't repeat it.
- **Before stopping mid-feature**, run `/handoff` so tomorrow's session starts with context instead of from zero.

## More

- [Claude Code quickstart](https://code.claude.com/docs/en/quickstart)
- [Best practices](https://code.claude.com/docs/en/best-practices)
- [Permission modes](https://code.claude.com/docs/en/permission-modes)
- [Claude Code 101](https://academy.claude.com/courses/claude-code-101), a free self-paced course
