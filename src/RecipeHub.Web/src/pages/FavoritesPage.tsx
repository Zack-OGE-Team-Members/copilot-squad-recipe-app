import { Button } from '../components/ui';
import styles from './FavoritesPage.module.css';

export function FavoritesPage() {
  return (
    <div className={styles.wrapper}>
      <h1>❤️ Favorites</h1>
      <p className={styles.empty}>🍽️ No favorites yet. Save recipes you love to find them here.</p>
      <Button variant="ghost" disabled>
        💔 Remove
      </Button>
    </div>
  );
}

export default FavoritesPage;
