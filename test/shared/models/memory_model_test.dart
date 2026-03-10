import 'package:aethera/shared/models/memory_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryModel', () {
    test('toMap/fromMap preserves createdByUserId', () {
      final model = MemoryModel(
        id: 'memory_1',
        coupleId: 'couple_1',
        type: 'tree',
        title: 'Carta',
        description: 'Carta escrita a mano',
        createdByUserId: 'user_1',
        createdAt: DateTime(2026, 3, 10),
        posX: 0.2,
        posY: 0.7,
      );

      final map = model.toMap();
      final restored = MemoryModel.fromMap(model.id, map);

      expect(map['createdByUserId'], 'user_1');
      expect(restored.createdByUserId, 'user_1');
      expect(restored.title, 'Carta');
      expect(restored.type, 'tree');
    });

    test('fromMap applies defaults for optional fields', () {
      final restored = MemoryModel.fromMap('memory_2', {
        'coupleId': 'couple_1',
      });

      expect(restored.type, 'constellation');
      expect(restored.title, '');
      expect(restored.description, '');
      expect(restored.createdByUserId, isNull);
      expect(restored.posX, 0.5);
      expect(restored.posY, 0.5);
    });
  });
}
