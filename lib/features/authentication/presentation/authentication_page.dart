import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_breakpoints.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_brand_banner.dart';
import 'auth_strings.dart';
import 'providers/auth_providers.dart';

class AuthenticationPage extends ConsumerStatefulWidget {
  const AuthenticationPage({required this.isRegister, super.key});

  final bool isRegister;

  @override
  ConsumerState<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends ConsumerState<AuthenticationPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _userAccountController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginIdController.dispose();
    _userAccountController.dispose();
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
      final succeeded = await controller.register(
        userAccount: _userAccountController.text,
        displayName: _displayNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!succeeded && mounted) {
        _formKey.currentState?.validate();
      }
      return;
    }

    final succeeded = await controller.signIn(
      loginId: _loginIdController.text,
      password: _passwordController.text,
    );
    if (!succeeded && mounted) {
      _formKey.currentState?.validate();
    }
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
      appBar: const AppBrandBanner(),
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
                                    widget.isRegister
                                        ? AuthStrings.registerTitle
                                        : AuthStrings.loginTitle,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: AppSpacing.small),
                                  Text(
                                    widget.isRegister
                                        ? AuthStrings.registerSubtitle
                                        : AuthStrings.loginSubtitle,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.large),
                                  ..._buildCredentialFields(authState),
                                  if (authState.errorMessage
                                      case final error?) ...[
                                    const SizedBox(height: AppSpacing.medium),
                                    _AuthenticationError(
                                      message: error,
                                      traceId: authState.traceId,
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.large),
                                  _buildSubmitButton(authState),
                                  const SizedBox(height: AppSpacing.medium),
                                  _buildSwitchModeButton(authState),
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

  List<Widget> _buildCredentialFields(AuthenticationState authState) {
    return [
      if (widget.isRegister)
        ..._buildRegistrationFields(authState)
      else
        _buildLoginIdField(authState),
      const SizedBox(height: AppSpacing.medium),
      _buildPasswordField(authState),
      if (widget.isRegister) ...[
        const SizedBox(height: AppSpacing.medium),
        _buildConfirmPasswordField(authState),
      ],
    ];
  }

  List<Widget> _buildRegistrationFields(AuthenticationState authState) {
    return [
      TextFormField(
        key: const Key('auth-user-account-field'),
        controller: _userAccountController,
        enabled: !authState.isAuthenticating,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        autofillHints: const [AutofillHints.newUsername],
        textInputAction: TextInputAction.next,
        onChanged: (_) => _clearServerErrors(),
        decoration: const InputDecoration(
          labelText: AuthStrings.userAccountLabel,
          helperText: AuthStrings.userAccountHelper,
          prefixIcon: Icon(Icons.alternate_email),
        ),
        validator: _validateUserAccount,
      ),
      const SizedBox(height: AppSpacing.medium),
      TextFormField(
        key: const Key('auth-display-name-field'),
        controller: _displayNameController,
        enabled: !authState.isAuthenticating,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _clearServerErrors(),
        decoration: const InputDecoration(
          labelText: AuthStrings.displayNameLabel,
          prefixIcon: Icon(Icons.badge_outlined),
        ),
        validator: _validateDisplayName,
      ),
      const SizedBox(height: AppSpacing.medium),
      TextFormField(
        key: const Key('auth-email-field'),
        controller: _emailController,
        enabled: !authState.isAuthenticating,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.next,
        onChanged: (_) => _clearServerErrors(),
        decoration: const InputDecoration(
          labelText: AuthStrings.emailLabel,
          prefixIcon: Icon(Icons.mail_outline),
        ),
        validator: _validateEmail,
      ),
    ];
  }

  Widget _buildLoginIdField(AuthenticationState authState) {
    return TextFormField(
      key: const Key('auth-login-id-field'),
      controller: _loginIdController,
      enabled: !authState.isAuthenticating,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      autofillHints: const [AutofillHints.username],
      textInputAction: TextInputAction.next,
      onChanged: (_) => _clearServerErrors(),
      decoration: const InputDecoration(
        labelText: AuthStrings.loginIdLabel,
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: _validateLoginId,
    );
  }

  Widget _buildPasswordField(AuthenticationState authState) {
    return TextFormField(
      key: const Key('auth-password-field'),
      controller: _passwordController,
      enabled: !authState.isAuthenticating,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      obscureText: _obscurePassword,
      autofillHints: [
        widget.isRegister ? AutofillHints.newPassword : AutofillHints.password,
      ],
      textInputAction: widget.isRegister
          ? TextInputAction.next
          : TextInputAction.done,
      onChanged: (_) => _clearServerErrors(),
      onFieldSubmitted: widget.isRegister ? null : (_) => _submit(),
      decoration: InputDecoration(
        labelText: AuthStrings.passwordLabel,
        helperText: widget.isRegister ? AuthStrings.passwordHelper : null,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscurePassword
              ? AuthStrings.showPassword
              : AuthStrings.hidePassword,
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
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
    );
  }

  Widget _buildConfirmPasswordField(AuthenticationState authState) {
    return TextFormField(
      key: const Key('confirm-password-field'),
      controller: _confirmPasswordController,
      enabled: !authState.isAuthenticating,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onChanged: (_) => _clearServerErrors(),
      onFieldSubmitted: (_) => _submit(),
      decoration: const InputDecoration(
        labelText: AuthStrings.confirmPasswordLabel,
        prefixIcon: Icon(Icons.lock_reset_outlined),
      ),
      validator: _validateConfirmPassword,
    );
  }

  Widget _buildSubmitButton(AuthenticationState authState) {
    return FilledButton(
      key: const Key('auth-submit-button'),
      onPressed: authState.isAuthenticating ? null : _submit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
        child: authState.isAuthenticating
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                widget.isRegister
                    ? AuthStrings.registerButton
                    : AuthStrings.loginButton,
              ),
      ),
    );
  }

  Widget _buildSwitchModeButton(AuthenticationState authState) {
    return TextButton(
      key: const Key('switch-auth-mode-button'),
      onPressed: authState.isAuthenticating ? null : _switchMode,
      child: Text(
        widget.isRegister
            ? AuthStrings.switchToLogin
            : AuthStrings.switchToRegister,
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final atIndex = email.indexOf('@');
    if (atIndex <= 0 ||
        atIndex >= email.length - 3 ||
        email.indexOf('.', atIndex) <= atIndex + 1) {
      return AuthStrings.emailInvalid;
    }
    return _serverFieldError('email');
  }

  String? _validateLoginId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AuthStrings.loginIdRequired;
    }
    return _serverFieldError('loginId');
  }

  String? _validateUserAccount(String? value) {
    final userAccount = value?.trim() ?? '';
    if (!RegExp(r'^[A-Za-z0-9_-]{4,30}$').hasMatch(userAccount)) {
      return AuthStrings.userAccountInvalid;
    }
    return _serverFieldError('userAccount');
  }

  String? _validateDisplayName(String? value) {
    final displayName = value?.trim() ?? '';
    if (displayName.isEmpty || displayName.length > 30) {
      return AuthStrings.displayNameInvalid;
    }
    return _serverFieldError('displayName');
  }

  String? _validatePassword(String? value) {
    if (!widget.isRegister) {
      if (value == null || value.isEmpty) {
        return AuthStrings.passwordRequired;
      }
      return _serverFieldError('password');
    }

    if (value == null || value.length < 8) {
      return AuthStrings.passwordTooShort;
    }
    if (!RegExp('[A-Z]').hasMatch(value) ||
        !RegExp('[a-z]').hasMatch(value) ||
        !RegExp('[0-9]').hasMatch(value)) {
      return AuthStrings.passwordComplexity;
    }
    return _serverFieldError('password');
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return AuthStrings.confirmPasswordMismatch;
    }
    return null;
  }

  String? _serverFieldError(String fieldName) {
    return ref.read(authenticationProvider).fieldErrors[fieldName];
  }

  void _clearServerErrors() {
    final authState = ref.read(authenticationProvider);
    if (authState.errorMessage != null || authState.fieldErrors.isNotEmpty) {
      ref.read(authenticationProvider.notifier).clearError();
    }
  }
}

class _AuthenticationError extends StatelessWidget {
  const _AuthenticationError({required this.message, this.traceId});

  final String message;
  final String? traceId;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                  if (traceId case final value?) ...[
                    const SizedBox(height: AppSpacing.extraSmall),
                    Text(
                      '${AuthStrings.traceIdLabel}：$value',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ],
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
      AuthStrings.prototypeNotice,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
