// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Aethera';

  @override
  String get startupErrorTitle => 'Aethera could not start';

  @override
  String get startupErrorMessage => 'Check your Firebase configuration and try again.';
}
