#!/usr/bin/env bash
python3 -c '
import json
import os
import re
import sys
from pathlib import Path

raw_input = sys.stdin.read()
if not raw_input.strip():
    raise SystemExit(0)

try:
    payload = json.loads(raw_input)
except Exception:
    raise SystemExit(0)

cwd = payload.get("cwd")
if not isinstance(cwd, str) or not cwd.strip():
    raise SystemExit(0)

try:
    repo_root = Path(cwd).resolve()
except Exception:
    raise SystemExit(0)


def iter_strings(value):
    if value is None:
        return
    if isinstance(value, str):
        yield value
        return
    if isinstance(value, dict):
        for item in value.values():
            yield from iter_strings(item)
        return
    if isinstance(value, (list, tuple, set)):
        for item in value:
            yield from iter_strings(item)


def is_path_like(candidate: str) -> bool:
    if not candidate.strip():
        return False
    if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*://", candidate):
        return False
    return "/" in candidate or "\\" in candidate or os.path.isabs(candidate) or bool(re.match(r"^[A-Za-z]:[\\/]", candidate))


def resolve_candidate(candidate: str):
    if re.match(r"^[A-Za-z]:[\\/]", candidate) or candidate.startswith("\\\\"):
        return candidate, False

    candidate_path = Path(candidate.replace("\\", os.sep))
    resolved = candidate_path.resolve() if candidate_path.is_absolute() else (repo_root / candidate_path).resolve()
    is_inside = resolved == repo_root or repo_root in resolved.parents
    return str(resolved), is_inside


violations = []
for candidate in iter_strings(payload.get("tool_input")):
    if not is_path_like(candidate):
        continue

    try:
        resolved_path, is_inside_repo = resolve_candidate(candidate)
    except Exception:
        continue

    if not is_inside_repo:
        violations.append(f"\'{candidate}\' -> \"{resolved_path}\"")

if violations:
    print(json.dumps({
        "permissionDecision": "deny",
        "permissionDecisionReason": f"Path guard denied tool use because these paths resolve outside the repository root \"{repo_root}\": {'; '.join(violations)}"
    }))
'