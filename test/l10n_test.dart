// Checks on the .arb files themselves. These run without Flutter — they read
// lib/l10n from disk — so they catch a bad translation before it ever reaches a
// widget test.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const templateLocale = 'ru';

// Plural categories each locale's `panels` message must define, per CLDR.
// Getting these wrong is silent: gen-l10n falls back to `other`, so a Polish
// user would read '5 panele' instead of '5 paneli' with nothing failing.
const pluralCategories = {
  'ru': {'one', 'few', 'many', 'other'},
  'pl': {'one', 'few', 'many', 'other'},
  'en': {'one', 'other'},
  'de': {'one', 'other'},
  'es': {'one', 'other'},
  'fr': {'one', 'other'},
  'it': {'one', 'other'},
  'pt': {'one', 'other'},
  'tr': {'one', 'other'},
  'zh': {'other'},
};

final cyrillic = RegExp(r'[Ѐ-ӿ]');
final pluralCategory = RegExp(r'(?:^|[\s,])(zero|one|two|few|many|other)\s*\{');

Map<String, String> messagesOf(String locale) {
  final json =
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in json.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

void main() {
  final locales = Directory('lib/l10n')
      .listSync()
      .map((f) => RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)?.group(1))
      .whereType<String>()
      .toList()
    ..sort();

  test('every locale in pluralCategories has a file and vice versa', () {
    expect(locales.toSet(), pluralCategories.keys.toSet());
  });

  test('every locale defines exactly the template keys', () {
    final expected = messagesOf(templateLocale).keys.toSet();
    for (final locale in locales) {
      expect(messagesOf(locale).keys.toSet(), expected, reason: 'app_$locale.arb');
    }
  });

  test('no message is left as the untranslated template text', () {
    final template = messagesOf(templateLocale);
    for (final locale in locales.where((l) => l != templateLocale)) {
      final messages = messagesOf(locale);
      // 'mm' is genuinely 'mm' in the Latin-script locales, so only flag a
      // match that still carries Russian letters.
      final copied = messages.entries
          .where((e) => e.value == template[e.key] && cyrillic.hasMatch(e.value))
          .map((e) => e.key);
      expect(copied, isEmpty, reason: 'app_$locale.arb still holds the Russian text');
    }
  });

  test('latin-script locales contain no Cyrillic', () {
    for (final locale in locales.where((l) => l != 'ru' && l != 'zh')) {
      for (final entry in messagesOf(locale).entries) {
        expect(cyrillic.hasMatch(entry.value), isFalse,
            reason: 'app_$locale.arb: "${entry.key}" mixes Cyrillic into Latin script');
      }
    }
  });

  test('panels declares the CLDR plural categories of its locale', () {
    for (final locale in locales) {
      final message = messagesOf(locale)['panels']!;
      final found = pluralCategory.allMatches(message).map((m) => m.group(1)).toSet();
      expect(found, pluralCategories[locale], reason: 'app_$locale.arb: $message');
    }
  });

  // Validators.sizeValidator decides "integer only" by comparing the unit label
  // against mm and pcs, so a locale where the inch or foot label collides with
  // either of them would reject decimal inches.
  test('unit labels are distinct within a locale', () {
    for (final locale in locales) {
      final messages = messagesOf(locale);
      final units = ['mm', 'pcs', 'ft', 'inch'].map((k) => messages[k]!).toList();
      expect(units.toSet(), hasLength(units.length), reason: 'app_$locale.arb: $units');
    }
  });
}
