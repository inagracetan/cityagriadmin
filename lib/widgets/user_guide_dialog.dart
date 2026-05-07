import 'package:flutter/material.dart';
import '../core/design_system.dart';
import 'enhanced_buttons_dialogs.dart';

class UserGuideDialog extends StatelessWidget {
  const UserGuideDialog({super.key});

  static void show(BuildContext context) {
    EnhancedDialog.show(
      context,
      title: '🌾 System User Guide',
      width: 800,
      content: const UserGuideDialog(),
      actions: [
        EnhancedButton(
          label: 'Got it!',
          onPressed: () => Navigator.pop(context),
          variant: ButtonVariant.primary,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            icon: Icons.rocket_launch,
            title: 'Getting Started',
            content: 'Navigate using the sidebar menu on the left. The Dashboard provides a quick overview of all ongoing projects and financial status.',
          ),
          _buildSection(
            context,
            icon: Icons.view_kanban,
            title: 'Projects & Kanban',
            content: 'Track activities by dragging cards across workflow stages: Proposed → Ongoing → Completed → Closed. Use filters to narrow down your view.',
          ),
          _buildSection(
            context,
            icon: Icons.assignment,
            title: 'Activity Management',
            content: 'Create activities with detailed objectives and budgets. Log Purchase Requests (PRs) directly within each activity to track real-time spending.',
          ),
          _buildSection(
            context,
            icon: Icons.minimize,
            title: 'Form Minimization',
            content: 'Need to multitask? Minimize any form to a floating tab on the right side of your screen. Click it to restore your work anytime.',
          ),
          _buildSection(
            context,
            icon: Icons.analytics,
            title: 'Financial Reports',
            content: 'Generate and export comprehensive data to Excel. View sector-specific breakdowns and track every cent allocated to agricultural programs.',
          ),
          _buildSection(
            context,
            icon: Icons.settings,
            title: 'Personalization',
            content: 'Toggle Dark Mode in Settings for a better experience at night. Switch languages to suit your preference.',
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusMedium),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppDesignSystem.spacing12),
                const Expanded(
                  child: Text(
                    'For technical support, please contact the City Agriculture system administrator.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusSmall),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: AppDesignSystem.spacing12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

