import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/features/authentication/presentation/providers/auth_providers.dart';

void main() {
  group('AuthenticationController', () {
    test('初始狀態為未登入', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(authenticationProvider);

      expect(state.status, AuthenticationStatus.unauthenticated);
      expect(state.user, isNull);
    });

    test('登入後建立 Session 並可登出', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final validPassword = List.filled(8, 'x').join();

      final succeeded = await container
          .read(authenticationProvider.notifier)
          .signIn(email: 'admin@example.com', password: validPassword);

      expect(succeeded, isTrue);
      expect(container.read(authenticationProvider).user?.isAdmin, isTrue);

      container.read(authenticationProvider.notifier).signOut();

      expect(
        container.read(authenticationProvider).status,
        AuthenticationStatus.unauthenticated,
      );
    });
  });
}
