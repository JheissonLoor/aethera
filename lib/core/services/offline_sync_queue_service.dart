import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineSyncAction {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final int createdAtMs;

  const OfflineSyncAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAtMs,
  });

  factory OfflineSyncAction.fromMap(Map<String, dynamic> map) {
    final rawPayload = map['payload'];
    final payload = <String, dynamic>{};
    if (rawPayload is Map) {
      for (final entry in rawPayload.entries) {
        final key = entry.key?.toString();
        if (key != null && key.isNotEmpty) {
          payload[key] = entry.value;
        }
      }
    }

    return OfflineSyncAction(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      payload: payload,
      createdAtMs: map['createdAtMs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'payload': payload,
    'createdAtMs': createdAtMs,
  };
}

class OfflineSyncQueueService {
  static const String _storageKey = 'offline_sync_queue_v1';

  Future<List<OfflineSyncAction>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const <OfflineSyncAction>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <OfflineSyncAction>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                OfflineSyncAction.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } catch (_) {
      return const <OfflineSyncAction>[];
    }
  }

  Future<void> enqueue(OfflineSyncAction action) async {
    final actions = (await load()).toList();
    actions.add(action);
    await _save(actions);
  }

  Future<void> removeByIds(Set<String> ids) async {
    if (ids.isEmpty) return;
    final actions = await load();
    final filtered = actions
        .where((action) => !ids.contains(action.id))
        .toList(growable: false);
    await _save(filtered);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<int> count() async => (await load()).length;

  Future<void> _save(List<OfflineSyncAction> actions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      actions.map((action) => action.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }
}
