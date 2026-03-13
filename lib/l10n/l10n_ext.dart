import 'package:flutter/widgets.dart';
import 'package:aethera/l10n/gen/app_localizations.dart';

extension BuildContextL10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  bool get _isSpanish => l10n.localeName.toLowerCase().startsWith('es');

  String tr(String es, String en) {
    return _isSpanish ? es : en;
  }
}
