import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';

class ServiceTemplate {
  const ServiceTemplate({
    required this.id,
    required this.name,
    this.nameKz,
    required this.category,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String? nameKz;
  final String category;
  final int sortOrder;

  factory ServiceTemplate.fromJson(Map<String, dynamic> j) => ServiceTemplate(
        id: j['id'] as String,
        name: j['name'] as String,
        nameKz: j['nameKz'] as String?,
        category: j['category'] as String,
        sortOrder: (j['sortOrder'] as num).toInt(),
      );

  // Метка категории для UI
  static String categoryLabel(String key) {
    const map = {
      'MANICURE': 'Маникюр',
      'PEDICURE': 'Педикюр',
      'HAIRCUT': 'Стрижки',
      'COLORING': 'Окрашивание',
      'MAKEUP': 'Макияж',
      'LASHES': 'Ресницы',
      'BROWS': 'Брови',
      'SKINCARE': 'Уход',
      'OTHER': 'Другое',
    };
    return map[key] ?? key;
  }
}

// Провайдер — загружается один раз, кэшируется
final serviceTemplatesProvider =
    FutureProvider<List<ServiceTemplate>>((ref) async {
  final res = await createDio().get('/service-templates');
  return (res.data as List)
      .map((j) => ServiceTemplate.fromJson(j as Map<String, dynamic>))
      .toList();
});
