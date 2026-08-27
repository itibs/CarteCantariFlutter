class CustomList {
  final String id;
  String name;
  List<String> songIds;
  bool pinned;

  CustomList({
    required this.id,
    required this.name,
    List<String>? songIds,
    this.pinned = false,
  }) : songIds = songIds ?? [];

  factory CustomList.fromJson(Map<String, dynamic> json) {
    return CustomList(
      id: json['id'],
      name: json['name'],
      songIds: ((json['song_ids'] ?? []) as List<dynamic>).cast<String>(),
      pinned: json['pinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "song_ids": songIds,
      "pinned": pinned,
    };
  }
}
