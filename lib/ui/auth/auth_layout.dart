import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/app_colors.dart';

class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? footer;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Design Elements
          Positioned(
            top: -100,
            right: -100,
            child: FadeInDown(
              duration: const Duration(milliseconds: 1000),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.05),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.05),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 600),
                    child: child,
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 32),
                    ...footer!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
