# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Scope, architecture & priorities | Monica | Plan features, resolve trade-offs, review designs, triage broad issues |
| Frontend UI & client state | Dinesh | React pages, components, routes, TanStack Query hooks, Vite build issues |
| Backend API & persistence | Gilfoyle | Minimal API endpoints, EF Core models/migrations, SQLite behavior, API contracts |
| Testing & quality | Jared | xUnit integration tests, Vitest tests, edge cases, regression coverage |
| Aspire, platform & dev workflow | Richard | AppHost orchestration, service defaults, local startup, Codespaces/devcontainer readiness |
| Code review | Monica | Review PRs, check quality, suggest improvements |
| Testing | Jared | Write tests, find edge cases, verify fixes |
| Scope & priorities | Monica | What to build next, trade-offs, decisions |
| Session logging | Scribe | Automatic — never needs routing |
| Work monitoring | Ralph | Backlog scans, issue pickup, keep-alive checks |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Lead |
| `squad:monica` | Pick up lead, architecture, and review work | Monica |
| `squad:dinesh` | Pick up frontend work | Dinesh |
| `squad:gilfoyle` | Pick up backend work | Gilfoyle |
| `squad:jared` | Pick up testing work | Jared |
| `squad:richard` | Pick up platform and Aspire work | Richard |
| `squad:{name}` | Pick up issue and complete the work | Named member |

### How Issue Assignment Works

1. When a GitHub issue gets the `squad` label, the **Lead** triages it — analyzing content, assigning the right `squad:{member}` label, and commenting with triage notes.
2. When a `squad:{member}` label is applied, that member picks up the issue in their next session.
3. Members can reassign by removing their label and adding another member's label.
4. The `squad` label is the "inbox" — untriaged issues waiting for Lead review.

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn an agent for "what port does the server run on?"
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** If a feature is being built, spawn the tester to write test cases from requirements simultaneously.
7. **Issue-labeled work** — when a `squad:{member}` label is applied to an issue, route to that member. The Lead handles all `squad` (base label) triage.
