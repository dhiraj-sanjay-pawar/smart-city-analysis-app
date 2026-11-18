import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(LoginRequested(
            mobile: _mobileController.text.trim(),
            password: _passwordController.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 460 : double.infinity),
                  child: Stack(
                    children: [
                      // Deep Navy & Teal gradient header
                      Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: AppColors.headerGradient,
                          borderRadius: BorderRadius.only(
                            bottomLeft: const Radius.circular(40),
                            bottomRight: const Radius.circular(40),
                            topLeft: Radius.circular(isWide ? 24 : 0),
                            topRight: Radius.circular(isWide ? 24 : 0),
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                                ),
                                child: const Icon(Icons.location_city_rounded, size: 36, color: Colors.white),
                              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                              const SizedBox(height: 14),
                              Text('Kumbh SmartCity',
                                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))
                                  .animate(delay: 200.ms)
                                  .fadeIn()
                                  .slideY(begin: 0.3, end: 0),
                              const SizedBox(height: 4),
                              Text('Nashik Municipal Analytics Portal',
                                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)))
                                  .animate(delay: 300.ms)
                                  .fadeIn(),
                            ],
                          ),
                        ),
                      ),

                      // Form
                      SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 240),
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.screenPadding),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppStrings.welcomeBack,
                                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                  const SizedBox(height: 4),
                                  Text('Sign in to access Smart City services',
                                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMedium)),
                                  const SizedBox(height: 24),
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        AppTextField(
                                          label: 'Mobile Number or Email',
                                          hint: 'Enter your phone or email',
                                          controller: _mobileController,
                                          keyboardType: TextInputType.emailAddress,
                                          prefixIcon: Icons.person_outline_rounded,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return 'Please enter your mobile or email';
                                            if (v.trim().length < 4) return 'Enter a valid identifier';
                                            return null;
                                          },
                                        ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                                        const SizedBox(height: 16),
                                        AppTextField(
                                          label: AppStrings.password,
                                          hint: 'Enter your password',
                                          controller: _passwordController,
                                          obscureText: true,
                                          prefixIcon: Icons.lock_outline_rounded,
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (_) => _onLogin(),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Enter your password';
                                            if (v.length < 6) return 'Minimum 6 characters';
                                            return null;
                                          },
                                        ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () => context.push('/forgot-password'),
                                            child: const Text(AppStrings.forgotPassword),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        BlocBuilder<AuthBloc, AuthState>(
                                          builder: (context, state) {
                                            return AppButton(
                                              label: AppStrings.signIn,
                                              isLoading: state is AuthLoading,
                                              onPressed: _onLogin,
                                              leadingIcon: Icons.login_rounded,
                                            );
                                          },
                                        ).animate(delay: 300.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text("Don't have an account? ",
                                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMedium)),
                                            GestureDetector(
                                              onTap: () => context.push('/register'),
                                              child: Text(AppStrings.signUp,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                                            ),
                                          ],
                                        ).animate(delay: 400.ms).fadeIn(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
