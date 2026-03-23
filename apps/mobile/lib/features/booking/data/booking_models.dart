class SlotResult {
  const SlotResult({
    required this.date,
    required this.slots,
    required this.isDayOff,
    required this.durationMin,
  });
  final String date;
  final List<String> slots;
  final bool isDayOff;
  final int durationMin;

  factory SlotResult.fromJson(Map<String, dynamic> j) => SlotResult(
        date: j['date'] as String,
        slots: (j['slots'] as List).map((e) => e.toString()).toList(),
        isDayOff: j['isDayOff'] as bool? ?? false,
        durationMin: j['durationMin'] as int? ?? 0,
      );
}
