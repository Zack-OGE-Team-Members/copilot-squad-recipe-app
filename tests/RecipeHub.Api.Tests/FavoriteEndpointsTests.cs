using System.Net;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using RecipeHub.Api.Dtos;
using Xunit;

namespace RecipeHub.Api.Tests;

/// <summary>
/// Integration tests for GET /api/favorites with an empty database.
/// Uses an isolated factory to guarantee no favorites exist.
/// </summary>
public class FavoriteEmptyTests : IClassFixture<RecipeApiFactory>
{
    private readonly RecipeApiFactory _factory;

    public FavoriteEmptyTests(RecipeApiFactory factory) => _factory = factory;

    [Fact]
    public async Task GetFavorites_WhenEmpty_ReturnsEmptyArray()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/favorites");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var favorites = await response.Content.ReadFromJsonAsync<FavoriteDto[]>();
        Assert.NotNull(favorites);
        Assert.Empty(favorites!);
    }
}

/// <summary>
/// Integration tests for POST /api/favorites.
/// Each test uses a distinct recipe ID (1–3) to avoid cross-test 409 conflicts.
/// </summary>
public class FavoritePostTests : IClassFixture<RecipeApiFactory>
{
    private readonly RecipeApiFactory _factory;

    public FavoritePostTests(RecipeApiFactory factory) => _factory = factory;

    [Fact]
    public async Task PostFavorite_ValidRecipeId_Returns201WithDto()
    {
        var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/favorites", new AddFavoriteRequest(1));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var dto = await response.Content.ReadFromJsonAsync<FavoriteDto>();
        Assert.NotNull(dto);
        Assert.Equal(1, dto!.RecipeId);
        Assert.True(dto.Id > 0);
        Assert.NotNull(dto.Recipe);
    }

    [Fact]
    public async Task PostFavorite_AlreadyFavorited_Returns409()
    {
        var client = _factory.CreateClient();

        var first = await client.PostAsJsonAsync("/api/favorites", new AddFavoriteRequest(2));
        Assert.Equal(HttpStatusCode.Created, first.StatusCode);

        var second = await client.PostAsJsonAsync("/api/favorites", new AddFavoriteRequest(2));
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task PostFavorite_InvalidRecipeId_Returns404()
    {
        var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/favorites", new AddFavoriteRequest(99999));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task PostFavorite_PersistsToDatabase()
    {
        var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/favorites", new AddFavoriteRequest(3));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var dto = await response.Content.ReadFromJsonAsync<FavoriteDto>();
        Assert.NotNull(dto);

        await using var db = _factory.CreateDbContext();
        var saved = await db.Favorites
            .AsNoTracking()
            .FirstOrDefaultAsync(f => f.RecipeId == 3);

        Assert.NotNull(saved);
        Assert.Equal("guest", saved!.UserId);
        Assert.Equal(dto!.Id, saved.Id);
    }
}

/// <summary>
/// Integration tests for GET /api/favorites after adding a favorite.
/// </summary>
public class FavoriteGetAfterAddTests : IClassFixture<RecipeApiFactory>
{
    private readonly RecipeApiFactory _factory;

    public FavoriteGetAfterAddTests(RecipeApiFactory factory) => _factory = factory;

    [Fact]
    public async Task GetFavorites_AfterAdd_ReturnsOneItem()
    {
        var client = _factory.CreateClient();

        var post = await client.PostAsJsonAsync("/api/favorites", new AddFavoriteRequest(1));
        Assert.Equal(HttpStatusCode.Created, post.StatusCode);

        var response = await client.GetAsync("/api/favorites");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var favorites = await response.Content.ReadFromJsonAsync<FavoriteDto[]>();
        Assert.NotNull(favorites);
        Assert.Single(favorites!);
        Assert.Equal(1, favorites![0].RecipeId);
    }
}

/// <summary>
/// Integration tests for DELETE /api/favorites/{recipeId}.
/// Each test uses a distinct recipe ID to avoid cross-test interference.
/// </summary>
public class FavoriteDeleteTests : IClassFixture<RecipeApiFactory>
{
    private readonly RecipeApiFactory _factory;

    public FavoriteDeleteTests(RecipeApiFactory factory) => _factory = factory;

    [Fact]
    public async Task DeleteFavorite_Favorited_Returns204()
    {
        var client = _factory.CreateClient();

        var post = await client.PostAsJsonAsync("/api/favorites", new AddFavoriteRequest(1));
        Assert.Equal(HttpStatusCode.Created, post.StatusCode);

        var delete = await client.DeleteAsync("/api/favorites/1");

        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);
    }

    [Fact]
    public async Task DeleteFavorite_NotFavorited_Returns404()
    {
        var client = _factory.CreateClient();

        var response = await client.DeleteAsync("/api/favorites/99999");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteFavorite_RemovesFromList()
    {
        var client = _factory.CreateClient();

        var post = await client.PostAsJsonAsync("/api/favorites", new AddFavoriteRequest(2));
        Assert.Equal(HttpStatusCode.Created, post.StatusCode);

        var delete = await client.DeleteAsync("/api/favorites/2");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var getResponse = await client.GetAsync("/api/favorites");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
        var favorites = await getResponse.Content.ReadFromJsonAsync<FavoriteDto[]>();
        Assert.NotNull(favorites);
        Assert.Empty(favorites!);
    }
}
