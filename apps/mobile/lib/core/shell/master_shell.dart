import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class MasterShell extends StatelessWidget {
  const MasterShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: navigationShell,
      bottomNavigationBar: _MasterTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i,
            initialLocation: i == navigationShell.currentIndex),
      ),
    );
  }
}

class _MasterTabBar extends StatelessWidget {
  const _MasterTabBar({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      _TabItem(icon: Icons.dashboard_outlined, label: 'Главная'),
      _TabItem(icon: Icons.calendar_today_outlined, label: 'Записи'),
      _TabItem(icon: Icons.access_time_rounded, label: 'Расписание'),
      _TabItem(icon: Icons.person_outline, label: 'Профиль'),
    ];

    return SafeArea(
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: kBgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final active = currentIndex == i;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: active
                        ? kGold.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon,
                          color: active ? kGold : kTextTertiary, size: 22),
                      const SizedBox(height: 2),
                      Text(item.label,
                          style: AppTextStyles.caption.copyWith(
                            color: active ? kGold : kTextTertiary,
                            fontSize: 10,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
