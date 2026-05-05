import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/responsive_utils.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import 'app_drawer.dart';
import 'dart:ui';

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
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= ResponsiveUtils.tabletBreakpoint;

        final appBar = AppBar(
          title: Text(
            title,
            style: AppDesignSystem.headingMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [if (actions != null) ...actions!, const SizedBox(width: 16)],
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          foregroundColor: theme.colorScheme.onSurface,
          centerTitle: false,
        );

        if (isWide) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Row(
              children: [
                // Sidebar
                Container(
                  width: 260, // Slightly wider for a more modern feel
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark 
                        ? AppColors.premiumNavy 
                        : AppColors.secondary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(5, 0),
                      ),
                    ],
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
                // Main Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: theme.brightness == Brightness.dark
                            ? [AppColors.premiumNavy, AppColors.premiumDarkBackground]
                            : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                      ),
                    ),
                    child: Column(
                      children: [
                        appBar,
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: AppDesignSystem.durationNormal,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.01, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          drawer: Drawer(
            width: 260,
            backgroundColor: theme.brightness == Brightness.dark 
                ? AppColors.premiumNavy 
                : AppColors.secondary,
            child: AppMenuContent(
              role: displayRole,
              staffName: displayName,
              staffId: displayStaffId,
              selectedIndex: selectedIndex,
              onItemSelected: onPageChanged,
            ),
          ),
          appBar: appBar,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.brightness == Brightness.dark
                    ? [AppColors.premiumNavy, AppColors.premiumDarkBackground]
                    : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
              ),
            ),
            child: AnimatedSwitcher(
              duration: AppDesignSystem.durationNormal,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.01, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: body,
            ),
          ),
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

      },
    );
  }
}
