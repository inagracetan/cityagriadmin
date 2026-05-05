import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/settings_provider.dart';
import '../core/design_system.dart';
import '../core/app_colors.dart';

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
      backgroundColor: Colors.transparent,
      elevation: 0,
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
      decoration: BoxDecoration(
        color: const Color(0xFF0B121E), // Deeper, darker navy for a more premium look
        border: isSidebar 
          ? Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.03)))
          : null,
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Image.asset(
                        'assets/AgriLogo.png',
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.agriculture_rounded, color: AppColors.primaryAccent, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (role == 'admin' ? 'ADMIN PANEL' : 'STAFF PANEL'),
                            style: TextStyle(
                              color: AppColors.primaryAccent.withValues(alpha: 0.8),
                              letterSpacing: 1.2,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'CityAgri Portal',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),


              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: [
                _buildSectionHeader('PLANNING'),
                _buildItem(
                  context,
                  index: 0,
                  icon: Icons.grid_view_rounded,
                  title: 'Dashboard',
                  onTap: () => _handleNavigation(0, context),
                ),
                _buildItem(
                  context,
                  index: 8,
                  icon: Icons.folder_rounded,
                  title: 'Projects (PPMP)',
                  onTap: () => _handleNavigation(8, context),
                ),
                _buildItem(
                  context,
                  index: 2,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Budget Allocation',
                  onTap: () => _handleNavigation(2, context),
                ),
                _buildItem(
                  context,
                  index: 4,
                  icon: Icons.event_note_rounded,
                  title: 'WFP (WFP Monthly)',
                  onTap: () => _handleNavigation(4, context),
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('EXECUTION'),
                _buildItem(
                  context,
                  index: 1,
                  icon: Icons.shopping_cart_rounded,
                  title: 'Procurement',
                  onTap: () => _handleNavigation(1, context),
                ),
                _buildItem(
                  context,
                  index: 9,
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Approvals',
                  onTap: () => _handleNavigation(9, context),
                ),
                _buildItem(
                  context,
                  index: 5,
                  icon: Icons.analytics_rounded,
                  title: 'Reports',
                  onTap: () => _handleNavigation(5, context),
                ),
                _buildItem(
                  context,
                  index: 6,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () => _handleNavigation(6, context),
                ),
              ],
            ),
          ),
          
          // Logout Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildItem(
              context,
              index: -1,
              icon: Icons.logout_rounded,
              title: 'Logout',
              color: Colors.white.withValues(alpha: 0.6),
              onTap: () => _showLogoutDialog(context, authService, l10n),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(int index, BuildContext context) {
    if (onItemSelected != null) {
      onItemSelected!(index);
    } else {
      if (!isSidebar) Navigator.pop(context);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          letterSpacing: 2.0,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
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
    final activeColor = color ?? const Color(0xFF10B981); // Vibrant Green

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
              border: isSelected ? Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService, dynamic l10n) {
    if (!isSidebar) Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(l10n.translate('confirm_logout'), style: AppDesignSystem.headingSmall),
          content: Text(l10n.translate('logout_confirm_msg'), style: AppDesignSystem.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.translate('cancel'), style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                authService.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.translate('logout')),
            ),
          ],
        );
      },
    );
  }

}
