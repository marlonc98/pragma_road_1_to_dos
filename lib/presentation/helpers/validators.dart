import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';

typedef Translate = String Function(String key, {Map<String, dynamic>? values});

/// Función que valida un input: devuelve el error, o null si es válido. Se
/// puede pasar a cualquier parámetro `validator` de un campo de texto.
typedef InputValidator = String? Function(String? text);

class Validators {
  /// Usuario@dominio.tld completo (anclado: nada antes ni después); el
  /// dominio admite guiones y subdominios. Se valida sin los espacios que
  /// deja el autocompletar del teclado.
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
    r"@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)*"
    r"\.[a-zA-Z]{2,}$",
  );

  /// Número finito (descarta "NaN", "Infinity" y los que desbordan double).
  static double? _finite(String text) {
    final parsed = double.tryParse(text);
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  /// Arma el validador con las reglas indicadas. Devuelve el primer error que
  /// encuentra. Un input vacío solo falla con [required].
  ///
  /// ```dart
  /// TextFormField(validator: Validators.check(i18n, required: true))
  /// ```
  static InputValidator check(
    Translate i18n, {
    bool required = false,
    bool isEmail = false,
    bool isNumber = false,
    int? minLength,
    int? maxLength,
    num? minValue,
    num? maxValue,
  }) {
    return (text) {
      final value = text?.trim() ?? '';
      if (value.isEmpty) {
        return required ? i18n(TextConstants.validatorRequired) : null;
      }
      if (isEmail && !_emailRegExp.hasMatch(value)) {
        return i18n(TextConstants.validatorEmail);
      }
      if (minLength != null && value.length < minLength) {
        return i18n(
          TextConstants.validatorMinLength,
          values: {'minLength': minLength},
        );
      }
      if (maxLength != null && value.length > maxLength) {
        return i18n(
          TextConstants.validatorMaxLength,
          values: {'maxLength': maxLength},
        );
      }
      if (isNumber || minValue != null || maxValue != null) {
        final number = _finite(value);
        if (number == null) return i18n(TextConstants.validatorIsNotNumber);
        if (minValue != null && number < minValue) {
          return i18n(
            TextConstants.validatorMinValue,
            values: {'minValue': minValue},
          );
        }
        if (maxValue != null && number > maxValue) {
          return i18n(
            TextConstants.validatorMaxValue,
            values: {'maxValue': maxValue},
          );
        }
      }
      return null;
    };
  }
}
