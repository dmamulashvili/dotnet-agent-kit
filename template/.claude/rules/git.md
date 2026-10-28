## Git rules

- Never commit, merge, rebase, or push unless I explicitly ask in this conversation.
- Never run destructive commands: `git reset --hard`, `git push --force`,
  `git clean -fd`, `git checkout -- .`, `git branch -D`. If one seems necessary,
  explain why and ask first.
- Never amend or rebase commits that are already pushed.
- Never skip hooks (`--no-verify`). If a hook fails, fix the cause or ask me.
- Never commit directly to `main`. Work on a branch named `<type>/<short-name>`.
- Stage specific files, not `git add -A` or `git add .`.
- Never commit secrets or local config (`.env`, credentials, keys).
- Commit messages follow Conventional Commits (see the conventional-commits skill).
- After finishing a change, suggest a commit message for it; don't commit.
- Before committing, show me `git status` and the proposed message.