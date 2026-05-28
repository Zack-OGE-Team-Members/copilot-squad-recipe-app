# Project Context

- **Owner:** Zack Way
- **Project:** RecipeHub / copilot-squad-recipe-app
- **Description:** Full-stack recipe management app for the GitHub Copilot & Squad Developer Workflow Hackathon.
- **Stack:** .NET Aspire 13.2, .NET 10 Minimal API, EF Core 10, SQLite, React 19, TypeScript, Vite 6, TanStack Query v5, xUnit, Vitest.
- **Created:** 2026-05-28T13:01:15.437-04:00

## Learnings

Initial team setup complete. Gilfoyle owns Minimal API endpoints, EF Core persistence, SQLite behavior, DTOs, and backend contracts.

### 2026-05-28 — Favorites backend implementation

Implemented the full favorites feature backend (Challenge 02):
- Created `FavoriteDto` and `AddFavoriteRequest` records in `Dtos/FavoriteDto.cs`.
- Replaced all 501 stubs in `FavoriteEndpoints.cs` with real EF Core logic.
- GET /api/favorites: queries by `UserId == "guest"`, includes `Recipe → RecipeTags → Tag`, orders by `CreatedAt` descending.
- POST /api/favorites: validates recipe exists (404), checks duplicate (409), saves, eager-loads tags, returns 201 Created.
- DELETE /api/favorites/{recipeId}: finds by `UserId + RecipeId`, returns 404 if missing, else removes and returns 204.
- No new migration was needed — `Favorites` table already existed from `InitialCreate`.
- `UserId` is hardcoded to `"guest"` (no auth in scope).

**Completion note (2026-05-28T13:47:19.889-04:00):** Favorites feature fully validated. All 9 integration tests pass. Decision merged to `.squad/decisions.md`. Session log written.
