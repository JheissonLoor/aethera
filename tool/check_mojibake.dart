import 'dart:convert';
import 'dart:io';

const List<String> _patronesMojibake = <String>[
  'Ã¡',
  'Ã©',
  'Ã­',
  'Ã³',
  'Ãº',
  'Ã±',
  'Â¿',
  'Â¡',
  'â€”',
  'â€“',
  'â€œ',
  'â€',
  'â€™',
  'â€¢',
  'ï»¿',
];

const Set<String> _extensiones = <String>{
  '.dart',
  '.md',
  '.yaml',
  '.yml',
  '.json',
  '.arb',
};

const List<String> _prefijosIgnorados = <String>[
  'build/',
  '.dart_tool/',
  'firebase/rules/node_modules/',
];

void main() {
  final ProcessResult lsFiles = Process.runSync(
    'git',
    <String>['ls-files'],
    runInShell: true,
  );

  if (lsFiles.exitCode != 0) {
    stderr.writeln(
      'No se pudo listar archivos versionados con git: ${lsFiles.stderr}',
    );
    exit(2);
  }

  final List<String> archivos = LineSplitter.split(
    (lsFiles.stdout as String?) ?? '',
  ).where((String path) => path.trim().isNotEmpty).toList(growable: false);

  final List<String> errores = <String>[];

  for (final String path in archivos) {
    if (_debeIgnorarse(path) || !_extensionPermitida(path)) {
      continue;
    }

    final File file = File(path);
    if (!file.existsSync()) {
      continue;
    }

    final List<int> bytes = file.readAsBytesSync();

    if (_tieneBomUtf8(bytes)) {
      errores.add('$path:1: Archivo con BOM UTF-8 (no permitido).');
    }

    String contenido;
    try {
      contenido = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      errores.add('$path:1: Archivo no es UTF-8 valido.');
      continue;
    }

    final List<String> lineas = const LineSplitter().convert(contenido);
    for (int i = 0; i < lineas.length; i++) {
      final String linea = lineas[i];
      for (final String patron in _patronesMojibake) {
        if (linea.contains(patron)) {
          final String vista = linea.trim();
          errores.add('$path:${i + 1}: Patrón "$patron" detectado -> $vista');
        }
      }
    }
  }

  if (errores.isNotEmpty) {
    stderr.writeln('Se detectaron problemas de encoding/mojibake:');
    for (final String error in errores) {
      stderr.writeln('- $error');
    }
    exit(1);
  }

  stdout.writeln('Check encoding/mojibake OK.');
}

bool _debeIgnorarse(String path) {
  for (final String prefijo in _prefijosIgnorados) {
    if (path.startsWith(prefijo)) {
      return true;
    }
  }
  return false;
}

bool _extensionPermitida(String path) {
  for (final String ext in _extensiones) {
    if (path.endsWith(ext)) {
      return true;
    }
  }
  return false;
}

bool _tieneBomUtf8(List<int> bytes) {
  return bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF;
}
