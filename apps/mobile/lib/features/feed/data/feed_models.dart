class FeedMaster {
  const FeedMaster({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceM,
    required this.specializations,
    required this.reviewCount,
    this.avatarUrl,
    this.bio,
    this.rating,
    this.minPrice,
    this.coverUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String address;
  final double? rating;
  final int reviewCount;
  final int distanceM;
  final int? minPrice;
  final String? coverUrl;
  final List<String> specializations;

  String get distanceLabel {
    if (distanceM < 1000) return '$distanceMм';
    return '${(distanceM / 1000).toStringAsFixed(1)}км';
  }

  factory FeedMaster.fromJson(Map<String, dynamic> j) => FeedMaster(
        id: j['id'] as String,
        name: j['name'] as String,
        avatarUrl: j['avatarUrl'] as String?,
        bio: j['bio'] as String?,
        address: j['address'] as String,
        rating: (j['rating'] as num?)?.toDouble(),
        reviewCount: j['reviewCount'] as int? ?? 0,
        distanceM: j['distanceM'] as int? ?? 0,
        minPrice: j['minPrice'] as int?,
        coverUrl: j['coverUrl'] as String?,
        specializations: (j['specializations'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class FeedResponse {
  const FeedResponse({
    required this.items,
    required this.hasMore,
    required this.nextOffset,
  });

  final List<FeedMaster> items;
  final bool hasMore;
  final int nextOffset;

  factory FeedResponse.fromJson(Map<String, dynamic> j) => FeedResponse(
        items: (j['items'] as List)
            .map((e) => FeedMaster.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: j['hasMore'] as bool,
        nextOffset: j['nextOffset'] as int,
      );
}
