import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/auth/auth_controller.dart";
import "../../routes/app_routes.dart";
import "../../core/theme/app_colors.dart";
import "../../core/config/env_controller.dart";
import "../../core/config/app_env.dart";

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _showPassword = false;

  static const _rememberKey = "remember_me";
  static const _rememberEmailKey = "remember_email";

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberKey) ?? false;
    final email = prefs.getString(_rememberEmailKey) ?? "";
    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (remember && email.isNotEmpty) {
          _emailController.text = email;
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_rememberEmailKey, _emailController.text.trim());
    } else {
      await prefs.remove(_rememberEmailKey);
    }
    final auth = ref.read(authControllerProvider.notifier);
    final ok = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (ok && mounted) {
      context.go(AppRoutes.dashboard);
    } else if (mounted) {
      final message = ref.read(authControllerProvider).errorMessage ??
          "Login failed. Please try again.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final env = ref.watch(envControllerProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "ENV: ${_label(env)}",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppColors.grey500),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push("/settings/env"),
                    child: const Text("Switch"),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      "assets/icons/agaliaLogo.svg",
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Please enter your credentials to access the platform.",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.greyBlue),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.black),
                      decoration: const InputDecoration(
                        labelText: "Email address",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Email is required";
                        }
                        if (!value.contains("@")) {
                          return "Invalid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: AppColors.black),
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Password is required";
                        }
                        if (value.length < 5) {
                          return "Minimum password length is 5 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                          activeColor: AppColors.primary,
                        ),
                        const Text("Remember me"),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.resetPassword),
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: authState.isLoading ? null : _submit,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Login"),
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
}

String _label(AppEnvironment env) {
  switch (env) {
    case AppEnvironment.dev:
      return "Dev";
    case AppEnvironment.devsc:
      return "DevSC";
    case AppEnvironment.qa:
      return "QA";
    case AppEnvironment.stage:
      return "Stage";
    case AppEnvironment.prod:
      return "Prod";
  }
}
