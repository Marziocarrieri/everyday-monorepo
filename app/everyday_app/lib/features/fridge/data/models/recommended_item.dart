class RecommendedItem {
  final int id;
  final String name;
  final String picture; // 'PENDING', 'BOUGHT'

  RecommendedItem({
    required this.id,
    required this.name,
    required this.picture,
  });

  factory RecommendedItem.fromJson(Map<String, dynamic> json) {
    return RecommendedItem(
      id: json['id'].toInt(),
      name: json['name'],
      picture: json['picture'],
    );
  }
}