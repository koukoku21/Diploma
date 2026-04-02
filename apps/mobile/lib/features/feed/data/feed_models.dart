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
    this.isBoosted = false,
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
  final bool isBoosted;

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
        isBoosted: j['isBoosted'] as bool? ?? false,
        specializations: (j['specializations'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

// ─── Story ────────────────────────────────────────────────────────

class StoryItem {
  const StoryItem({
    required this.id,
    required this.mediaUrl,
    required this.salonName,
    this.caption,
    this.category,
    this.salonLogoUrl,
    this.isPaid = false,
    this.expiresAt,
    this.viewCount = 0,
  });

  final String id;
  final String mediaUrl;
  final String salonName;
  final String? caption;
  final String? category;
  final String? salonLogoUrl;
  final bool isPaid;
  final DateTime? expiresAt;
  final int viewCount;

  factory StoryItem.fromJson(Map<String, dynamic> j) => StoryItem(
        id: j['id'] as String,
        mediaUrl: j['mediaUrl'] as String,
        salonName: j['salonName'] as String? ?? 'Салон',
        caption: j['caption'] as String?,
        category: j['category'] as String?,
        salonLogoUrl: j['salonLogoUrl'] as String?,
        isPaid: j['isPaid'] as bool? ?? false,
        expiresAt: j['expiresAt'] != null
            ? DateTime.tryParse(j['expiresAt'] as String)
            : null,
        viewCount: j['viewCount'] as int? ?? 0,
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
