class MasterDashboard {
  const MasterDashboard({
    required this.isActive,
    required this.todayIncome,
    required this.monthIncome,
    required this.nextBooking,
    required this.pendingCount,
  });

  final bool isActive;
  final double todayIncome;
  final double monthIncome;
  final MasterNextBooking? nextBooking;
  final int pendingCount;

  factory MasterDashboard.fromJson(Map<String, dynamic> j) => MasterDashboard(
        isActive: j['isActive'] as bool? ?? false,
        todayIncome: (j['todayIncome'] as num?)?.toDouble() ?? 0,
        monthIncome: (j['monthIncome'] as num?)?.toDouble() ?? 0,
        nextBooking: j['nextBooking'] != null
            ? MasterNextBooking.fromJson(j['nextBooking'] as Map<String, dynamic>)
            : null,
        pendingCount: j['pendingCount'] as int? ?? 0,
      );
}

class MasterNextBooking {
  const MasterNextBooking({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.startTime,
  });

  final String id;
  final String clientName;
  final String serviceName;
  final DateTime startTime;

  factory MasterNextBooking.fromJson(Map<String, dynamic> j) => MasterNextBooking(
        id: j['id'] as String,
        clientName: (j['client'] as Map?)?['name'] as String? ?? '—',
        serviceName: (j['service'] as Map?)?['title'] as String? ?? '—',
        startTime: DateTime.parse(j['startsAt'] as String).toLocal(),
      );
}

class MasterBookingItem {
  const MasterBookingItem({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.price,
    required this.startTime,
    required this.status,
  });

  final String id;
  final String clientName;
  final String serviceName;
  final double price;
  final DateTime startTime;
  final String status;

  factory MasterBookingItem.fromJson(Map<String, dynamic> j) => MasterBookingItem(
        id: j['id'] as String,
        clientName: (j['client'] as Map?)?['name'] as String? ?? '—',
        serviceName: (j['service'] as Map?)?['title'] as String? ?? '—',
        price: (j['priceSnapshot'] as num?)?.toDouble() ?? 0,
        startTime: DateTime.parse(j['startsAt'] as String).toLocal(),
        status: j['status'] as String? ?? 'PENDING',
      );
}

class ScheduleSlot {
  const ScheduleSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isWorking,
  });

  final int dayOfWeek; // 1=Mon..7=Sun
  final String startTime; // "HH:mm"
  final String endTime;
  final bool isWorking;

  factory ScheduleSlot.fromJson(Map<String, dynamic> j) => ScheduleSlot(
        dayOfWeek: j['dayOfWeek'] as int,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        // API хранит isDayOff, Flutter использует isWorking (инверсия)
        isWorking: j['isWorking'] as bool? ?? !(j['isDayOff'] as bool? ?? false),
      );

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'isWorking': isWorking,
      };

  ScheduleSlot copyWith({String? startTime, String? endTime, bool? isWorking}) =>
      ScheduleSlot(
        dayOfWeek: dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isWorking: isWorking ?? this.isWorking,
      );
}
