import 'package:ccc_flutter/widgets/song_screen/text_body/formatted_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 14);
  const boldStyle = TextStyle(fontWeight: FontWeight.bold);

  List<TextSpan> childrenOf(TextSpan span) =>
      (span.children ?? const <InlineSpan>[]).cast<TextSpan>();

  test('root span carries the base style', () {
    final span = getFormattedTextSpan('plain', baseStyle, {});
    expect(span.style, baseStyle);
  });

  test('returns a single plain child when nothing matches', () {
    final span = getFormattedTextSpan('plain text', baseStyle, {});
    final children = childrenOf(span);

    expect(children.length, 1);
    expect(children.first.text, 'plain text');
    expect(children.first.style, isNull);
  });

  test('styles matched tokens and strips the internal marker', () {
    final span = getFormattedTextSpan(
      'sing LOUD now',
      baseStyle,
      {r'LOUD': boldStyle},
    );
    final children = childrenOf(span);

    final styled = children.where((s) => s.style == boldStyle).toList();
    expect(styled.length, 1);
    expect(styled.first.text, 'LOUD');

    final reconstructed = children.map((s) => s.text).join();
    expect(reconstructed, 'sing LOUD now');
  });

  test('applies multiple distinct styles', () {
    const italicStyle = TextStyle(fontStyle: FontStyle.italic);
    final span = getFormattedTextSpan(
      'A B C',
      baseStyle,
      {r'A': boldStyle, r'C': italicStyle},
    );
    final children = childrenOf(span);

    expect(children.any((s) => s.text == 'A' && s.style == boldStyle), isTrue);
    expect(children.any((s) => s.text == 'C' && s.style == italicStyle), isTrue);
  });
}
