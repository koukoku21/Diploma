import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class ClientShell extends StatelessWidget {
  const ClientShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Лента'),
    _TabItem(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Избранное'),
    _TabItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Чаты'),
    _TabItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Записи'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FloatingTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        tabs: _tabs,
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> tabs;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: kBgPrimary,
      child: Container(
        margin: EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, bottom + AppSpacing.sm),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: kBgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final active = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: active
                          ? BoxDecoration(
                              color: kGold.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            )
                          : null,
                      child: Icon(
                        active ? tabs[i].activeIcon : tabs[i].icon,
                        color: active ? kGold : kTextTertiary,
                        size: 22,
                      ),
                    ),
                    Text(
                      tabs[i].label,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: active ? kGold : kTextTertiary,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(
      {required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
