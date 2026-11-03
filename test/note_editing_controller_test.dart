import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/controllers/note_editing_controller.dart';

void main() {
  Future<TextSpan> buildSpan(
    WidgetTester tester,
    NoteEditingController controller,
  ) async {
    late TextSpan span;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          span = controller.buildTextSpan(
            context: context,
            withComposing: true,
          );
          return const SizedBox();
        },
      ),
    );
    return span;
  }

  testWidgets('subraya el rango que el teclado está componiendo', (
    tester,
  ) async {
    final controller = NoteEditingController()
      ..value = const TextEditingValue(
        text: 'Hola mun\nx',
        selection: TextSelection.collapsed(offset: 8),
        composing: TextRange(start: 5, end: 8),
      );
    final span = await buildSpan(tester, controller);
    expect(span.toPlainText(), 'Hola mun\nx');
    final composing = span.children!.cast<TextSpan>().firstWhere(
      (child) => child.text == 'mun',
    );
    expect(composing.style?.decoration, TextDecoration.underline);
  });

  testWidgets('aplica el formato y oculta las marcas sin perder texto', (
    tester,
  ) async {
    const text = 'uno **dos** fd_tres_';
    final controller = NoteEditingController(text: text);
    final span = await buildSpan(tester, controller);
    // Si no coincide, el cursor del TextField se descuadra
    expect(span.toPlainText(), text);

    final children = span.children!.cast<TextSpan>();
    TextStyle? styleOf(String part) =>
        children.firstWhere((child) => child.text == part).style;
    expect(styleOf('**')?.color, Colors.transparent);
    expect(styleOf('**')?.fontSize, lessThan(1));
    expect(styleOf('dos')?.fontWeight, FontWeight.bold);
    // La cursiva funciona dentro de una palabra
    expect(styleOf('tres')?.fontStyle, FontStyle.italic);
  });

  testWidgets('el tachado ya no es un formato: ~~ se ve tal cual', (
    tester,
  ) async {
    const text = 'uno ~~dos~~';
    final span = await buildSpan(tester, NoteEditingController(text: text));
    expect(span.toPlainText(), text);
    for (final child in span.children!.cast<TextSpan>()) {
      expect(child.style?.decoration, isNot(TextDecoration.lineThrough));
      expect(child.style?.color, isNot(Colors.transparent));
    }
  });

  testWidgets('**_x_** aplica negrita y cursiva', (tester) async {
    final controller = NoteEditingController(text: 'T\n**_ambos_**');
    final span = await buildSpan(tester, controller);
    final children = span.children!.cast<TextSpan>();
    final ambos = children.firstWhere((child) => child.text == 'ambos');
    expect(ambos.style?.fontWeight, FontWeight.bold);
    expect(ambos.style?.fontStyle, FontStyle.italic);
    expect(
      children.where((child) => child.text!.contains(RegExp(r'[*_]'))),
      everyElement(
        isA<TextSpan>().having(
          (child) => child.style?.color,
          'color',
          Colors.transparent,
        ),
      ),
    );
  });

  group('saltar marcas', () {
    NoteEditingController controllerAt(String text, int offset) =>
        NoteEditingController(text: text)
          ..selection = TextSelection.collapsed(offset: offset);

    void moveTo(NoteEditingController controller, int offset) =>
        controller.selection = TextSelection.collapsed(offset: offset);

    test('la flecha a la derecha cruza la marca y avanza una letra', () {
      // T\na**bc**d : la marca de apertura está en 3-4
      final controller = controllerAt('T\na**bc**d', 3);
      moveTo(controller, 4);
      expect(controller.selection.baseOffset, 6); // después de la b
    });

    test('la flecha a la izquierda cruza la marca y retrocede una letra', () {
      // cursor después de la marca de cierre (9), a la izquierda cae dentro
      // de ella: cruza la marca y queda entre la b y la c
      final controller = controllerAt('T\na**bc**d', 9);
      moveTo(controller, 8);
      expect(controller.selection.baseOffset, 6);
    });

    test('un toque dentro de una marca solo la saca de ahí', () {
      final controller = controllerAt('T\na**bc**d', 0);
      moveTo(controller, 4);
      expect(controller.selection.baseOffset, 5);
    });

    test('borrar sobre una marca borra la letra visible anterior', () {
      // cursor al final de "**bc**"; backspace borraría un *
      final controller = controllerAt('T\na**bc**d', 9);
      controller.value = const TextEditingValue(
        text: 'T\na**bc*d',
        selection: TextSelection.collapsed(offset: 8),
      );
      expect(controller.text, 'T\na**b**d');
      expect(controller.selection.baseOffset, 6);
    });

    test('borrar la última letra de una negrita quita las marcas', () {
      final controller = controllerAt('T\na**b**', 8);
      controller.value = const TextEditingValue(
        text: 'T\na**b*',
        selection: TextSelection.collapsed(offset: 7),
      );
      expect(controller.text, 'T\na');
      expect(controller.selection.baseOffset, 3);
    });

    test('borrar justo después de tocar negrita cancela el formato', () {
      final controller = controllerAt('T\na****', 5);
      controller.value = const TextEditingValue(
        text: 'T\na***',
        selection: TextSelection.collapsed(offset: 4),
      );
      expect(controller.text, 'T\na');
      expect(controller.selection.baseOffset, 3);
    });
  });

  group('combinar y quitar formatos con la barra', () {
    Future<List<TextSpan>> render(
      WidgetTester tester,
      NoteEditingController controller,
    ) async => (await buildSpan(tester, controller)).children!.cast<TextSpan>();

    TextStyle? styleOf(List<TextSpan> spans, String word) =>
        spans.firstWhere((span) => span.text == word).style;

    TextStyle? styleContaining(List<TextSpan> spans, String word) =>
        spans.firstWhere((span) => span.text!.contains(word)).style;

    void expectNoVisibleMarkers(List<TextSpan> spans) {
      for (final span in spans) {
        if (span.text!.contains(RegExp(r'[*_]'))) {
          expect(span.style?.color, Colors.transparent, reason: span.text);
        }
      }
    }

    NoteEditingController select(String text, String word) {
      final start = text.indexOf(word);
      return NoteEditingController(text: text)
        ..selection = TextSelection(
          baseOffset: start,
          extentOffset: start + word.length,
        );
    }

    testWidgets('el ejemplo **hola _dssd_ hosad _dasd_ **', (tester) async {
      final controller = NoteEditingController(
        text: 'T\n**hola _dssd_ hosad _dasd_ **',
      );
      final spans = await render(tester, controller);
      expect(styleOf(spans, 'dssd')?.fontWeight, FontWeight.bold);
      expect(styleOf(spans, 'dssd')?.fontStyle, FontStyle.italic);
      expect(styleOf(spans, 'dasd')?.fontStyle, FontStyle.italic);
      expect(styleContaining(spans, 'hola')?.fontWeight, FontWeight.bold);
      expectNoVisibleMarkers(spans);
    });

    const all = MarkdownFormat.values;
    final orders = [
      for (final a in all)
        for (final b in all)
          if (a != b) [a, b],
    ];

    for (final order in orders) {
      testWidgets('poner ${order.map((f) => f.name).join(', ')}', (
        tester,
      ) async {
        final controller = select('T\ntexto', 'texto');
        order.forEach(controller.toggleFormat);
        final spans = await render(tester, controller);
        final style = styleOf(spans, 'texto');
        expect(style?.fontWeight, FontWeight.bold, reason: controller.text);
        expect(style?.fontStyle, FontStyle.italic, reason: controller.text);
        expectNoVisibleMarkers(spans);

        // Quitar uno deja el otro
        for (final removed in all) {
          final copy = NoteEditingController()..value = controller.value;
          copy.toggleFormat(removed);
          final after = await render(tester, copy);
          final afterStyle = styleOf(after, 'texto');
          expect(
            afterStyle?.fontWeight == FontWeight.bold,
            removed != MarkdownFormat.bold,
            reason: 'negrita al quitar ${removed.name}: ${copy.text}',
          );
          expect(
            afterStyle?.fontStyle == FontStyle.italic,
            removed != MarkdownFormat.italic,
            reason: 'cursiva al quitar ${removed.name}: ${copy.text}',
          );
          expectNoVisibleMarkers(after);
        }
      });
    }

    testWidgets('quitar la negrita a una palabra en medio y volver a ponerla', (
      tester,
    ) async {
      final controller = select('T\n**hola dssd hosad**', 'dssd');
      controller.toggleFormat(MarkdownFormat.bold);
      var spans = await render(tester, controller);
      expect(controller.text, 'T\n**hola** dssd **hosad**');
      expect(
        styleContaining(spans, 'dssd')?.fontWeight,
        isNot(FontWeight.bold),
        reason: controller.text,
      );
      expect(styleContaining(spans, 'hola')?.fontWeight, FontWeight.bold);
      expect(styleContaining(spans, 'hosad')?.fontWeight, FontWeight.bold);
      expectNoVisibleMarkers(spans);

      controller.toggleFormat(MarkdownFormat.bold);
      spans = await render(tester, controller);
      expect(
        styleContaining(spans, 'dssd')?.fontWeight,
        FontWeight.bold,
        reason: controller.text,
      );
      expectNoVisibleMarkers(spans);
    });

    testWidgets('quitar la cursiva dentro de una negrita', (tester) async {
      final controller = select('T\n**hola _dssd_ hosad**', 'dssd');
      controller.toggleFormat(MarkdownFormat.italic);
      final spans = await render(tester, controller);
      expect(styleContaining(spans, 'dssd')?.fontWeight, FontWeight.bold);
      expect(
        styleContaining(spans, 'dssd')?.fontStyle,
        isNot(FontStyle.italic),
        reason: controller.text,
      );
      expectNoVisibleMarkers(spans);
    });

    testWidgets('con el cursor dentro de una negrita, lo que se escribe no '
        'sale en negrita', (tester) async {
      final controller = NoteEditingController(text: 'T\n**hola**')
        ..selection = const TextSelection.collapsed(offset: 6); // ho|la
      controller.toggleFormat(MarkdownFormat.bold);
      final caret = controller.selection.baseOffset;
      controller.value = TextEditingValue(
        text: controller.text.replaceRange(caret, caret, 'x'),
        selection: TextSelection.collapsed(offset: caret + 1),
      );
      final spans = await render(tester, controller);
      expect(
        styleOf(spans, 'x')?.fontWeight,
        isNot(FontWeight.bold),
        reason: controller.text,
      );
      expect(styleOf(spans, 'ho')?.fontWeight, FontWeight.bold);
      expect(styleOf(spans, 'la')?.fontWeight, FontWeight.bold);
      expectNoVisibleMarkers(spans);
    });
  });

  group('escribir y tocar botones sin selección', () {
    void type(NoteEditingController controller, String text) {
      for (final char in text.split('')) {
        final caret = controller.selection.baseOffset;
        controller.value = TextEditingValue(
          text: controller.text.replaceRange(caret, caret, char),
          selection: TextSelection.collapsed(offset: caret + 1),
        );
      }
    }

    const all = MarkdownFormat.values;
    final orders = [
      for (final a in all)
        for (final b in all)
          if (a != b) [a, b],
    ];

    for (final order in orders) {
      testWidgets('algo, ${order.map((f) => f.name).join(', ')}, texto', (
        tester,
      ) async {
        final controller = NoteEditingController(text: 'T\nalgo')
          ..selection = const TextSelection.collapsed(offset: 6);
        order.forEach(controller.toggleFormat);
        type(controller, 'texto');

        final spans = (await buildSpan(
          tester,
          controller,
        )).children!.cast<TextSpan>();
        final style = spans
            .firstWhere((span) => span.text!.contains('texto'))
            .style;
        for (final format in all) {
          final expected = order.contains(format);
          final actual = switch (format) {
            MarkdownFormat.bold => style?.fontWeight == FontWeight.bold,
            MarkdownFormat.italic => style?.fontStyle == FontStyle.italic,
          };
          expect(
            actual,
            expected,
            reason: '${format.name}: ${controller.text}',
          );
        }
        for (final span in spans) {
          if (span.text!.contains(RegExp(r'[*_]'))) {
            expect(
              span.style?.color,
              Colors.transparent,
              reason: '${span.text} en ${controller.text}',
            );
          }
        }
      });
    }
  });

  testWidgets('algo, cursiva, texto, negrita, mas', (tester) async {
    final controller = NoteEditingController(text: 'T\nalgo')
      ..selection = const TextSelection.collapsed(offset: 6);
    void type(String text) {
      for (final char in text.split('')) {
        final caret = controller.selection.baseOffset;
        controller.value = TextEditingValue(
          text: controller.text.replaceRange(caret, caret, char),
          selection: TextSelection.collapsed(offset: caret + 1),
        );
      }
    }

    controller.toggleFormat(MarkdownFormat.italic);
    type('texto');
    controller.toggleFormat(MarkdownFormat.bold);
    type('mas');
    final spans = (await buildSpan(
      tester,
      controller,
    )).children!.cast<TextSpan>();
    TextStyle? styleOf(String word) =>
        spans.firstWhere((span) => span.text!.contains(word)).style;
    expect(
      styleOf('texto')?.fontStyle,
      FontStyle.italic,
      reason: controller.text,
    );
    expect(styleOf('texto')?.fontWeight, isNot(FontWeight.bold));
    expect(
      styleOf('mas')?.fontStyle,
      FontStyle.italic,
      reason: controller.text,
    );
    expect(
      styleOf('mas')?.fontWeight,
      FontWeight.bold,
      reason: controller.text,
    );
    for (final span in spans) {
      if (span.text!.contains(RegExp(r'[*_]'))) {
        expect(span.style?.color, Colors.transparent, reason: controller.text);
      }
    }
  });

  group('preview sin marcas', () {
    test('quita las marcas y conserva los estilos', () {
      final span = NoteEditingController.formattedSpan(
        'hola **negrita _ambas_**',
      );
      expect(span.toPlainText(), 'hola negrita ambas');
      final children = span.children!.cast<TextSpan>();
      final ambas = children.firstWhere((child) => child.text == 'ambas');
      expect(ambas.style?.fontWeight, FontWeight.bold);
      expect(ambas.style?.fontStyle, FontStyle.italic);
    });

    test('deja visibles las marcas sin pareja', () {
      final span = NoteEditingController.formattedSpan('**abierto');
      expect(span.toPlainText(), '**abierto');
    });
  });
}
