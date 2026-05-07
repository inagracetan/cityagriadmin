import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/navigation_provider.dart';
import '../services/settings_provider.dart';
import '../widgets/responsive_scaffold.dart';
import '../core/responsive_utils.dart';

import 'admin/ppmp_dashboard.dart';
import 'staff/staff_dashboard.dart';
import 'admin/sector_overview.dart';
import 'admin/user_management_screen.dart';
import 'admin/activity_management_screen.dart';
import 'admin/financial_reports_screen.dart';
import 'settings_screen.dart';
import 'admin/add_activity_dialog.dart';
import 'admin/edit_activity_dialog.dart';
import 'admin/budget_management_screen.dart';
import 'expenditure_tracker_screen.dart';
import 'package:cityagriadmin/main.dart';
import '../services/activity_form_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/skeleton_loading.dart';
import 'admin/projects_screen.dart';
import 'admin/approvals_screen.dart';
import '../widgets/user_guide_dialog.dart';
import '../widgets/notification_center.dart';
import '../widgets/user_profile_badge.dart';
import '../models/notification_model.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with RouteAware {
  bool isCurrent = true;
  StreamSubscription? _notificationSubscription;
  DateTime _appStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.uid;
    if (userId == null) return;

    final settingsProvider = context.read<SettingsProvider>();
    
    // Cancel existing if any
    _notificationSubscription?.cancel();
    
    if (!settingsProvider.notificationsEnabled) return;

    final fbService = context.read<FirebaseService>();
    _notificationSubscription = fbService.streamNotifications(userId: userId).listen(
      (notifications) {
        if (notifications.isEmpty) return;

        // Only look at the most recent one
        final latest = notifications.first;
        
        // If it's new (after app start) and unread
        if (latest.timestamp.isAfter(_appStartTime) && !latest.isRead) {
          // Update app start time so we don't show the same one again 
          _appStartTime = latest.timestamp;
          
          _showInAppNotification(latest);
        }
      },
      onError: (e) => debugPrint('Notification Stream Error: $e'),
    );
  }

  void _showInAppNotification(SystemNotification notification) {
    if (!mounted) return;

    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              _getNotificationIcon(notification.type, theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type, ThemeData theme) {
    IconData icon;
    Color color;
    switch (type) {
      case NotificationType.success:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.warning:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case NotificationType.error:
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = theme.colorScheme.primary;
    }
    return Icon(icon, color: color, size: 24);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didPushNext() {
    // A new route was pushed on top of us (e.g., a dialog)
    setState(() => isCurrent = false);
  }

  @override
  void didPopNext() {
    // The route on top of us was popped, we are now current again
    setState(() => isCurrent = true);
  }

  void onPageChanged(int index) {
    final navProvider = context.read<NavigationProvider>();
    if (navProvider.selectedIndex == index) {
      try {
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
      } catch (_) {}
      return;
    }

    // Reset the nav provider immediately so the new page's defaultTitle
    // is shown right away instead of the previous page's stale title.
    final l10n = context.read<SettingsProvider>().l10n;

    String newTitle;
    switch (index) {
      case 0:
        newTitle = 'Budget Management';
        break;
      case 1:
        newTitle = 'Activity Management';
        break;
      case 2:
        newTitle = l10n.translate('dashboard');
        break;
      case 3:
        newTitle = 'Expenditure Tracker';
        break;
      case 4:
        newTitle = l10n.translate('section_unit_allocation');
        break;
      case 5:
        newTitle = l10n.translate('financial_reports');
        break;
      case 6:
        newTitle = l10n.translate('settings');
        break;
      case 7:
        newTitle = l10n.translate('user_management');
        break;
      case 8:
        newTitle = 'Projects (PPMP)';
        break;
      case 9:
        newTitle = 'Approvals';
        break;
      default:
        newTitle = 'AWFPS';
    }
    navProvider.updateLayout(title: newTitle, actions: [], fab: null, selectedIndex: index);

    try {
      if (Scaffold.of(context).isDrawerOpen) {
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final navProvider = context.watch<NavigationProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final l10n = settingsProvider.l10n;
    final selectedIndex = navProvider.selectedIndex;
    final user = authService.currentUser;

    // Check if notifications were toggled
    if (settingsProvider.notificationsEnabled && _notificationSubscription == null) {
      _setupNotificationListener();
    } else if (!settingsProvider.notificationsEnabled && _notificationSubscription != null) {
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
    }

    if (user == null) {
      return const Scaffold(body: SkeletonDashboard());
    }

    // Determine default title based on index
    String defaultTitle;
    switch (selectedIndex) {
      case 0:
        defaultTitle = 'Budget Management';
        break;
      case 1:
        defaultTitle = 'Activity Management';
        break;
      case 2:
        defaultTitle = l10n.translate('dashboard');
        break;
      case 3:
        defaultTitle = 'Expenditure Tracker';
        break;
      case 4:
        defaultTitle = l10n.translate('section_unit_allocation');
        break;
      case 5:
        defaultTitle = l10n.translate('financial_reports');
        break;
      case 6:
        defaultTitle = l10n.translate('settings');
        break;
      case 7:
        defaultTitle = l10n.translate('user_management');
        break;
      case 8:
        defaultTitle = 'Projects (PPMP)';
        break;
      case 9:
        defaultTitle = 'Approvals';
        break;
      default:
        defaultTitle = 'AWFPS';
    }
    final List<Widget> pages = [
      // Index 0: Budget Management
      BudgetManagementScreen(isActive: selectedIndex == 0),
      // Index 1: Activity Management
      ActivityManagementScreen(isActive: selectedIndex == 1),
      // Index 2: Dashboard
      user.role == 'admin'
          ? PPMPDashboard(isActive: selectedIndex == 2)
          : StaffDashboard(staffName: user.name, isActive: selectedIndex == 2),
      // Index 3: Expenditure Tracker
      ExpenditureTrackerScreen(isActive: selectedIndex == 3),
      // Index 4: Section/Unit overview
      SectionUnitOverviewScreen(isActive: selectedIndex == 4),
      // Index 5: Financial Reports
      FinancialReportsScreen(isActive: selectedIndex == 5),
      // Index 6: Settings
      SettingsScreen(isActive: selectedIndex == 6),
      // Index 7: User Management
      user.role == 'admin'
          ? UserManagementScreen(isActive: selectedIndex == 7)
          : const SizedBox.shrink(),
      // Index 8: Projects (PPMP)
      ProjectsScreen(isActive: selectedIndex == 8),
      // Index 9: Approvals
      ApprovalsScreen(isActive: selectedIndex == 9),
    ];

    return Consumer<ActivityFormProvider>(
      builder: (context, formProvider, child) {
        return Stack(
          children: [
            ResponsiveScaffold(
              title:
                  navProvider.title == 'LGU Agri App' ||
                      navProvider.title.isEmpty
                  ? defaultTitle
                  : navProvider.title,
              selectedIndex: selectedIndex,
              onPageChanged: onPageChanged,
              actions: [
                const ConnectionStatusBadge(),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'System Guide',
                  onPressed: () => UserGuideDialog.show(context),
                ),
                StreamBuilder<List<SystemNotification>>(
                  stream: context.read<FirebaseService>().streamNotifications(userId: user.uid),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          tooltip: 'Notifications',
                          onPressed: () => NotificationCenter.show(context),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                ...?navProvider.actions,
                UserProfileBadge(
                  user: user,
                  onTap: () => onPageChanged(6), // Navigate to Settings
                ),
              ],
              // Hide the FAB only when the Add Activity form is open and NOT minimized, or a modal route is pushed
              floatingActionButton: (!isCurrent || (formProvider.isOpen && !formProvider.isMinimized))
                  ? null
                  : navProvider.fab,
              body: IndexedStack(index: selectedIndex, children: pages),
            ),
            if (formProvider.isOpen) buildOverlay(context, formProvider),
          ],
        );
      },
    );
  }

  Widget buildOverlay(BuildContext context, ActivityFormProvider formProvider) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Stack(
      key: const ValueKey('form_overlay'),
      fit: StackFit.expand,
      children: [
        // Centered popup and Backdrop (Offstage if minimized)
        Offstage(
          offstage: formProvider.isMinimized,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Dark backdrop: tapping outside minimizes the form
              GestureDetector(
                onTap: () => formProvider.minimizeForm(),
                child: Container(color: Colors.black.withOpacity(0.45)),
              ),
              // Centered popup
              Center(
                child: Container(
                  width: isMobile
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width * 0.95,
                  height: isMobile
                      ? MediaQuery.of(context).size.height
                      : MediaQuery.of(context).size.height * 0.95,
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 1300,
                    maxHeight: isMobile ? double.infinity : 1100,
                  ),
                  child: Material(
                    elevation: isMobile ? 0 : 24,
                    color: Colors.white,
                    borderRadius: isMobile
                        ? BorderRadius.zero
                        : BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child:
                        formProvider.isEditing &&
                            formProvider.editingActivity != null
                        ? EditActivityDialog(
                            key: ValueKey(
                              'edit_activity_${formProvider.editingActivity?.id}',
                            ),
                            fbService: context.read<FirebaseService>(),
                            activity: formProvider.editingActivity!,
                          )
                        : AddActivityDialog(
                            key: const ValueKey('add_activity_form'),
                            fbService: context.read<FirebaseService>(),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Floating Tab (Only if minimized)
        if (formProvider.isMinimized)
          MinimizedActivityTab(formProvider: formProvider),
      ],
    );
  }
}

class MinimizedActivityTab extends StatefulWidget {
  final ActivityFormProvider formProvider;
  const MinimizedActivityTab({super.key, required this.formProvider});

  @override
  State<MinimizedActivityTab> createState() => MinimizedActivityTabState();
}

class MinimizedActivityTabState extends State<MinimizedActivityTab> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Vertically centered on the right
      top: MediaQuery.of(context).size.height * 0.45,
      right: 0,
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          // Hide most of the tab when not hovered (only icon peeks)
          transform: Matrix4.translationValues(
            isHovered ? 0 : 190, // Adjust based on estimated width
            0,
            0,
          ),
          child: Material(
            elevation: isHovered ? 12 : 4,
            shadowColor: Colors.black45,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            color: Theme.of(context).colorScheme.primary,
            child: InkWell(
              onTap: () => widget.formProvider.restoreForm(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 28, 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_task, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Restore Form',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Close button always accessible but smaller
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 18,
                      ),
                      onPressed: () => widget.formProvider.closeForm(),
                      tooltip: 'Close form',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceholderView extends StatelessWidget {
  final String title;
  const PlaceholderView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '$title is under development',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

