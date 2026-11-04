import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/helpers/validators.dart';

String i18n(String key, {Map<String, dynamic>? values}) =>
    values == null ? key : '$key ${values.values.first}';

void main() {
  test('required falla con vacío, null y solo espacios', () {
    final validate = Validators.check(i18n, required: true);
    expect(validate(null), TextConstants.validatorRequired);
    expect(validate(''), TextConstants.validatorRequired);
    expect(validate('   '), TextConstants.validatorRequired);
    expect(validate('Pan'), isNull);
  });

  test('un input vacío solo falla con required', () {
    final validate = Validators.check(
      i18n,
      isEmail: true,
      isNumber: true,
      minLength: 3,
      minValue: 1,
    );
    expect(validate(''), isNull);
    expect(validate(null), isNull);
  });

  test('email: sin espacios alrededor y con dominio completo', () {
    final validate = Validators.check(i18n, isEmail: true);
    expect(validate(' ana@correo.com '), isNull);
    expect(validate('ana@sub.correo-web.co'), isNull);
    expect(validate('ana@correo'), TextConstants.validatorEmail);
    expect(validate('x ana@correo.com'), TextConstants.validatorEmail);
  });

  test('largo mínimo y máximo, incluyendo los límites', () {
    final validate = Validators.check(i18n, minLength: 2, maxLength: 3);
    expect(validate('a'), '${TextConstants.validatorMinLength} 2');
    expect(validate('ab'), isNull);
    expect(validate('abc'), isNull);
    expect(validate('abcd'), '${TextConstants.validatorMaxLength} 3');
  });

  test('números: descarta lo no finito y revisa el rango', () {
    final validate = Validators.check(i18n, minValue: 1, maxValue: 5);
    expect(validate('abc'), TextConstants.validatorIsNotNumber);
    expect(validate('NaN'), TextConstants.validatorIsNotNumber);
    expect(validate('Infinity'), TextConstants.validatorIsNotNumber);
    expect(validate('0'), '${TextConstants.validatorMinValue} 1');
    expect(validate('2.5'), isNull);
    expect(validate('6'), '${TextConstants.validatorMaxValue} 5');
    expect(
      Validators.check(i18n, isNumber: true)('x'),
      TextConstants.validatorIsNotNumber,
    );
  });

  group('inputs vacíos y de borde', () {
    test('sin reglas, todo es válido', () {
      final validate = Validators.check(i18n);
      expect(validate(null), isNull);
      expect(validate(''), isNull);
      expect(validate('cualquier cosa'), isNull);
    });

    test('tabs y saltos de línea cuentan como vacío', () {
      final validate = Validators.check(i18n, required: true);
      expect(validate('\t\n  '), TextConstants.validatorRequired);
    });

    test('los espacios de los extremos no cuentan para el largo', () {
      final validate = Validators.check(i18n, maxLength: 3);
      expect(validate('  abc  '), isNull);
      expect(validate('a b c'), '${TextConstants.validatorMaxLength} 3');
    });

    test('un solo carácter sigue contando como texto', () {
      expect(Validators.check(i18n, required: true)('a'), isNull);
    });

    test('email sin arroba, sin usuario o sin dominio', () {
      final validate = Validators.check(i18n, isEmail: true);
      for (final text in ['ana', '@correo.com', 'ana@', 'ana@.com', 'a@b.c']) {
        expect(validate(text), TextConstants.validatorEmail, reason: text);
      }
    });

    test('números negativos, decimales y que desbordan', () {
      final validate = Validators.check(i18n, isNumber: true);
      expect(validate('-5'), isNull);
      expect(validate('.5'), isNull);
      expect(validate('1e400'), TextConstants.validatorIsNotNumber);
      expect(validate('1,5'), TextConstants.validatorIsNotNumber);
    });

    test('el valor mínimo y máximo incluyen los límites', () {
      final validate = Validators.check(i18n, minValue: 0, maxValue: 10);
      expect(validate('0'), isNull);
      expect(validate('10'), isNull);
      expect(validate('-0.1'), '${TextConstants.validatorMinValue} 0');
      expect(validate('10.1'), '${TextConstants.validatorMaxValue} 10');
    });
  });

  test('devuelve el primer error según el orden de las reglas', () {
    final validate = Validators.check(i18n, isEmail: true, minLength: 50);
    expect(validate('nada'), TextConstants.validatorEmail);
  });

  testWidgets('se puede pasar como validator de un campo', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TextFormField(
              validator: Validators.check(i18n, required: true),
            ),
          ),
        ),
      ),
    );
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text(TextConstants.validatorRequired), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Pan');
    expect(formKey.currentState!.validate(), isTrue);
  });
}
