import 'dart:io';

void main() {
  final locFile = File('lib/core/localization.dart');
  final locContent = locFile.readAsStringSync();

  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).where((f) => f.path.endsWith('.dart') && f is File).cast<File>();

  final regex = RegExp(r"l10n\.translate\('([^']+)'\)");
  final keys = <String>{};

  for (final file in files) {
    final content = file.readAsStringSync();
    for (final match in regex.allMatches(content)) {
      keys.add(match.group(1)!);
    }
  }

  for (final key in keys) {
    if (!locContent.contains("'$key':")) {
      print('Missing key: $key');
    }
  }
}
