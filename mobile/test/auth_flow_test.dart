import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdreporta/core/theme/app_theme.dart';
import 'package:rdreporta/features/auth/login_screen.dart';
import 'package:rdreporta/features/home/home_screen.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final width in [360.0, 800.0]) {
    testWidgets('social sign-in does not create a fake session at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()));
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(HomeScreen), findsNothing);
      expect(await const FlutterSecureStorage().read(key: 'jwt_token'), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
