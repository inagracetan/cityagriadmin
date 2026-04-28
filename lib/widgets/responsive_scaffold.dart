import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/responsive_utils.dart';
import 'app_drawer.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final String? role;
  final String? staffName;
  final String? staffId;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int selectedIndex;
  final Function(int)? onPageChanged;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.title,
    this.role,
    this.staffName,
    this.staffId,
    this.actions,
    this.floatingActionButton,
    this.selectedIndex = 0,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final displayRole = role ?? user?.role ?? 'staff';
    final displayName = staffName ?? user?.name;
    final displayStaffId = staffId ?? user?.staffId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= ResponsiveUtils.tabletBreakpoint;

        final appBar = AppBar(
          title: Text(
            title,
            style: const TextStyle(
              inherit: true,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.8,
            ),
          ),
          actions: [if (actions != null) ...actions!, const SizedBox(width: 8)],
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Theme.of(context).colorScheme.primary,
          centerTitle: false,
        );

        if (isWide) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: AppMenuContent(
                    role: displayRole,
                    staffName: displayName,
                    staffId: displayStaffId,
                    isSidebar: true,
                    selectedIndex: selectedIndex,
                    onItemSelected: onPageChanged,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      appBar,
                      Expanded(
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: Drawer(
            width: 280,
            child: AppMenuContent(
              role: displayRole,
              staffName: displayName,
              staffId: displayStaffId,
              selectedIndex: selectedIndex,
              onItemSelected: onPageChanged,
            ),
          ),
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}
