// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Aethera';

  @override
  String get startupErrorTitle => 'No se pudo iniciar Aethera';

  @override
  String get startupErrorMessage => 'Verifica la configuracion de Firebase e intentalo de nuevo.';
}
