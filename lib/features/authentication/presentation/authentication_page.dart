import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_breakpoints.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import 'providers/auth_providers.dart';

class AuthenticationPage extends ConsumerStatefulWidget {
  const AuthenticationPage({required this.isRegister, super.key});

  final bool isRegister;

  @override
  ConsumerState<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends ConsumerState<AuthenticationPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(authenticationProvider.notifier);
    if (widget.isRegister) {
      await controller.register(
        displayName: _displayNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      return;
    }

    await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  void _switchMode() {
    ref.read(authenticationProvider.notifier).clearError();
    final destination = widget.isRegister
        ? AppRoutes.login
        : AppRoutes.register;
    final returnLocation = GoRouterState.of(
      context,
    ).uri.queryParameters['from'];
    context.go(
      Uri(
        path: destination,
        queryParameters: returnLocation == null
            ? null
            : {'from': returnLocation},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.section,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.compact,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _BrandHeader(),
                        const SizedBox(height: AppSpacing.extraLarge),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppSpacing.extraLarge,
                            ),
                            child: Form(
                              key: _formKey,
                              autovalidateMode: AutovalidateMode.onUnfocus,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    widget.isRegister ? '建立會員帳號' : '歡迎回來',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: AppSpacing.small),
                                  Text(
                                    widget.isRegister
                                        ? '開始記錄每日飲食與營養目標。'
                                        : '登入後繼續管理你的飲食紀錄。',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.large),
                                  if (widget.isRegister) ...[
                                    TextFormField(
                                      key: const Key('display-name-field'),
                                      controller: _displayNameController,
                                      enabled: !authState.isAuthenticating,
                                      autovalidateMode: AutovalidateMode
                                          .onUserInteractionIfError,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: '顯示名稱',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                      validator: _validateDisplayName,
                                    ),
                                    const SizedBox(height: AppSpacing.medium),
                                  ],
                                  TextFormField(
                                    key: const Key('auth-email-field'),
                                    controller: _emailController,
                                    enabled: !authState.isAuthenticating,
                                    autovalidateMode: AutovalidateMode
                                        .onUserInteractionIfError,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: '電子郵件',
                                      prefixIcon: Icon(Icons.mail_outline),
                                    ),
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  TextFormField(
                                    key: const Key('auth-password-field'),
                                    controller: _passwordController,
                                    enabled: !authState.isAuthenticating,
                                    autovalidateMode: AutovalidateMode
                                        .onUserInteractionIfError,
                                    obscureText: _obscurePassword,
                                    autofillHints: [
                                      widget.isRegister
                                          ? AutofillHints.newPassword
                                          : AutofillHints.password,
                                    ],
                                    textInputAction: widget.isRegister
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    onFieldSubmitted: widget.isRegister
                                        ? null
                                        : (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: '密碼',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? '顯示密碼'
                                            : '隱藏密碼',
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: _validatePassword,
                                  ),
                                  if (widget.isRegister) ...[
                                    const SizedBox(height: AppSpacing.medium),
                                    TextFormField(
                                      key: const Key('confirm-password-field'),
                                      controller: _confirmPasswordController,
                                      enabled: !authState.isAuthenticating,
                                      autovalidateMode: AutovalidateMode
                                          .onUserInteractionIfError,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: const InputDecoration(
                                        labelText: '確認密碼',
                                        prefixIcon: Icon(
                                          Icons.lock_reset_outlined,
                                        ),
                                      ),
                                      validator: _validateConfirmPassword,
                                    ),
                                  ],
                                  if (authState.errorMessage
                                      case final error?) ...[
                                    const SizedBox(height: AppSpacing.medium),
                                    _AuthenticationError(message: error),
                                  ],
                                  const SizedBox(height: AppSpacing.large),
                                  FilledButton(
                                    key: const Key('auth-submit-button'),
                                    onPressed: authState.isAuthenticating
                                        ? null
                                        : _submit,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.small,
                                      ),
                                      child: authState.isAuthenticating
                                          ? const SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              widget.isRegister ? '註冊' : '登入',
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  TextButton(
                                    key: const Key('switch-auth-mode-button'),
                                    onPressed: authState.isAuthenticating
                                        ? null
                                        : _switchMode,
                                    child: Text(
                                      widget.isRegister
                                          ? '已經有帳號？前往登入'
                                          : '還沒有帳號？建立會員帳號',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        const _PrototypeNotice(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().length < 2) {
      return '請輸入至少 2 個字元的顯示名稱';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final atIndex = email.indexOf('@');
    if (atIndex <= 0 ||
        atIndex >= email.length - 3 ||
        email.indexOf('.', atIndex) <= atIndex + 1) {
      return '請輸入有效的電子郵件';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return '密碼至少需要 8 個字元';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return '兩次輸入的密碼不一致';
    }
    return null;
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.restaurant_menu, color: theme.colorScheme.primary, size: 32),
        const SizedBox(width: AppSpacing.small),
        Text(
          'FoodLedger',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AuthenticationError extends StatelessWidget {
  const _AuthenticationError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: AppRadius.smallBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrototypeNotice extends StatelessWidget {
  const _PrototypeNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Prototype 模式：可使用任意有效信箱與 8 字元以上密碼。'
      '以 admin@ 開頭的信箱可預覽管理頁面。',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
