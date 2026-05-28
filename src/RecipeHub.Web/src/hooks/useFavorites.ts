import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '../api';
import type { AddFavoriteRequest, FavoriteDto } from '../api';
import { favoriteKeys } from './queryKeys';

export function useFavorites() {
  return useQuery<FavoriteDto[]>({
    queryKey: favoriteKeys.lists(),
    queryFn: () => apiClient.listFavorites(),
  });
}

export function useAddFavorite() {
  const qc = useQueryClient();
  return useMutation<FavoriteDto, Error, AddFavoriteRequest>({
    mutationFn: (req) => apiClient.addFavorite(req),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: favoriteKeys.lists() });
    },
  });
}

export function useRemoveFavorite() {
  const qc = useQueryClient();
  return useMutation<void, Error, number>({
    mutationFn: (recipeId) => apiClient.removeFavorite(recipeId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: favoriteKeys.lists() });
    },
  });
}
