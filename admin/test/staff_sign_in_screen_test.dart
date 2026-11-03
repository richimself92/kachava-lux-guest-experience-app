import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/presentation/staff_sign_in_screen.dart';

const _submit = Key('staff-sign-in-submit');
const _error = Key('staff-sign-in-error');

Widget _screen(Future<void> Function(String) onSignIn, {bool isEs = false}) =>
    MaterialApp(home: StaffSignInScreen(onSignIn: onSignIn, isEs: isEs));

void main() {
  testWidgets('test_signInScreen_spanish_rendersLocalizedLabels',
      (tester) async {
    await tester.pumpWidget(_screen((_) async {}, isEs: true));

    expect(find.text('KACHAVA LUX · Acceso del Personal'), findsOneWidget);
    expect(find.text('Correo del personal'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('test_signInScreen_rejectedInSpanish_showsSpanishError',
      (tester) async {
    await tester.pumpWidget(_screen(
        (_) async => throw const AdminUnauthorizedException('401'),
        isEs: true));

    await tester.tap(find.byKey(_submit));
    await tester.pump();

    expect(find.text('Acceso rechazado. Revisa tu correo del personal.'),
        findsOneWidget);
  });

  testWidgets('test_signInScreen_onSignInThrowsError_showsErrorAndReenables',
      (tester) async {
    await tester.pumpWidget(_screen((_) async => throw StateError('boom')));

    await tester.tap(find.byKey(_submit));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.byKey(_error)).data,
        'Sign-in failed. Check your connection and try again.');
    expect(
        tester.widget<FilledButton>(find.byKey(_submit)).onPressed, isNotNull);
  });
}
