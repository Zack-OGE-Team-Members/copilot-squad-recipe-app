import { Link } from 'react-router-dom';
import { Badge, Button, Spinner } from '../components/ui';
import { useFavorites, useRemoveFavorite } from '../hooks';
import styles from './FavoritesPage.module.css';

export function FavoritesPage() {
  const { data: favorites, isLoading, isError } = useFavorites();
  const removeMutation = useRemoveFavorite();

  if (isLoading) {
    return <Spinner label="Loading favorites…" />;
  }

  if (isError) {
    return <div className={styles.error}>Couldn't load favorites.</div>;
  }

  return (
    <div className={styles.wrapper}>
      <h1>❤️ Favorites</h1>
      {favorites && favorites.length === 0 ? (
        <p className={styles.empty}>
          🍽️ No favorites yet. <Link to="/recipes">Browse recipes</Link> to add some.
        </p>
      ) : (
        <ul className={styles.list}>
          {favorites?.map((fav) => (
            <li key={fav.id} className={styles.item}>
              <Link to={`/recipes/${fav.recipe.id}`} className={styles.title}>
                {fav.recipe.title}
              </Link>
              <div className={styles.meta}>
                <span>{fav.recipe.difficulty}</span>
                {fav.recipe.tagNames.map((t) => (
                  <Badge key={t} variant="info">
                    {t}
                  </Badge>
                ))}
              </div>
              <Button
                variant="ghost"
                onClick={() => removeMutation.mutate(fav.recipeId)}
                loading={
                  removeMutation.isPending && removeMutation.variables === fav.recipeId
                }
              >
                💔 Remove
              </Button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default FavoritesPage;
