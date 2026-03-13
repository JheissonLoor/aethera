import 'dart:io';

void main(List<String> args) {
  final String lcovPath = _leerArg(args, '--lcov') ?? 'coverage/lcov.info';
  final double minCoverage = double.tryParse(
        _leerArg(args, '--min') ??
            Platform.environment['MIN_COVERAGE'] ??
            '15',
      ) ??
      15;
  final List<String> includeFilters = _leerListaArg(args, '--include');
  final List<String> excludeFilters = _leerListaArg(args, '--exclude');

  final File lcovFile = File(lcovPath);
  if (!lcovFile.existsSync()) {
    stderr.writeln('No existe archivo de cobertura: $lcovPath');
    exit(2);
  }

  int totalLineas = 0;
  int lineasCubiertas = 0;
  String archivoActual = '';
  bool contarArchivoActual = true;

  for (final String linea in lcovFile.readAsLinesSync()) {
    if (linea.startsWith('SF:')) {
      archivoActual = linea.substring(3).replaceAll('\\', '/');
      contarArchivoActual = _debeContarArchivo(
        archivoActual,
        includeFilters: includeFilters,
        excludeFilters: excludeFilters,
      );
      continue;
    }

    if (!contarArchivoActual) {
      continue;
    }

    if (!linea.startsWith('DA:')) {
      continue;
    }

    final List<String> partes = linea.substring(3).split(',');
    if (partes.length != 2) {
      continue;
    }

    final int hits = int.tryParse(partes[1]) ?? 0;
    totalLineas += 1;
    if (hits > 0) {
      lineasCubiertas += 1;
    }
  }

  if (totalLineas == 0) {
    stderr.writeln(
      'No se encontraron entradas DA para los filtros en $lcovPath',
    );
    exit(2);
  }

  final double coverage = (lineasCubiertas * 100.0) / totalLineas;
  final String coverageTxt = coverage.toStringAsFixed(2);
  final String minTxt = minCoverage.toStringAsFixed(2);

  stdout.writeln(
    'Cobertura total: $coverageTxt% ($lineasCubiertas/$totalLineas). Minimo requerido: $minTxt%',
  );

  if (coverage + 1e-9 < minCoverage) {
    stderr.writeln(
      'Cobertura insuficiente: $coverageTxt% < $minTxt%',
    );
    exit(1);
  }

  stdout.writeln('Check de cobertura minima OK.');
}

String? _leerArg(List<String> args, String key) {
  for (int i = 0; i < args.length; i++) {
    final String arg = args[i];
    if (arg == key && i + 1 < args.length) {
      return args[i + 1];
    }
    if (arg.startsWith('$key=')) {
      return arg.substring('$key='.length);
    }
  }
  return null;
}

List<String> _leerListaArg(List<String> args, String key) {
  final String? valor = _leerArg(args, key);
  if (valor == null || valor.trim().isEmpty) {
    return <String>[];
  }
  return valor
      .split(',')
      .map((item) => item.trim().replaceAll('\\', '/'))
      .where((item) => item.isNotEmpty)
      .toList();
}

bool _debeContarArchivo(
  String path, {
  required List<String> includeFilters,
  required List<String> excludeFilters,
}) {
  if (includeFilters.isNotEmpty &&
      !includeFilters.any((filtro) => path.contains(filtro))) {
    return false;
  }

  if (excludeFilters.any((filtro) => path.contains(filtro))) {
    return false;
  }

  return true;
}
