import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_layout.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _institutionController = TextEditingController(
    text: 'University of Rwanda',
  );
  final _coursesController = TextEditingController();

  UserRole _selectedRole = UserRole.student;
  String _selectedTitle = 'Mr';
  final List<String> _titles = [
    'Mr',
    'Mrs',
    'Mss',
    'Dr',
    'Prof',
    'Assoc. Prof',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _institutionController.dispose();
    _coursesController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _fullNameController.text.trim(),
            role: _selectedRole,
            title: _selectedRole == UserRole.teacher ? _selectedTitle : null,
            institution: _institutionController.text.trim(),
          );

      if (ref.read(authControllerProvider).hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(authControllerProvider).error.toString()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthLayout(
      title: 'Create Account',
      subtitle: 'Join our modern attendance system today',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Role Selection
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _RoleButton(
                      label: 'Student',
                      isSelected: _selectedRole == UserRole.student,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.student),
                    ),
                  ),
                  Expanded(
                    child: _RoleButton(
                      label: 'Teacher',
                      isSelected: _selectedRole == UserRole.teacher,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.teacher),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedRole == UserRole.teacher) ...[
              DropdownButtonFormField<String>(
                value: _selectedTitle,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: _titles.map((title) {
                  return DropdownMenuItem(value: title, child: Text(title));
                }).toList(),
                onChanged: (val) => setState(() => _selectedTitle = val!),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Invalid email'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _institutionController,
              decoration: const InputDecoration(
                hintText: 'Institution',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              validator: (value) =>
                  value == null || value.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: authState.isLoading ? null : _handleSignup,
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
      footer: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Already have an account?"),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Sign In',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
