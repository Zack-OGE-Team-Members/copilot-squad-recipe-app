# Squad Decisions

## Active Decisions

### 2026-05-28T13:01:15.437-04:00: Initial Squad roster and casting
**By:** Zack Way (via Copilot)
**What:** Hire a Silicon Valley-cast Squad for RecipeHub with Monica as Lead, Dinesh as Frontend Dev, Gilfoyle as Backend Dev, Jared as Tester, Richard as Platform Dev, plus Scribe and Ralph.
**Why:** User requested the team for this repo and specified the Silicon Valley universe for agent names.

### 2026-05-28T13:47:19.889-04:00: Favorites Backend Implementation (Gilfoyle)
**By:** Gilfoyle (Backend Dev)
**What:** Hardcoded `UserId` to `"guest"` in FavoriteEndpoints; no new migration required (Favorites table already in InitialCreate).
**Why:** App has no auth layer in scope. Swapping to real user identity in future is a one-line change. Unique index on `(UserId, RecipeId)` already enforced at DB level.

### 2026-05-28T13:47:19.889-04:00: Favorites Frontend Implementation (Dinesh)
**By:** Dinesh (Frontend Dev)
**What:** Full frontend implementation: types, apiClient methods, hooks (useFavorites, useAddFavorite, useRemoveFavorite), FavoritesPage list UI, RecipeDetailPage toggle button. 8 files touched.
**Why:** Completed Challenge 02 requirements. No auth plumbing needed (backend uses "guest"). Per-item loading state via `mutation.variables`. Favorite toggle on detail page derives state from cached list (no separate lookup endpoint).

### 2026-05-28T13:47:19.889-04:00: Favorites Integration Test Structure (Jared)
**By:** Jared (Tester)
**What:** 9 integration tests split into 4 classes (FavoriteEmptyTests, FavoritePostTests, FavoriteGetAfterAddTests, FavoriteDeleteTests), each with its own `IClassFixture<RecipeApiFactory>` for DB isolation. Recipe IDs from seed data.
**Why:** Isolation prevents cross-test 409 conflicts. DTO contracts added to src/RecipeHub.Api/Dtos early for Gilfoyle to implement against. All 9 tests live (fail-on-red until endpoints exist).

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
