import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Singleton that manages ambient background music throughout the app.
///
/// Usage:
///   await MusicService.instance.initialize();
///   MusicService.instance.play();
///   MusicService.instance.setMuted(true);
///   MusicService.instance.onEmotionChanged('love');
class MusicService with WidgetsBindingObserver {
  MusicService._();
  static final instance = MusicService._();

  final _player = AudioPlayer();
  bool _isMuted = false;
  bool _isPlaying = false;
  bool _initialized = false;
  bool _audioAvailable = true;
  double _currentVolume = 0.22;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await _player.setReleaseMode(ReleaseMode.loop);
  }

  // ── Playback control ──────────────────────────────────────────────────────

  Future<void> play() async {
    if (!_audioAvailable || _isMuted) return;
    try {
      await _player.setVolume(0.0);
      await _player.play(AssetSource('audio/ambient.mp3'));
      _isPlaying = true;
      // Fade in over 2 seconds
      _fadeVolumeTo(_currentVolume, duration: const Duration(seconds: 2));
    } catch (_) {
      // Audio file not found or unsupported — silently disable music
      _audioAvailable = false;
      _isPlaying = false;
    }
  }

  Future<void> pause() async {
    if (!_isPlaying) return;
    _fadeVolumeTo(0.0, duration: const Duration(milliseconds: 800));
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    if (_isMuted || !_audioAvailable) return;
    try {
      await _player.resume();
      _isPlaying = true;
      _fadeVolumeTo(_currentVolume, duration: const Duration(milliseconds: 800));
    } catch (_) {}
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _player.stop();
  }

  // ── Mute toggle ───────────────────────────────────────────────────────────

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    if (muted) {
      _fadeVolumeTo(0.0, duration: const Duration(milliseconds: 500));
    } else {
      if (!_isPlaying) {
        await play();
      } else {
        _fadeVolumeTo(_currentVolume, duration: const Duration(milliseconds: 500));
      }
    }
  }

  bool get isMuted => _isMuted;
  bool get isAvailable => _audioAvailable;

  // ── Emotion-based volume ──────────────────────────────────────────────────

  /// Adjusts volume subtly based on the combined emotion.
  void onEmotionChanged(String mood) {
    _currentVolume = _volumeForMood(mood);
    if (!_isMuted && _isPlaying) {
      _fadeVolumeTo(_currentVolume, duration: const Duration(seconds: 1));
    }
  }

  double _volumeForMood(String mood) {
    switch (mood) {
      case 'joy':        return 0.32;
      case 'love':       return 0.30;
      case 'peace':      return 0.18;
      case 'longing':    return 0.24;
      case 'melancholy': return 0.16;
      case 'anxious':    return 0.12;
      default:           return 0.22;
    }
  }

  // ── Volume fade helper ────────────────────────────────────────────────────

  void _fadeVolumeTo(double target, {required Duration duration}) {
    if (!_isPlaying && target > 0) return;
    _player.setVolume(target);
  }

  // ── App lifecycle ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _player.pause();
        break;
      case AppLifecycleState.resumed:
        if (!_isMuted && _isPlaying && _audioAvailable) {
          _player.resume();
          _player.setVolume(_currentVolume);
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void disposeService() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
  }
}
