import 'package:flutter_test/flutter_test.dart';
import 'package:aethera/core/services/telemetry_service.dart';

class _LoggedEvent {
  final String name;
  final Map<String, Object> params;

  _LoggedEvent(this.name, this.params);
}

class _FakeTelemetrySink implements TelemetrySink {
  int initializeCalls = 0;
  int setEnabledCalls = 0;
  bool? enabledValue;
  String? userId;
  final Map<String, String?> userProperties = <String, String?>{};
  final List<_LoggedEvent> events = <_LoggedEvent>[];

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    setEnabledCalls++;
    enabledValue = enabled;
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object> parameters = const <String, Object>{},
  }) async {
    events.add(_LoggedEvent(name, parameters));
  }

  @override
  Future<void> setUserId(String? userId) async {
    this.userId = userId;
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    userProperties[name] = value;
  }
}

void main() {
  group('AppTelemetryService', () {
    test('normaliza nombre/parametros de evento', () async {
      final sink = _FakeTelemetrySink();
      final service = AppTelemetryService(
        sink: sink,
        nonFatalRecorder: (_, __, {String? reason}) async {},
      );

      await service.initialize();
      await service.logEvent(
        'Evento Premium!',
        parameters: {
          'Accion Tipo': 'crear_memoria',
          'isOk': true,
          'vacio': '   ',
          'numero': 7,
        },
      );

      expect(sink.events, isNotEmpty);
      final last = sink.events.last;
      expect(last.name, 'evento_premium');
      expect(last.params['accion_tipo'], 'crear_memoria');
      expect(last.params['isok'], 1);
      expect(last.params['numero'], 7);
      expect(last.params.containsKey('vacio'), isFalse);
    });

    test('recordNonFatal registra crash y evento', () async {
      final sink = _FakeTelemetrySink();
      var recorderCalls = 0;
      String? recorderReason;

      final service = AppTelemetryService(
        sink: sink,
        nonFatalRecorder: (error, stackTrace, {String? reason}) async {
          recorderCalls++;
          recorderReason = reason;
        },
      );

      await service.initialize();
      await service.recordNonFatal(
        reason: 'sync_queue_action_failed',
        error: StateError('fallo'),
        stackTrace: StackTrace.current,
        context: {'action_type': 'sendWish'},
      );

      expect(recorderCalls, 1);
      expect(recorderReason, 'sync_queue_action_failed');
      final last = sink.events.last;
      expect(last.name, 'non_fatal_error');
      expect(last.params['reason'], 'sync_queue_action_failed');
      expect(last.params['action_type'], 'sendWish');
    });

    test('cuando esta deshabilitado no envia eventos', () async {
      final sink = _FakeTelemetrySink();
      final service = AppTelemetryService(
        sink: sink,
        nonFatalRecorder: (_, __, {String? reason}) async {},
      );

      await service.initialize(enabled: false);
      await service.logEvent('evento_prueba');

      expect(sink.initializeCalls, 0);
      expect(sink.events, isEmpty);
    });
  });
}
