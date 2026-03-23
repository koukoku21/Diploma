import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Русские форматы дат (DateFormat('d MMM', 'ru'))
  await initializeDateFormatting('ru');

  // Firebase + FCM (требует google-services.json / GoogleService-Info.plist)
  await PushService.init();

  runApp(const ProviderScope(child: MirakuApp()));
}

class MirakuApp extends StatelessWidget {
  const MirakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Miraku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
