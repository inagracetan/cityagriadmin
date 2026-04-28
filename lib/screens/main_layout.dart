import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/navigation_provider.dart';
import '../services/settings_provider.dart';
import '../widgets/responsive_scaffold.dart';
import '../core/responsive_utils.dart';

import 'admin/admin_dashboard.dart';
import 'staff/staff_dashboard.dart';
import 'admin/sector_overview.dart';
import 'admin/user_management_screen.dart';
import 'admin/financial_reports_screen.dart';
import 'settings_screen.dart';
import 'admin/add_activity_dialog.dart';
import 'admin/edit_activity_dialog.dart';
import 'package:cityagriadmin/main.dart';
import '../services/activity_form_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/chat_widget.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with RouteAware {
  int selectedIndex = 0;
  bool isCurrent = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
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
    if (selectedIndex == index) {
      try {
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
      } catch (_) {}
      return;
    }

    // Reset the nav provider immediately so the new page's defaultTitle
    // is shown right away instead of the previous page's stale title.
    final navProvider = context.read<NavigationProvider>();
    final l10n = context.read<SettingsProvider>().l10n;

    String newTitle;
    switch (index) {
      case 0:
        newTitle = l10n.translate('dashboard');
        break;
      case 1:
        newTitle = l10n.translate('section_unit_allocation');
        break;
      case 2:
        newTitle = l10n.translate('financial_reports');
        break;
      case 3:
        newTitle = l10n.translate('settings');
        break;
      case 4:
        newTitle = l10n.translate('user_management');
        break;
      default:
        newTitle = 'AWFPS';
    }
    navProvider.updateLayout(title: newTitle, actions: [], fab: null);

    setState(() {
      selectedIndex = index;
    });
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
    final l10n = context.watch<SettingsProvider>().l10n;
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Determine default title based on index
    String defaultTitle;
    switch (selectedIndex) {
      case 0:
        defaultTitle = l10n.translate('dashboard');
        break;
      case 1:
        defaultTitle = l10n.translate('section_unit_allocation');
        break;
      case 2:
        defaultTitle = l10n.translate('financial_reports');
        break;
      case 3:
        defaultTitle = l10n.translate('settings');
        break;
      case 4:
        defaultTitle = l10n.translate('user_management');
        break;
      default:
        defaultTitle = 'AWFPS';
    }

    final List<Widget> pages = [
      // Index 0: Dashboard
      user.role == 'admin'
          ? AdminDashboard(isActive: selectedIndex == 0)
          : StaffDashboard(staffName: user.name, isActive: selectedIndex == 0),
      // Index 1: Section/Unit overview
      SectionUnitOverviewScreen(isActive: selectedIndex == 1),
      // Index 2: Financial Reports
      FinancialReportsScreen(isActive: selectedIndex == 2),
      // Index 3: Settings
      SettingsScreen(isActive: selectedIndex == 3),
      // Index 4: User Management (Keep always in list but only accessible to admin)
      user.role == 'admin'
          ? UserManagementScreen(isActive: selectedIndex == 4)
          : const SizedBox.shrink(),
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
              actions: navProvider.actions,
              // Hide the FAB only when the Add Activity form is open or a modal route is pushed
              floatingActionButton: (!isCurrent || formProvider.isOpen)
                  ? null
                  : navProvider.fab,
              body: IndexedStack(index: selectedIndex, children: pages),
            ),
            if (formProvider.isOpen) buildOverlay(context, formProvider),
            // Floating AI Chat Widget
            const Positioned(
              right: 16,
              bottom: 16,
              child: ChatWidget(),
            ),
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
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
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
