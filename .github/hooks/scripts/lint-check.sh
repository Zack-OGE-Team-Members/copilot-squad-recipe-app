#!/usr/bin/env bash
set -u

payload="$(cat || true)"
if [[ -z "${payload//[[:space:]]/}" ]]; then
    exit 0
fi

cwd="$(printf '%s' "$payload" | python3 -c 'import json, sys
raw = sys.stdin.read()
if not raw.strip():
    raise SystemExit(0)
try:
    payload = json.loads(raw)
except Exception:
    raise SystemExit(0)
cwd = payload.get("cwd")
if isinstance(cwd, str) and cwd.strip():
    sys.stdout.write(cwd)
')"

if [[ -z "${cwd//[[:space:]]/}" || ! -d "$cwd" ]]; then
    exit 0
fi

cd "$cwd" || exit 0

declare -a issues

trim_output() {
    printf '%s' "$1" | python3 -c 'import sys
lines = [line for line in sys.stdin.read().splitlines() if line.strip()]
if not lines:
    print("No output captured.")
else:
    print("\n".join(lines[:20]))
'
}

add_issue() {
    issues+=("$1"$'\x1f'"$2"$'\x1f'"$3")
}

run_check() {
    local executable="$1"
    local title="$2"
    local fix="$3"
    shift 3

    if ! command -v "$executable" >/dev/null 2>&1; then
        return
    fi

    local output
    output="$("$@" 2>&1)"
    local status=$?

    if [[ $status -ne 0 ]]; then
        add_issue "$title" "$fix" "$(trim_output "$output")"
    fi
}

run_check dotnet 'dotnet format' 'Run `dotnet format` from the repo root to apply required formatting and analyzer fixes, then re-run the checks.' dotnet format --verify-no-changes
run_check npx 'ESLint' 'Run `npx eslint "src/RecipeHub.Web/src" --ext .ts,.tsx --max-warnings 0 --fix` from the repo root, then resolve any remaining lint errors.' npx eslint 'src/RecipeHub.Web/src' --ext .ts,.tsx --max-warnings 0
run_check npx 'Prettier' 'Run `npx prettier --write src/RecipeHub.Web/src` from the repo root to apply formatting, then re-run the checks.' npx prettier --check 'src/RecipeHub.Web/src'

if (( ${#issues[@]} > 0 )); then
    reason=$'🚫 Lint/format check failed. Fix these issues before proceeding:\n'
    index=1

    for issue in "${issues[@]}"; do
        IFS=$'\x1f' read -r title fix output <<< "$issue"
        reason+=$'\n'
        reason+="$index. $title: $fix"$'\n'
        while IFS= read -r line; do
            reason+="   $line"$'\n'
        done <<< "$output"
        reason+=$'\n'
        (( index++ ))
    done

    python3 -c "import json, sys
reason = sys.argv[1]
print(json.dumps({'decision': 'block', 'reason': reason.rstrip()}))" "$reason"
fi