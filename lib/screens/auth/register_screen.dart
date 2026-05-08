import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/agri_ui.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/enhanced_form_fields.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onLoginTap;

  const RegisterScreen({super.key, required this.onLoginTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _adminCodeCtl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _adminCodeFocus = FocusNode();
  String _selectedRole = 'staff';
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureAdminCode = true;

  final String _secretAdminCode = 'AGRI-ADMIN-${SystemConfig.nextFiscalYearStr}';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    _nameCtl.dispose();
    _adminCodeCtl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _adminCodeFocus.dispose();
    super.dispose();
  }

  void _register() async {
    if (_emailCtl.text.isEmpty ||
        _passCtl.text.isEmpty ||
        _nameCtl.text.isEmpty) {
      AgriUI.showError(context, 'Please fill all fields');
      return;
    }

    if (_selectedRole == 'admin' && _adminCodeCtl.text != _secretAdminCode) {
      AgriUI.showError(context, 'Invalid Admin Verification Code!');
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.register(
        _emailCtl.text.trim(),
        _passCtl.text,
        _nameCtl.text.trim(),
        role: _selectedRole,
      );
    } catch (e) {
      if (mounted) {
        AgriUI.showError(context, 'Registration failed: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/agri.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.1),
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset('assets/AgriLogo.png', height: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Join AWFPS',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      TextField(
                        controller: _nameCtl,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _emailCtl,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _passCtl,
                        focusNode: _passFocus,
                        obscureText: _obscurePassword,
                        textInputAction: _selectedRole == 'admin' ? TextInputAction.next : TextInputAction.done,
                        onSubmitted: (_) {
                          if (_selectedRole == 'admin') {
                            FocusScope.of(context).requestFocus(_adminCodeFocus);
                          } else if (!_loading) {
                            _register();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      EnhancedSearchableDropdownField<String>(
                        label: 'Account Type',
                        value: _selectedRole,
                        entries: const [
                          DropdownMenuEntry(value: 'staff', label: 'Office Staff'),
                          DropdownMenuEntry(value: 'admin', label: 'System Administrator'),
                        ],
                        onSelected: (val) => setState(() => _selectedRole = val!),
                        prefixIcon: const Icon(Icons.badge_outlined),
                        width: double.infinity,
                      ),
                      
                      if (_selectedRole == 'admin') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _adminCodeCtl,
                          focusNode: _adminCodeFocus,
                          obscureText: _obscureAdminCode,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _loading ? null : _register(),
                          decoration: InputDecoration(
                            labelText: 'Admin Verification Code',
                            prefixIcon: const Icon(Icons.security),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureAdminCode ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureAdminCode = !_obscureAdminCode),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      if (_loading)
                        const SkeletonLoading(height: 50, borderRadius: 12)
                      else
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?", style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: widget.onLoginTap,
                            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


