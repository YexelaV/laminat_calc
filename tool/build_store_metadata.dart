// Lays the listing out of store/ into the folder tree `fastlane supply` reads.
//
//   dart run tool/build_store_metadata.dart
//
// store/ stays the place the texts are written and the screenshots are shot
// into; this only rearranges them and checks them against Play's limits before
// anything reaches the network.
//
// The feature graphic and the icon are deliberately not written: supply fills a
// listing with what Play already holds and overwrites only the fields it finds
// a file for, so leaving them out keeps the live ones untouched. The title
// works the same way and is optional here — write store/<locale>/title.txt only
// to change a title, or to give a locale Play does not carry yet one at all,
// since a listing Play has never seen starts out empty and it will not take an
// empty title.

import 'dart:io';

/// `store/<key>` to the code Google Play knows the locale by. Read off a
/// `fastlane supply init` of the live listing, so Portuguese is Brazilian and
/// English is American — those are the listings that exist, and a different
/// code would quietly create a second one.
const _playLocales = <String, String>{
  'bg': 'bg', // Bulgarian has no region on Play
  'cs': 'cs-CZ',
  'de': 'de-DE',
  'en': 'en-US',
  'es': 'es-ES',
  'fr': 'fr-FR',
  'it': 'it-IT',
  'pl': 'pl-PL',
  // Two Portuguese listings, each with its own text: store/pt is European
  // ("cômodo" spelled "cómodo", enclitic pronouns), store/pt_BR is Brazilian.
  'pt': 'pt-PT',
  'pt_BR': 'pt-BR',
  'ru': 'ru-RU',
  'sv': 'sv-SE',
  'tr': 'tr-TR',
};

/// Where a listing takes its screenshots from, when not from its own folder.
/// test/store_screenshots_test.dart shoots one set per locale the app ships in,
/// and Portuguese is one locale there — so the Brazilian listing, which has
/// only text of its own, borrows the pictures.
const _screenshotsFrom = <String, String>{'pt_BR': 'pt'};

const _shortHeader = 'SHORT DESCRIPTION (max 80)';
const _fullHeader = 'FULL DESCRIPTION (max 4000)';

const _maxTitle = 30;
const _maxShort = 80;
const _maxFull = 4000;
const _maxChangelog = 500;

/// Play takes eight phone screenshots at most; the listing shows five, because
/// the first two or three are what decides the install and the rest are only
/// read by someone already persuaded. The order is
/// test/store_screenshots_test.dart's, and the numbers in these names are what
/// puts them in it — supply uploads in alphabetical order.
const _screenshotCount = 5;

const _screenshotNames = <String>[
  '01_room',
  '02_scheme',
  '03_cut_list',
  '04_laminate',
  '05_laying',
];

final List<String> _problems = <String>[];

void main() {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run this from the repository root: pubspec.yaml is not here.');
    exit(1);
  }

  final version = _readVersion('${root.path}/pubspec.yaml');
  final versionName = version[0];
  final versionCode = version[1];

  final out = Directory('${root.path}/fastlane/metadata/android');
  if (out.existsSync()) out.deleteSync(recursive: true);
  out.createSync(recursive: true);

  final rows = <List<String>>[];
  final locales = _playLocales.keys.toList()..sort();

  for (final locale in locales) {
    final playLocale = _playLocales[locale]!;
    final from = Directory('${root.path}/store/$locale');
    if (!from.existsSync()) {
      _problems.add('store/$locale/ is missing');
      continue;
    }

    final short = _listingSection(from.path, _shortHeader, _fullHeader);
    final full = _listingSection(from.path, _fullHeader, null);
    final changelog = _changelog(from.path, versionName);
    final title = _title(from.path);

    _checkLength('store/$locale/listing.txt short description', short, _maxShort);
    _checkLength('store/$locale/listing.txt full description', full, _maxFull);
    _checkLength('store/$locale/whatsnew.txt', changelog, _maxChangelog);
    _checkLength('store/$locale/title.txt', title, _maxTitle);

    final to = Directory('${out.path}/$playLocale')..createSync(recursive: true);
    if (title.isNotEmpty) _write('${to.path}/title.txt', title);
    _write('${to.path}/short_description.txt', short);
    _write('${to.path}/full_description.txt', full);
    Directory('${to.path}/changelogs').createSync();
    _write('${to.path}/changelogs/$versionCode.txt', changelog);

    final shotsLocale = _screenshotsFrom[locale] ?? locale;
    final shotsDir = '${root.path}/store/$shotsLocale';
    final shots = Directory('${to.path}/images/phoneScreenshots')
      ..createSync(recursive: true);
    var copied = 0;
    for (final name in _screenshotNames) {
      final png = File('$shotsDir/$name.png');
      if (!png.existsSync()) {
        _problems.add('store/$shotsLocale/$name.png is missing');
        continue;
      }
      // supply uploads screenshots in alphabetical order, which the numbered
      // prefixes already give us.
      png.copySync('${shots.path}/$name.png');
      copied++;
    }
    if (copied != _screenshotCount) {
      _problems.add(
          'store/$shotsLocale/ has $copied screenshots, Play wants $_screenshotCount');
    }

    rows.add(<String>[
      locale,
      playLocale,
      title.isEmpty ? 'kept' : '${title.length}/$_maxTitle',
      '${short.length}/$_maxShort',
      '${full.length}/$_maxFull',
      '${changelog.length}/$_maxChangelog',
      '$copied',
    ]);
  }

  _printTable(rows);
  stdout.writeln('');
  stdout.writeln('Version $versionName, changelogs written as $versionCode.txt');
  stdout.writeln('Written to fastlane/metadata/android/');

  if (_problems.isNotEmpty) {
    stderr.writeln('');
    for (final problem in _problems) {
      stderr.writeln('  $problem');
    }
    stderr.writeln('');
    stderr.writeln('${_problems.length} problem(s); nothing was uploaded.');
    exit(1);
  }
}

