import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/procurement.dart';
import '../../services/firebase_service.dart';

import '../../core/app_colors.dart';

class ProcurementDetailsDialog extends StatelessWidget {
  final Procurement procurement;
  final FirebaseService fbService;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProcurementDetailsDialog({
    super.key,
    required this.procurement,
    required this.fbService,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {

    final currencyFormat = NumberFormat.simpleCurrency(name: 'PHP ');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.assignment_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Procurement Details',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'PR #: ${procurement.prNumber}',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Section
                    _buildSectionTitle('Current Status'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Slate.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Slate.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              procurement.status.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1B5E20),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Last Update: ${procurement.statusDate}',
                            style: GoogleFonts.inter(
                              color: Slate.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Financial Details
                    _buildSectionTitle('Financial Information'),
                    const SizedBox(height: 12),
                    _buildInfoRow('PPMP Allocation', currencyFormat.format(procurement.ppmpAmount)),
                    _buildInfoRow('PR Amount', currencyFormat.format(procurement.prAmount)),
                    _buildInfoRow('Current Balance', currencyFormat.format(procurement.prBalance), isBold: true),
                    
                    const Divider(height: 32),

                    // PO Details
                    if (procurement.poNumber.isNotEmpty) ...[
                      _buildSectionTitle('Purchase Order'),
                      const SizedBox(height: 12),
                      _buildInfoRow('PO Number', procurement.poNumber),
                      _buildInfoRow('PO Amount', currencyFormat.format(procurement.poAmount)),
                      if (procurement.poDate != null)
                        _buildInfoRow('PO Date', procurement.poDate!),
                      const Divider(height: 32),
                    ],

                    // Meta Information
                    _buildSectionTitle('Classification'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Supplier', procurement.supplier.isEmpty ? 'Not Assigned' : procurement.supplier),
                    _buildInfoRow('Fund Source', procurement.fundSource),
                    _buildInfoRow('Object of Exp.', procurement.objectOfExpenditure),

                    const SizedBox(height: 32),

                    // Actions
                    if (canEdit)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'View Only: You do not have permission to edit this program\'s procurements.',
                                style: GoogleFonts.inter(
                                  color: Colors.orange.shade800,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Slate.shade400,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Slate.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Slate.shade900,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

