abstract class IFavoritesRepository {
  Future<Set<String>> getFavorites();
  Future<void> storeFavorites(Set<String> favorites);
}
