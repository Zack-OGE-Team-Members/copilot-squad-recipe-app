# Project Context

- **Owner:** Zack Way
- **Project:** RecipeHub / copilot-squad-recipe-app
- **Description:** Full-stack recipe management app for the GitHub Copilot & Squad Developer Workflow Hackathon.
- **Stack:** .NET Aspire 13.2, .NET 10 Minimal API, EF Core 10, SQLite, React 19, TypeScript, Vite 6, TanStack Query v5, xUnit, Vitest.
- **Created:** 2026-05-28T13:01:15.437-04:00

## Learnings

Initial team setup complete. Dinesh owns React, TypeScript, Vite, TanStack Query, frontend tests, and client-facing behavior.

- Implemented full Favorites feature (Challenge 02): types, apiClient methods, `favoriteKeys`, `useFavorites`/`useAddFavorite`/`useRemoveFavorite` hooks, FavoritesPage list UI, and toggle button on RecipeDetailPage. All wired through existing barrel exports.
- `api/index.ts` uses `export * from './types'` so new types are automatically re-exported — no manual addition needed.
- TanStack Query `useMutation.variables` tracks the in-flight argument, enabling per-item loading state on list pages (e.g. FavoritesPage remove button).

**Completion note (2026-05-28T13:47:19.889-04:00):** Favorites feature fully validated. npm build clean (0 errors, 134 modules). Decision merged to `.squad/decisions.md`. Session log written.

## Learnings

### 2026-05-28: Dark Mode — Late Night Kitchen Theme
- CSS custom property token system established in index.css
- All color values in all 16 CSS files now use var() references — no hardcoded hex colors
- color-scheme: light dark restored safely (dark mode backed by full CSS custom properties)
- Dark mode palette: espresso bg (#1a0d08), cream text (#f5e6d3), saffron accent (#e07c2e)
- WCAG AA confirmed in both modes
- Pattern: always use CSS custom properties for colors; never hardcode hex in component CSS
