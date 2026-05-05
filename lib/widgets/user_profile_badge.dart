import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProfileBadge extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const UserProfileBadge({super.key, required this.user, this.onTap});

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    List<String> names = name.trim().split(RegExp(r'\s+'));
    if (names.length >= 2) {
      return (names[0][0] + (names[1].isNotEmpty ? names[1][0] : '')).toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getInitials(user.name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
