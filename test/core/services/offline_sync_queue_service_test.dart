import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aethera/core/services/offline_sync_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineSyncQueueService', () {
    late OfflineSyncQueueService service;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      service = OfflineSyncQueueService();
    });

    test('enqueue agrega acciones y count refleja el total', () async {
      await service.enqueue(
        const OfflineSyncAction(
          id: 'a1',
          type: 'updateEmotion',
          payload: {'mood': 'love'},
          createdAtMs: 1,
        ),
      );
      await service.enqueue(
        const OfflineSyncAction(
          id: 'a2',
          type: 'sendWish',
          payload: {'message': 'hola'},
          createdAtMs: 2,
        ),
      );

      final actions = await service.load();
      expect(actions.map((e) => e.id), <String>['a1', 'a2']);
      expect(await service.count(), 2);
    });

    test('removeByIds elimina solo los ids solicitados', () async {
      await service.enqueue(
        const OfflineSyncAction(
          id: 'a1',
          type: 'updateEmotion',
          payload: {'mood': 'peace'},
          createdAtMs: 1,
        ),
      );
      await service.enqueue(
        const OfflineSyncAction(
          id: 'a2',
          type: 'sendPulse',
          payload: {'ok': true},
          createdAtMs: 2,
        ),
      );

      await service.removeByIds(<String>{'a1'});
      final actions = await service.load();

      expect(actions.length, 1);
      expect(actions.first.id, 'a2');
    });

    test('clear vacia la cola completa', () async {
      await service.enqueue(
        const OfflineSyncAction(
          id: 'a1',
          type: 'addMemory',
          payload: {'title': 'x'},
          createdAtMs: 1,
        ),
      );

      await service.clear();

      expect(await service.load(), isEmpty);
      expect(await service.count(), 0);
    });

    test('cuando la cola supera el limite elimina las mas antiguas', () async {
      final bounded = OfflineSyncQueueService(maxQueueSize: 2);

      final r1 = await bounded.enqueue(
        const OfflineSyncAction(
          id: 'a1',
          type: 'updateEmotion',
          payload: {'mood': 'love'},
          createdAtMs: 1,
        ),
      );
      final r2 = await bounded.enqueue(
        const OfflineSyncAction(
          id: 'a2',
          type: 'sendWish',
          payload: {'message': 'hola'},
          createdAtMs: 2,
        ),
      );
      final r3 = await bounded.enqueue(
        const OfflineSyncAction(
          id: 'a3',
          type: 'sendPulse',
          payload: {'ok': true},
          createdAtMs: 3,
        ),
      );

      expect(r1.droppedCount, 0);
      expect(r2.droppedCount, 0);
      expect(r3.droppedCount, 1);
      expect(r3.queueSize, 2);

      final actions = await bounded.load();
      expect(actions.map((e) => e.id), <String>['a2', 'a3']);
    });
  });
}
