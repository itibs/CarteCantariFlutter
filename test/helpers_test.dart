import 'package:ccc_flutter/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getSearchable', () {
    test('lowercases input', () {
      expect(getSearchable('Slava Domnului'), 'slava domnului');
    });

    test('normalizes Romanian diacritics', () {
      expect(getSearchable('ăâîÎțţșş'), 'aaiittss');
    });

    test('replaces non-alphanumeric characters with spaces', () {
      expect(getSearchable('hello-world!'), 'hello world');
    });

    test('keeps digits', () {
      expect(getSearchable('Psalmul 23'), 'psalmul 23');
    });

    test('collapses multiple spaces into one', () {
      expect(getSearchable('a    b'), 'a b');
    });

    test('trims leading and trailing whitespace', () {
      expect(getSearchable('  hi  '), 'hi');
    });

    test('combines all rules for a realistic title', () {
      expect(
        getSearchable('Cântă, Inimă, Cântă!'),
        'canta inima canta',
      );
    });

    test('empty string stays empty', () {
      expect(getSearchable(''), '');
    });
  });

  group('createRichText', () {
    const baseStyle = TextStyle(fontSize: 12);
    final boldStyle = const TextStyle(fontWeight: FontWeight.bold);

    List<TextSpan> childrenOf(RichText richText) {
      final root = richText.text as TextSpan;
      return (root.children ?? const <InlineSpan>[]).cast<TextSpan>();
    }

    test('returns a single plain span when no patterns match', () {
      final richText = createRichText('plain text', baseStyle, {});
      final children = childrenOf(richText);

      expect(children.length, 1);
      expect(children.first.text, 'plain text');
      expect(children.first.style, isNull);
    });

    test('applies the matching style to matched tokens', () {
      final richText = createRichText(
        'hello WORLD hello',
        baseStyle,
        {r'WORLD': boldStyle},
      );
      final children = childrenOf(richText);

      final boldSpans =
          children.where((s) => s.style == boldStyle).toList();
      expect(boldSpans.length, 1);
      expect(boldSpans.first.text, 'WORLD');

      final reconstructed = children.map((s) => s.text).join();
      expect(reconstructed, 'hello WORLD hello');
    });

    test('root span carries the base style', () {
      final richText = createRichText('abc', baseStyle, {});
      final root = richText.text as TextSpan;
      expect(root.style, baseStyle);
    });
  });
}
