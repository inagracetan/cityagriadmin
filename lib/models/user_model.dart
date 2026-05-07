import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin', 'program_head', 'staff'
  final String name;
  final String password;
  final String? staffId;
  final String? assignedProgramId; // Matches Program ID in Firestore

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.password = '',
    this.staffId,
    this.assignedProgramId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<dynamic, dynamic>;
    return UserModel(
      uid: doc.id,
      email: (data['email'] as String? ?? '').trim(),
      role: (data['role'] as String? ?? SystemConfig.staffRole).trim(),
      name: (data['name'] as String? ?? '').trim(),
      password: (data['password'] as String? ?? '').trim(),
      staffId: (data['staff_id'] as String?)?.trim(),
      assignedProgramId: (data['assigned_program'] as String?)?.trim(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? name,
    String? password,
    String? staffId,
    String? assignedProgramId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      password: password ?? this.password,
      staffId: staffId ?? this.staffId,
      assignedProgramId: assignedProgramId ?? this.assignedProgramId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'password': password,
      'staff_id': staffId,
      'assigned_program': assignedProgramId,
    };
  }

  bool get isAdmin => role == SystemConfig.adminRole;
  bool get isProgramHead => role == SystemConfig.programHeadRole;

  bool canEditProgram(String programId) {
    if (isAdmin) return true;
    if (isProgramHead && assignedProgramId == programId) return true;
    return false;
  }

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    bool contains(String? source) {
      if (source == null) return false;
      final normalized =
          source.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (normalized.contains(q)) return true;

      // Also check abbreviation
      final abbr = AppConstants.abbreviate(source).toLowerCase();
      if (abbr.contains(q)) return true;

      return false;
    }

    return contains(name) ||
        contains(email) ||
        contains(role) ||
        contains(staffId) ||
        contains(assignedProgramId);
  }
}

