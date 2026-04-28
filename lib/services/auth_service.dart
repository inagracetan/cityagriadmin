import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '940939770223-43ss2oinvne7ggpauamjm2hldjp8h0qr.apps.googleusercontent.com'
        : null,
  );
  UserModel? currentUser;
  bool isLoading = true;
  StreamSubscription<DocumentSnapshot>? userSubscription;

  AuthService() {
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    if (uid != null) {
      subscribeToUser(uid);
    } else {
      isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToUser(String uid) {
    userSubscription?.cancel();
    userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            currentUser = UserModel.fromFirestore(doc);
          } else {
            currentUser = null;
          }
          isLoading = false;
          notifyListeners();
        });
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_email');
  }

  Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_password');
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password, {
    bool rememberMe = false,
    String? expectedRole,
  }) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userDoc = querySnapshot.docs.first;
      final tempUser = UserModel.fromFirestore(userDoc);

      currentUser = tempUser;
      final prefs = await SharedPreferences.getInstance();

      if (rememberMe) {
        await prefs.setString('uid', currentUser!.uid);
        await prefs.setString('saved_email', email.trim());
        await prefs.setString('saved_password', password);
      } else {
        await prefs.remove('uid');
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }

      subscribeToUser(currentUser!.uid);
    } else {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> signInWithGoogle() async {
    isLoading = true;
    notifyListeners();

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        isLoading = false;
        notifyListeners();
        return; // User canceled
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          currentUser = UserModel.fromFirestore(doc);
        } else {
          // If the user sign-in email already exists in another doc, link them or just create a new one?
          // Since the mock auth doesn't use standard Firebase Auth UIDs,
          // we might want to search by email if UID isn't found.
          final emailQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();

          if (emailQuery.docs.isNotEmpty) {
            // Already exist with this email, maybe update their record with UID or just use that record
            final existingDoc = emailQuery.docs.first;
            currentUser = UserModel.fromFirestore(existingDoc);
          } else {
            // New user via Google Sign-In
            final newUser = UserModel(
              uid: user.uid,
              email: user.email ?? '',
              name: user.displayName ?? '',
              role: 'staff', // Default role
              password: '', // No password needed for Google users
            );
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set(newUser.toFirestore());
            currentUser = newUser;
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', currentUser!.uid);
        subscribeToUser(currentUser!.uid);
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register(
    String email,
    String password,
    String name, {
    String role = 'staff',
  }) async {
    final existing = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Email already exists');
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc();
    final newUser = UserModel(
      uid: docRef.id,
      email: email.trim(),
      role: role.trim(),
      name: name.trim(),
      password: password.trim(),
    );

    await docRef.set(newUser.toFirestore());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', newUser.uid);
    subscribeToUser(newUser.uid);
  }

  Future<void> updateProfile(String name) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({'name': name.trim()});
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    if (currentUser == null) return;
    if (currentUser!.password != oldPassword) {
      throw Exception('Current password does not match');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({'password': newPassword});

    // Update local cache so same-session re-validation works correctly
    currentUser = currentUser!.copyWith(password: newPassword);

    // Keep SharedPreferences in sync for "Remember Me" auto-login
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('saved_password');
    if (savedPassword != null) {
      await prefs.setString('saved_password', newPassword);
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    userSubscription?.cancel();
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');

    // Also sign out from Google and Firebase Auth
    await auth.signOut();
    await googleSignIn.signOut();

    notifyListeners();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    super.dispose();
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return null;
  }

  Future<void> resetPassword(
    String email,
    String fullName,
    String newPassword,
  ) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .where('name', isEqualTo: fullName.trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception(
        'Identity verification failed. Please ensure your email and full name match our records.',
      );
    }

    final docId = query.docs.first.id;
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'password': newPassword,
    });
  }
}
