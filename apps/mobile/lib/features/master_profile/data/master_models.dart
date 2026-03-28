class MasterService {
  const MasterService({
    required this.id,
    required this.title,
    required this.category,
    required this.priceFrom,
    required this.durationMin,
  });
  final String id;
  final String title;
  final String category;
  final int priceFrom;
  final int durationMin;

  factory MasterService.fromJson(Map<String, dynamic> j) => MasterService(
        id: j['id'] as String,
        title: j['title'] as String,
        category: j['category'] as String,
        priceFrom: j['priceFrom'] as int,
        durationMin: j['durationMin'] as int,
      );
}

class MasterReview {
  const MasterReview({
    required this.id,
    required this.rating,
    required this.createdAt,
    required this.clientName,
    this.text,
    this.clientAvatar,
  });
  final String id;
  final int rating;
  final String? text;
  final DateTime createdAt;
  final String clientName;
  final String? clientAvatar;

  factory MasterReview.fromJson(Map<String, dynamic> j) => MasterReview(
        id: j['id'] as String,
        rating: j['rating'] as int,
        text: j['text'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        clientName: (j['client'] as Map?)?['name'] as String? ?? '',
        clientAvatar: (j['client'] as Map?)?['avatarUrl'] as String?,
      );
}

class MasterPortfolioPhoto {
  const MasterPortfolioPhoto({required this.id, required this.url, this.thumbUrl});
  final String id;
  final String url;
  final String? thumbUrl;

  factory MasterPortfolioPhoto.fromJson(Map<String, dynamic> j) =>
      MasterPortfolioPhoto(
        id: j['id'] as String,
        url: j['url'] as String,
        thumbUrl: j['thumbUrl'] as String?,
      );
}

class MasterProfile {
  const MasterProfile({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceM,
    required this.specializations,
    required this.services,
    required this.reviews,
    required this.photos,
    required this.reviewCount,
    this.avatarUrl,
    this.bio,
    this.rating,
    this.minPrice,
    this.lat,
    this.lng,
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
  final double? lat;
  final double? lng;
  final List<String> specializations;
  final List<MasterService> services;
  final List<MasterReview> reviews;
  final List<MasterPortfolioPhoto> photos;

  factory MasterProfile.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return MasterProfile(
      id: j['id'] as String,
      name: user?['name'] as String? ?? '',
      avatarUrl: user?['avatarUrl'] as String?,
      bio: j['bio'] as String?,
      address: j['address'] as String? ?? '',
      rating: (j['rating'] as num?)?.toDouble(),
      reviewCount: j['reviewCount'] as int? ?? 0,
      distanceM: j['distanceM'] as int? ?? 0,
      minPrice: j['minPrice'] as int?,
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      specializations: (j['specializations'] as List?)
              ?.map((e) => (e as Map)['category'].toString())
              .toList() ??
          [],
      services: (j['services'] as List?)
              ?.map((e) => MasterService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviews: (j['reviews'] as List?)
              ?.map((e) => MasterReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      photos: (j['portfolioPhotos'] as List?)
              ?.map((e) =>
                  MasterPortfolioPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
