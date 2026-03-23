enum BookingStatus { confirmed, completed, cancelled }

class BookingItem {
  const BookingItem({
    required this.id,
    required this.status,
    required this.startsAt,
    required this.priceSnapshot,
    required this.serviceName,
    required this.masterName,
    this.masterCover,
    this.masterId,
    this.hasReview = false,
  });

  final String id;
  final BookingStatus status;
  final DateTime startsAt;
  final int priceSnapshot;
  final String serviceName;
  final String masterName;
  final String? masterCover;
  final String? masterId;
  final bool hasReview;

  factory BookingItem.fromJson(Map<String, dynamic> j) {
    final statusStr = j['status'] as String;
    final master = j['master'] as Map<String, dynamic>?;
    final masterUser = master?['user'] as Map<String, dynamic>?;
    final photos = master?['portfolioPhotos'] as List?;

    return BookingItem(
      id: j['id'] as String,
      status: switch (statusStr) {
        'COMPLETED' => BookingStatus.completed,
        'CANCELLED' => BookingStatus.cancelled,
        _ => BookingStatus.confirmed,
      },
      startsAt: DateTime.parse(j['startsAt'] as String).toLocal(),
      priceSnapshot: j['priceSnapshot'] as int,
      serviceName: (j['service'] as Map?)?['title'] as String? ?? '',
      masterName: masterUser?['name'] as String? ?? '',
      masterCover: (photos?.isNotEmpty == true)
          ? (photos!.first as Map)['url'] as String?
          : null,
      masterId: master?['id'] as String?,
      hasReview: j['review'] != null,
    );
  }
}
