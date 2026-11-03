import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_NavItem> _items = [
    _NavItem('Home', Icons.home_outlined, Icons.home_rounded),
    _NavItem(
      'Baru & Populer',
      Icons.local_fire_department_outlined,
      Icons.local_fire_department_rounded,
    ),
    _NavItem('Daftar Saya', Icons.bookmark_border, Icons.bookmark_rounded),
    _NavItem('Profil', Icons.person_outline, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF080808),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final selected = navigationShell.currentIndex == index;
                return Expanded(
                  child: InkResponse(
                    onTap: () => navigationShell.goBranch(
                      index,
                      initialLocation:
                          index == navigationShell.currentIndex,
                    ),
                    radius: 42,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 22,
                          color:
                              selected ? Colors.white : AppColors.textMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
