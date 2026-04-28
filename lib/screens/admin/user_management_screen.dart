import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/navigation_provider.dart';
import '../../core/responsive_utils.dart';
import '../../core/app_colors.dart';

class UserManagementScreen extends StatefulWidget {
  final bool isActive;
  const UserManagementScreen({super.key, this.isActive = true});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  void didUpdateWidget(UserManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateNav();
      });
    }
  }

  void _updateNav() {
    final navProvider = context.read<NavigationProvider>();
    // Update shell
    navProvider.updateLayout(title: 'User Management', actions: [], fab: null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isActive) _updateNav();
    });
  }

  Future<void> _updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role updated to $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStaffId(String uid, String staffId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'staff_id': staffId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff ID updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update Staff ID: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSetStaffIdDialog(UserModel user) {
    final controller = TextEditingController(text: user.staffId ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Set Staff ID',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign a unique ID for ${user.name}',
              style: GoogleFonts.inter(
                color: Slate.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Staff ID',
                labelStyle: GoogleFonts.inter(),
                hintText: 'e.g. AGRI-2024-001',
                filled: true,
                fillColor: Slate.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Slate.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _updateStaffId(user.uid, controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Save ID',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        List<UserModel> users = snapshot.data!.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();

        if (_searchQuery.isNotEmpty) {
          users = users.where((u) => u.matchesSearch(_searchQuery)).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText:
                      'Search by name, email, or role (abbreviations allowed)...',
                  hintStyle: GoogleFonts.inter(
                    color: Slate.shade400,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1B5E20),
                      size: 22,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Slate.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Slate.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF1B5E20),
                      width: 2.0,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: ResponsiveUtils.screenPadding(context),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isMe = user.uid == currentUser?.uid;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: Slate.shade200.withValues(alpha: 0.5),
                        ),
                      ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: user.role == 'admin'
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          user.role == 'admin'
                              ? Icons.shield_rounded
                              : Icons.person_rounded,
                          color: user.role == 'admin'
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                          size: 24,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: -0.3,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (user.staffId != null &&
                              user.staffId!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                ),
                              ),
                                child: Text(
                                  'ID: ${user.staffId}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                            ),
                          ],
                          if (isMe)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                                child: Text(
                                  'YOU',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).colorScheme.primary,
                                    letterSpacing: 1,
                                  ),
                                ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(
                              color: Slate.shade500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'UID: ${user.uid}',
                            style: GoogleFonts.inter(
                              color: Slate.shade300,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: user.role == 'admin'
                                  ? const Color(0xFFE11D48).withValues(alpha: 0.1)
                                  : const Color(0xFF059669).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: user.role == 'admin'
                                    ? const Color(0xFFE11D48)
                                    : const Color(0xFF059669),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: isMe
                          ? null
                          : PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Color(0xFF9CA3AF),
                              ),
                              onSelected: (value) {
                                if (value == 'admin' || value == 'staff') {
                                  _updateUserRole(user.uid, value);
                                } else if (value == 'set_id') {
                                  _showSetStaffIdDialog(user);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'admin',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.shield_outlined,
                                        size: 18,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Set as Admin'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'staff',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 18,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Set as Staff'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'set_id',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.badge_outlined,
                                        size: 18,
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Set Staff ID'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                    ),
                  ),
                );
              },
              ),
            ),
          ],
        );
      },
    );
  }
}
