namespace RecipeHub.Api.Dtos;

public record FavoriteDto(int Id, int RecipeId, DateTime CreatedAt, RecipeDto Recipe);
public record AddFavoriteRequest(int RecipeId);

