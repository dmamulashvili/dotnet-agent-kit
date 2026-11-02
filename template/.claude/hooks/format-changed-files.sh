#!/usr/bin/env bash
# Stop hook: runs dotnet format on the .cs files changed since the last commit (plus new
# untracked ones) once Claude finishes a response. Formatting per edit would cost about a
# second each time; once per response keeps that cost off every edit.
#
# DOTNET_FORMAT_ON_STOP, set in the "env" block of .claude/settings.json:
#   whitespace (default)  spacing and indentation only; doesn't load the project
#   full                  whitespace, code style, and analyzers; loads the solution
#   off                   disabled
# DOTNET_FORMAT_WORKSPACE: solution or project for "full", relative to the repo root.
# Without it, "full" uses the only .sln, .slnx, or .csproj in the repo root, and falls
# back to whitespace if there isn't exactly one.
#
# Always exits 0: exit 2 on a Stop hook would make Claude continue instead of stopping.

cat > /dev/null   # the Stop input isn't needed

mode=${DOTNET_FORMAT_ON_STOP:-whitespace}
case "$mode" in
  whitespace|full) ;;
  *) exit 0 ;;
esac

root=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
command -v dotnet > /dev/null 2>&1 || exit 0

# Changed and new .cs files, relative to the repo root. EF Core migrations and generated
# files are left as the tools wrote them.
files=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in
    Migrations/*|*/Migrations/*|*.Designer.cs|*.g.cs|*.generated.cs) continue ;;
  esac
  files+=("$f")
done < <(
  { git diff --name-only --diff-filter=ACMR HEAD -- '*.cs' 2>/dev/null || git diff --name-only --cached -- '*.cs'
    git ls-files --others --exclude-standard -- '*.cs'
  } | sort -u
)
[ ${#files[@]} -eq 0 ] && exit 0

if [ "$mode" = full ]; then
  workspace=${DOTNET_FORMAT_WORKSPACE:-}
  if [ -z "$workspace" ]; then
    candidates=()
    for c in *.slnx *.sln; do [ -f "$c" ] && candidates+=("$c"); done
    if [ ${#candidates[@]} -eq 0 ]; then
      for c in *.csproj; do [ -f "$c" ] && candidates+=("$c"); done
    fi
    [ ${#candidates[@]} -eq 1 ] && workspace=${candidates[0]}
  fi
  if [ -n "$workspace" ] && [ -f "$workspace" ]; then
    dotnet format "$workspace" --include "${files[@]}" > /dev/null 2>&1 \
      && { echo "dotnet format (full): ${#files[@]} file(s)"; exit 0; }
  fi
  # No single workspace, or the full run failed: whitespace still helps.
fi

dotnet format whitespace . --folder --include "${files[@]}" > /dev/null 2>&1 \
  && echo "dotnet format (whitespace): ${#files[@]} file(s)"
exit 0
