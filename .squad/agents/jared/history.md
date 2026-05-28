# Project Context

- **Owner:** Zack Way
- **Project:** RecipeHub / copilot-squad-recipe-app
- **Description:** Full-stack recipe management app for the GitHub Copilot & Squad Developer Workflow Hackathon.
- **Stack:** .NET Aspire 13.2, .NET 10 Minimal API, EF Core 10, SQLite, React 19, TypeScript, Vite 6, TanStack Query v5, xUnit, Vitest.
- **Created:** 2026-05-28T13:01:15.437-04:00

## Learnings

Initial team setup complete. Jared owns xUnit, Vitest, regression coverage, edge cases, and quality review.

- **2026-05-28** — Created `tests/RecipeHub.Api.Tests/FavoriteEndpointsTests.cs` with 9 integration tests covering the Favorites API (GET, POST, DELETE). Split into 4 test classes (`FavoriteEmptyTests`, `FavoritePostTests`, `FavoriteGetAfterAddTests`, `FavoriteDeleteTests`), each with its own `IClassFixture<RecipeApiFactory>`, to ensure DB isolation between logical groups. Within each class, tests use distinct recipe IDs (from the 12 seeded recipes) to avoid cross-test 409 conflicts. Also added `src/RecipeHub.Api/Dtos/FavoriteDto.cs` with `FavoriteDto` and `AddFavoriteRequest` records so the tests compile ahead of Gilfoyle's endpoint implementation. Build: `dotnet build tests/RecipeHub.Api.Tests/RecipeHub.Api.Tests.csproj` — succeeded with only pre-existing vulnerability warnings.

**Completion note (2026-05-28T13:47:19.889-04:00):** Favorites feature fully validated. All 9 integration tests pass. Decision merged to `.squad/decisions.md`. Session log written.
