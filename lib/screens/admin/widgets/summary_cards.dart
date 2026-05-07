import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/activity.dart';
import '../../../services/settings_provider.dart';
import '../../../core/responsive_utils.dart';
import '../../../core/design_system.dart';

class SummaryCardsRow extends StatelessWidget {
  final List<Activity> activities;
  final NumberFormat formatCurrency;
  final Function(String) onFundSelected;

  const SummaryCardsRow({
    super.key,
    required this.activities,
    required this.formatCurrency,
    required this.onFundSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<SettingsProvider>().l10n;
    double totalMOOE = 0;
    double spentMOOE = 0;
    double totalCapitalOutlay = 0;
    double totalDF20 = 0;

    for (var a in activities) {
      final budget = a.totalBudget;
      final spent = a.effectivePOAmount;
      if (a.fundingSource == 'Agri MOOE') {
        totalMOOE += budget;
        spentMOOE += spent;
      } else if (a.fundingSource == 'Capital Outlay') {
        totalCapitalOutlay += budget;
      } else if (a.fundingSource == '20% DF') {
        totalDF20 += budget;
      }
    }

    double totalMayorsFund = activities
        .where((a) => a.fundingSource == "Mayor's Fund" || a.fundingSource == 'Mayors Fund')
        .fold(0.0, (s, a) => s + a.totalBudget);

    final totalApproved = activities.fold(0.0, (s, a) => s + a.totalBudget);
    final totalSpent = activities.fold(0.0, (s, a) => s + a.effectivePOAmount);

    final isMobile = ResponsiveUtils.isMobile(context);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = ResponsiveUtils.isDesktop(context);
          final sideBarWidth = isDesktop ? 260.0 : 0.0;
          final horizontalPadding = isMobile ? 24.0 : 48.0;
          final availableWidth = screenWidth - sideBarWidth - horizontalPadding;

          int crossAxisCount = ResponsiveUtils.valueByScreen(
            context,
            mobile: 1,
            tablet: screenWidth < 800 ? 2 : 3,
            desktop: screenWidth < 1400 ? 3 : 5,
          );

          const double spacing = 16.0;
          final double cardWidth =
              (availableWidth - (crossAxisCount - 1) * spacing) /
              crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children: [
              if (activities.isNotEmpty) ...[
                _SummaryCard(
                  title: l10n.translate('allocated_budget'),
                  helpText: 'Total budget approved for all agricultural programs in the current fiscal year.',
                  amount: totalApproved,
                  color: const Color(0xFF2E7D32),
                  icon: Icons.account_balance,
                  width: cardWidth,
                  formatCurrency: formatCurrency,
                  onTap: () {},
                ),
                _SummaryCard(
                  title: l10n.translate('overall_total'),
                  helpText: 'Total amount already committed or spent via Purchase Requests (PR).',
                  amount: totalSpent,
                  color: const Color(0xFF1976D2),
                  icon: Icons.payments,
                  width: cardWidth,
                  formatCurrency: formatCurrency,
                  onTap: () {},
                ),
                _SummaryCard(
                  title: l10n.translate('overall_unexpended_balance'),
                  helpText: 'Remaining funds available for future procurement or projects.',
                  amount: totalApproved - totalSpent,
                  color: const Color(0xFFE65100),
                  icon: Icons.account_balance_wallet,
                  width: cardWidth,
                  formatCurrency: formatCurrency,
                  onTap: () {},
                ),
                _SummaryCard(
                  title: l10n.translate('utilization'),
                  helpText: 'Percentage of the budget that has been spent. Higher is usually better for project completion.',
                  amount: totalSpent,
                  color: const Color(0xFF6A1B9A),
                  icon: Icons.pie_chart,
                  width: cardWidth,
                  utilRate: totalApproved > 0 ? totalSpent / totalApproved : 0,
                  formatCurrency: formatCurrency,
                  subtitle: 'of ${formatCurrency.format(totalApproved)}',
                  onTap: () => onFundSelected(''),
                ),
              ],
              if (activities.any((a) => a.fundingSource == 'Agri MOOE'))
                _SummaryCard(
                  title: 'Agri MOOE Spent',
                  amount: spentMOOE,
                  color: const Color(0xFF1976D2),
                  icon: Icons.business_center,
                  width: cardWidth,
                  utilRate: totalMOOE > 0 ? spentMOOE / totalMOOE : 0,
                  formatCurrency: formatCurrency,
                  subtitle: 'of ${formatCurrency.format(totalMOOE)}',
                  onTap: () => onFundSelected('Agri MOOE'),
                ),
              if (activities.any((a) => a.fundingSource == 'Capital Outlay'))
                _SummaryCard(
                  title: 'Capital Outlay',
                  amount: totalCapitalOutlay,
                  color: const Color(0xFF2E7D32),
                  icon: Icons.account_balance,
                  width: cardWidth,
                  utilRate: totalApproved > 0
                      ? totalCapitalOutlay / totalApproved
                      : 0,
                  formatCurrency: formatCurrency,
                  onTap: () => onFundSelected('Capital Outlay'),
                ),
              if (activities.any((a) => a.fundingSource == '20% DF'))
                _SummaryCard(
                  title: 'Total 20% DF',
                  amount: totalDF20,
                  color: const Color(0xFFE65100),
                  icon: Icons.monetization_on,
                  width: cardWidth,
                  utilRate: totalApproved > 0 ? totalDF20 / totalApproved : 0,
                  formatCurrency: formatCurrency,
                  onTap: () => onFundSelected('20% DF'),
                ),
              if (activities.any((a) => a.fundingSource == 'Mayors Fund'))
                _SummaryCard(
                  title: 'Mayors Fund',
                  amount: totalMayorsFund,
                  color: const Color(0xFFD4AF37),
                  icon: Icons.account_balance_wallet,
                  width: cardWidth,
                  utilRate: totalApproved > 0
                      ? totalMayorsFund / totalApproved
                      : 0,
                  formatCurrency: formatCurrency,
                  onTap: () => onFundSelected('Mayors Fund'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final double width;
  final double? utilRate;
  final NumberFormat formatCurrency;
  final String? subtitle;
  final String? helpText;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.width,
    this.utilRate,
    required this.formatCurrency,
    this.subtitle,
    this.helpText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconBox(),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (helpText != null) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: helpText!,
                          child: Icon(
                            Icons.info_outline,
                            size: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatCurrency.format(amount),
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (utilRate != null) ...[
              const SizedBox(width: 16),
              _buildUtilizationCircle(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildUtilizationCircle() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: (utilRate ?? 0).clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            strokeWidth: 4.5,
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              '${((utilRate ?? 0) * 100).toInt()}%',
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

