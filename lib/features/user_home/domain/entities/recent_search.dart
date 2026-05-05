class RecentSearch {
  final String id;
  final String userId;
  final String query;
  final DateTime searchedAt;

  const RecentSearch({
    required this.id,
    required this.userId,
    required this.query,
    required this.searchedAt,
  });
}
