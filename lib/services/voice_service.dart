import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Voice recording configuration
class VoiceRecordingConfig {
  static const int maxDurationSeconds = 60; // 1 minute max
  static const int sampleRate = 44100;
  static const int bitRate = 128000;
  static const AudioEncoder encoder = AudioEncoder.aacLc;
  static const String fileExtension = 'm4a';
}

/// State of voice recording
enum VoiceRecordingState {
  idle,
  recording,
  paused,
  stopped,
}

/// Voice recording result
class VoiceRecordingResult {
  final String filePath;
  final int durationSeconds;
  final int fileSizeBytes;

  const VoiceRecordingResult({
    required this.filePath,
    required this.durationSeconds,
    required this.fileSizeBytes,
  });

  XFile toXFile() => XFile(filePath);
}

/// Service for recording voice messages
class VoiceRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  static const _uuid = Uuid();

  VoiceRecordingState _state = VoiceRecordingState.idle;
  String? _currentRecordingPath;
  Timer? _durationTimer;
  int _currentDurationSeconds = 0;

  // Stream controllers
  final _stateController = StreamController<VoiceRecordingState>.broadcast();
  final _durationController = StreamController<int>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();

  // Public getters
  VoiceRecordingState get state => _state;
  bool get isRecording => _state == VoiceRecordingState.recording;
  bool get isPaused => _state == VoiceRecordingState.paused;
  int get currentDurationSeconds => _currentDurationSeconds;

  // Streams
  Stream<VoiceRecordingState> get stateStream => _stateController.stream;
  Stream<int> get durationStream => _durationController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Check if recording is permitted
  Future<bool> hasPermission() async {
    if (kIsWeb) {
      return false; // Web recording not supported yet
    }
    return await _recorder.hasPermission();
  }

  /// Start recording voice
  Future<bool> startRecording() async {
    if (_state == VoiceRecordingState.recording) {
      return false;
    }

    if (kIsWeb) {
      debugPrint('Voice recording not supported on web');
      return false;
    }

    try {
      // Check permission
      if (!await hasPermission()) {
        debugPrint('Microphone permission not granted');
        return false;
      }

      // Create file path
      final directory = await getTemporaryDirectory();
      final fileName = '${_uuid.v4()}.${VoiceRecordingConfig.fileExtension}';
      _currentRecordingPath = '${directory.path}/$fileName';

      // Configure recording
      const config = RecordConfig(
        encoder: VoiceRecordingConfig.encoder,
        sampleRate: VoiceRecordingConfig.sampleRate,
        bitRate: VoiceRecordingConfig.bitRate,
      );

      // Start recording
      await _recorder.start(config, path: _currentRecordingPath!);

      _currentDurationSeconds = 0;
      _updateState(VoiceRecordingState.recording);

      // Start duration timer
      _startDurationTimer();

      // Start amplitude monitoring
      _startAmplitudeMonitoring();

      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _updateState(VoiceRecordingState.idle);
      return false;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_state != VoiceRecordingState.recording) return;

    try {
      await _recorder.pause();
      _durationTimer?.cancel();
      _updateState(VoiceRecordingState.paused);
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_state != VoiceRecordingState.paused) return;

    try {
      await _recorder.resume();
      _startDurationTimer();
      _updateState(VoiceRecordingState.recording);
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  /// Stop recording and return the result
  Future<VoiceRecordingResult?> stopRecording() async {
    if (_state != VoiceRecordingState.recording &&
        _state != VoiceRecordingState.paused) {
      return null;
    }

    try {
      _durationTimer?.cancel();
      final path = await _recorder.stop();

      if (path == null || _currentRecordingPath == null) {
        _updateState(VoiceRecordingState.idle);
        return null;
      }

      final file = File(_currentRecordingPath!);
      final fileSize = await file.length();

      _updateState(VoiceRecordingState.stopped);

      final result = VoiceRecordingResult(
        filePath: _currentRecordingPath!,
        durationSeconds: _currentDurationSeconds,
        fileSizeBytes: fileSize,
      );

      // Reset state
      _currentRecordingPath = null;
      _currentDurationSeconds = 0;
      _updateState(VoiceRecordingState.idle);

      return result;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _updateState(VoiceRecordingState.idle);
      return null;
    }
  }

  /// Cancel ongoing recording
  Future<void> cancelRecording() async {
    try {
      _durationTimer?.cancel();
      await _recorder.stop();

      // Delete the temporary file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _currentRecordingPath = null;
      _currentDurationSeconds = 0;
      _updateState(VoiceRecordingState.idle);
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentDurationSeconds++;
      _durationController.add(_currentDurationSeconds);

      // Auto-stop if max duration reached
      if (_currentDurationSeconds >= VoiceRecordingConfig.maxDurationSeconds) {
        stopRecording();
      }
    });
  }

  void _startAmplitudeMonitoring() {
    // Monitor amplitude periodically
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_state != VoiceRecordingState.recording) {
        timer.cancel();
        return;
      }

      try {
        final amplitude = await _recorder.getAmplitude();
        // Normalize amplitude to 0-1 range
        final normalized = ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
        _amplitudeController.add(normalized);
      } catch (e) {
        // Ignore amplitude errors
      }
    });
  }

  void _updateState(VoiceRecordingState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Dispose resources
  void dispose() {
    _durationTimer?.cancel();
    _stateController.close();
    _durationController.close();
    _amplitudeController.close();
    _recorder.dispose();
  }
}

/// Service for playing voice messages
class VoicePlayerService {
  final AudioPlayer _player = AudioPlayer();

  String? _currentUrl;

  // Stream controllers
  final _stateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  // Public getters
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  String? get currentUrl => _currentUrl;

  // Streams
  Stream<PlayerState> get stateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  VoicePlayerService() {
    // Forward player streams
    _player.playerStateStream.listen((state) {
      _stateController.add(state);
    });
    _player.positionStream.listen((pos) {
      _positionController.add(pos);
    });
    _player.durationStream.listen((dur) {
      if (dur != null) {
        _durationController.add(dur);
      }
    });
  }

  /// Load and prepare audio from URL
  Future<Duration?> load(String url) async {
    try {
      _currentUrl = url;
      final duration = await _player.setUrl(url);
      return duration;
    } catch (e) {
      debugPrint('Error loading audio: $e');
      return null;
    }
  }

  /// Load and prepare audio from file path
  Future<Duration?> loadFile(String path) async {
    try {
      _currentUrl = path;
      final duration = await _player.setFilePath(path);
      return duration;
    } catch (e) {
      debugPrint('Error loading audio file: $e');
      return null;
    }
  }

  /// Play audio
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  /// Pause audio
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  /// Stop audio
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      debugPrint('Error setting speed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
    _positionController.close();
    _durationController.close();
    _player.dispose();
  }
}

/// Format duration for display (MM:SS)
String formatVoiceDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Format duration from seconds for display (MM:SS)
String formatVoiceDurationSeconds(int seconds) {
  return formatVoiceDuration(Duration(seconds: seconds));
}
