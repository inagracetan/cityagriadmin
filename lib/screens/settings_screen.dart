import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/navigation_provider.dart';
import '../core/responsive_utils.dart';

class SettingsScreen extends StatefulWidget {
  final bool isActive;
  const SettingsScreen({super.key, this.isActive = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateNav();
      });
    }
  }

  void _updateNav() {
    final l10n = context.read<SettingsProvider>().l10n;
    Provider.of<NavigationProvider>(
      context,
      listen: false,
    ).updateLayout(title: l10n.translate('settings'), actions: [], fab: null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isActive) _updateNav();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final authService = context.watch<AuthService>();
    final l10n = settingsProvider.l10n;
    final theme = Theme.of(context);
    final user = authService.currentUser;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: ResponsiveUtils.screenPadding(context).copyWith(top: 24, bottom: 24),
          children: [
            _SectionHeader(title: l10n.translate('account')),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1,
                  ),
                  radius: 28,
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                title: Text(
                  user?.name ?? 'Unknown User',
                  style: const TextStyle(
                    inherit: true,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  'Role: ${user?.role ?? 'Unknown'} • ${user?.email ?? ''}',
                  style: TextStyle(
                    inherit: true,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6,
                    ),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      _showEditProfileDialog(context, authService, l10n),
                  tooltip: l10n.translate('edit_profile'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.translate('change_password')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _showChangePasswordDialog(context, authService, l10n),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _SectionHeader(title: l10n.translate('preferences')),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text(l10n.translate('notifications')),
                subtitle: Text(l10n.translate('notifications_subtitle')),
                secondary: Icon(
                  Icons.notifications_outlined,
                  color: theme.colorScheme.primary,
                ),
                value: settingsProvider.notificationsEnabled,
                onChanged: settingsProvider.toggleNotifications,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(l10n.translate('dark_mode')),
                subtitle: Text(l10n.translate('dark_mode_subtitle')),
                secondary: Icon(
                  Icons.dark_mode_outlined,
                  color: theme.colorScheme.primary,
                ),
                value: settingsProvider.isDarkMode,
                onChanged: settingsProvider.toggleDarkMode,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.language_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.translate('language')),
                subtitle: Text(settingsProvider.language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(context, settingsProvider),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _SectionHeader(title: l10n.translate('about')),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.translate('app_version')),
                trailing: const Text(
                  '1.0.0',
                  style: TextStyle(inherit: true, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.privacy_tip_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.translate('privacy_policy')),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('privacy_policy_soon')),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.translate('terms_of_service')),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('terms_of_service_soon')),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextButton.icon(
            onPressed: () => _confirmLogout(context, authService, l10n),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(
              l10n.translate('logout_account'),
              style: const TextStyle(inherit: true, color: Colors.red),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
      ],
    ),
  ),
);
}

  void _showEditProfileDialog(
    BuildContext context,
    AuthService authService,
    dynamic l10n,
  ) {
    final controller = TextEditingController(
      text: authService.currentUser?.name,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('edit_profile')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.translate('full_name'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await authService.updateProfile(controller.text);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(l10n.translate('save')),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AuthService authService,
    dynamic l10n,
  ) {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.translate('change_password')),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldController,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: l10n.translate('current_password'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOld
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => obscureOld = !obscureOld),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? l10n.translate('required') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: l10n.translate('new_password'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (val) =>
                          val!.length < 6 ? l10n.translate('too_short') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: l10n.translate('confirm_new_password'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (val) => val != newController.text
                          ? l10n.translate('passwords_match_fail')
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await authService.updatePassword(
                        oldController.text,
                        newController.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.translate('password_updated')),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: Text(l10n.translate('update')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.l10n.translate('select_language'),
                  style: const TextStyle(
                    inherit: true,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('English'),
                  trailing: provider.language == 'English'
                      ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    provider.setLanguage('English');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Tagalog'),
                  trailing: provider.language == 'Tagalog'
                      ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    provider.setLanguage('Tagalog');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(
    BuildContext context,
    AuthService authService,
    dynamic l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_logout')),
        content: Text(l10n.translate('logout_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authService.signOut();
            },
            child: Text(
              l10n.translate('logout'),
              style: const TextStyle(inherit: true, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          inherit: true,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