/// The name and the build number out of `version: 1.11.1+21`. The build number
/// is what Play calls the versionCode, and the name is what whatsnew.txt is
/// checked against.
List<String> _readVersion(String pubspecPath) {
  for (final line in File(pubspecPath).readAsLinesSync()) {
    if (!line.startsWith('version:')) continue;
    final value = line.substring('version:'.length).trim();
    final plus = value.indexOf('+');
    if (plus < 0) {
      stderr.writeln('pubspec.yaml: "$value" has no build number after a "+".');
      exit(1);
    }
    return <String>[value.substring(0, plus), value.substring(plus + 1)];
  }
  stderr.writeln('pubspec.yaml has no version: line.');
  exit(1);
}

/// The text between two of listing.txt's ALL-CAPS headers, or from one header
/// to the end of the file when [until] is null.
String _listingSection(String localeDir, String from, String? until) {
  final path = '$localeDir/listing.txt';
  final file = File(path);
  if (!file.existsSync()) {
    _problems.add('${_short(path)} is missing');
    return '';
  }

  final lines = file.readAsLinesSync();
  final start = lines.indexOf(from);
  if (start < 0) {
    _problems.add('${_short(path)} has no "$from" line');
    return '';
  }

  var end = lines.length;
  if (until != null) {
    end = lines.indexOf(until);
    if (end < 0) {
      _problems.add('${_short(path)} has no "$until" line');
      return '';
    }
  }

  final text = lines.sublist(start + 1, end).join('\n').trim();
  if (text.isEmpty) _problems.add('${_short(path)}: "$from" is followed by nothing');
  return text;
}

/// whatsnew.txt without its header line. The header carries the version, so a
/// mismatch here is a whatsnew that was not rewritten for this release.
String _changelog(String localeDir, String versionName) {
  final path = '$localeDir/whatsnew.txt';
  final file = File(path);
  if (!file.existsSync()) {
    _problems.add('${_short(path)} is missing');
    return '';
  }

  final lines = file.readAsLinesSync();
  final expected = 'RELEASE NOTES $versionName (max $_maxChangelog)';
  if (lines.isEmpty || lines.first.trim() != expected) {
    final found = lines.isEmpty ? '(empty file)' : lines.first.trim();
    _problems.add('${_short(path)}: first line is "$found", expected "$expected"');
    return '';
  }

  final text = lines.sublist(1).join('\n').trim();
  if (text.isEmpty) _problems.add('${_short(path)} has a header and nothing else');
  return text;
}

/// The title, if this locale has one written for it. Empty means "leave the one
/// on Play alone", which is what every locale Play already carries wants.
String _title(String localeDir) {
  final file = File('$localeDir/title.txt');
  if (!file.existsSync()) return '';

  final text = file.readAsStringSync().trim();
  if (text.isEmpty) _problems.add('${_short(file.path)} is empty');
  return text;
}

void _checkLength(String what, String text, int max) {
  if (text.length > max) {
    _problems.add('$what is ${text.length} characters, Play allows $max');
  }
}

/// Written without a trailing newline: supply sends the file verbatim, so the
/// bytes on disk are the field value and nothing else.
void _write(String path, String text) {
  File(path).writeAsStringSync(text);
}

String _short(String path) =>
    path.replaceFirst('${Directory.current.path}/', '');

void _printTable(List<List<String>> rows) {
  const headers = <String>[
    'store',
    'play',
    'title',
    'short',
    'full',
    'whatsnew',
    'shots',
  ];
  final widths = List<int>.generate(headers.length, (i) => headers[i].length);
  for (final row in rows) {
    for (var i = 0; i < row.length; i++) {
      if (row[i].length > widths[i]) widths[i] = row[i].length;
    }
  }

  String line(List<String> cells) {
    final padded = <String>[];
    for (var i = 0; i < cells.length; i++) {
      padded.add(cells[i].padRight(widths[i]));
    }
    return '  ${padded.join('  ')}'.trimRight();
  }

  stdout.writeln(line(headers));
  stdout.writeln(line(widths.map((w) => '-' * w).toList()));
  for (final row in rows) {
    stdout.writeln(line(row));
  }
}
