import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/settings_provider.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/sector_overview.dart';

class AppDrawer extends StatelessWidget {
  final String role;
  final String? staffName;
  final String? staffId;

  const AppDrawer({
    super.key,
    required this.role,
    this.staffName,
    this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: AppMenuContent(role: role, staffName: staffName, staffId: staffId),
    );
  }
}

class AppMenuContent extends StatelessWidget {
  final String role;
  final String? staffName;
  final String? staffId;
  final bool isSidebar;
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const AppMenuContent({
    super.key,
    required this.role,
    this.staffName,
    this.staffId,
    this.isSidebar = false,
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final l10n = context.watch<SettingsProvider>().l10n;

    return Container(
      color: isSidebar ? Theme.of(context).colorScheme.surface : null,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Image.asset(
                        'assets/AgriLogo.png',
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role == 'admin'
                                ? l10n.translate('admin_panel')
                                : l10n.translate('staff_panel'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AWFPS Admin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(
                                context,
                              ).textTheme.titleLarge?.color,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (staffName != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                          child: Text(
                            staffName![0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staffName!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (staffId != null && staffId!.isNotEmpty)
                              Text(
                                'ID: $staffId',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildItem(
                  context,
                  index: 0,
                  icon: Icons.dashboard,
                  title: l10n.translate('dashboard'),
                  onTap: () {
                    if (onItemSelected != null) {
                      onItemSelected!(0);
                    } else {
                      if (!isSidebar) Navigator.pop(context);
                    }
                  },
                ),
                _buildItem(
                  context,
                  index: 1,
                  icon: Icons.category,
                  title: l10n.translate('section_unit_overview'),
                  onTap: () {
                    if (onItemSelected != null) {
                      onItemSelected!(1);
                    } else {
                      if (!isSidebar) Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SectionUnitOverviewScreen(),
                        ),
                      );
                    }
                  },
                ),
                _buildItem(
                  context,
                  index: 2,
                  icon: Icons.bar_chart,
                  title: l10n.translate('financial_reports'),
                  onTap: () {
                    if (onItemSelected != null) {
                      onItemSelected!(2);
                    } else {
                      if (!isSidebar) Navigator.pop(context);
                    }
                  },
                ),
                if (role == 'admin') ...[
                  _buildItem(
                    context,
                    index: 4,
                    icon: Icons.people,
                    title: l10n.translate('user_management'),
                    onTap: () {
                      if (onItemSelected != null) {
                        onItemSelected!(4);
                      } else {
                        if (!isSidebar) Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
                _buildItem(
                  context,
                  index: 3,
                  icon: Icons.settings,
                  title: l10n.translate('settings'),
                  onTap: () {
                    if (onItemSelected != null) {
                      onItemSelected!(3);
                    } else {
                      if (!isSidebar) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildItem(
              context,
              index: -1, // No highlight for logout
              icon: Icons.logout,
              title: l10n.translate('logout'),
              color: Colors.redAccent,
              onTap: () {
                if (!isSidebar) Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(l10n.translate('confirm_logout')),
                      content: Text(l10n.translate('logout_confirm_msg')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(l10n.translate('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            authService.signOut();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.translate('logout')),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isSelected = index == selectedIndex;
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? activeColor.withValues(alpha: 0.08)
              : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            selected: isSelected,
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? activeColor
                    : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                inherit: true,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? activeColor
                    : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                letterSpacing: 0.1,
              ),
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
