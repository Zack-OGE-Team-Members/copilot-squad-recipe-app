using Microsoft.EntityFrameworkCore;
using RecipeHub.Api.Data;
using RecipeHub.Api.Dtos;
using RecipeHub.Api.Models;

namespace RecipeHub.Api.Endpoints;

public static class FavoriteEndpoints
{
    private const string GuestUserId = "guest";

    public static void MapFavoriteEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/favorites").WithTags("Favorites");

        group.MapGet("/", GetAllAsync);
        group.MapPost("/", AddAsync);
        group.MapDelete("/{recipeId:int}", DeleteAsync);
    }

    private static async Task<IResult> GetAllAsync(RecipeDbContext db, CancellationToken ct)
    {
        var favorites = await db.Favorites
            .AsNoTracking()
            .Where(f => f.UserId == GuestUserId)
            .Include(f => f.Recipe)
                .ThenInclude(r => r!.RecipeTags)
                    .ThenInclude(rt => rt.Tag)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync(ct);

        return Results.Ok(favorites.Select(ToDto).ToArray());
    }

    private static async Task<IResult> AddAsync(
        AddFavoriteRequest req,
        RecipeDbContext db,
        CancellationToken ct)
    {
        var recipeExists = await db.Recipes.AnyAsync(r => r.Id == req.RecipeId, ct);
        if (!recipeExists)
            return Results.NotFound();

        var alreadyFavorited = await db.Favorites
            .AnyAsync(f => f.UserId == GuestUserId && f.RecipeId == req.RecipeId, ct);
        if (alreadyFavorited)
            return Results.Conflict();

        var favorite = new Favorite
        {
            UserId = GuestUserId,
            RecipeId = req.RecipeId,
            CreatedAt = DateTime.UtcNow
        };

        db.Favorites.Add(favorite);
        await db.SaveChangesAsync(ct);

        await db.Entry(favorite)
            .Reference(f => f.Recipe)
            .Query()
            .Include(r => r.RecipeTags)
                .ThenInclude(rt => rt.Tag)
            .LoadAsync(ct);

        return Results.Created($"/api/favorites/{favorite.Id}", ToDto(favorite));
    }

    private static async Task<IResult> DeleteAsync(int recipeId, RecipeDbContext db, CancellationToken ct)
    {
        var favorite = await db.Favorites
            .FirstOrDefaultAsync(f => f.UserId == GuestUserId && f.RecipeId == recipeId, ct);

        if (favorite is null)
            return Results.NotFound();

        db.Favorites.Remove(favorite);
        await db.SaveChangesAsync(ct);
        return Results.NoContent();
    }

    private static FavoriteDto ToDto(Favorite f) =>
        new(f.Id, f.RecipeId, f.CreatedAt, RecipeEndpoints.ToDto(f.Recipe!));
}
