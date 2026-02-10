import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/voice_service.dart';

/// Widget for displaying and playing voice messages
class VoiceMessageWidget extends StatefulWidget {
  final String voiceUrl;
  final int? durationSeconds;
  final bool isFromArtist;

  const VoiceMessageWidget({
    super.key,
    required this.voiceUrl,
    this.durationSeconds,
    this.isFromArtist = false,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  late final VoicePlayerService _player;
  bool _isLoading = false;
  bool _hasError = false;
  Duration? _totalDuration;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = VoicePlayerService();
    _setupPlayer();
  }

  void _setupPlayer() {
    // Listen to player state changes
    _player.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _currentPosition = Duration.zero;
            _isPlaying = false;
          }
        });
      }
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  Future<void> _loadAudio() async {
    if (_totalDuration != null) return; // Already loaded

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final duration = await _player.load(widget.voiceUrl);
      if (mounted) {
        setState(() {
          _totalDuration = duration;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading) return;

    // Load audio if not loaded yet
    if (_totalDuration == null) {
      await _loadAudio();
      if (_hasError) return;
    }

    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.isFromArtist ? AppColors.primary : Colors.grey;

    // Use provided duration or total duration from player
    final displayDuration = _totalDuration ??
        (widget.durationSeconds != null
            ? Duration(seconds: widget.durationSeconds!)
            : null);

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _hasError
                          ? Icons.error_outline
                          : _isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Waveform / Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: primaryColor,
                    inactiveTrackColor:
                        isDark ? Colors.grey[600] : Colors.grey[400],
                    thumbColor: primaryColor,
                  ),
                  child: Slider(
                    value: displayDuration != null &&
                            displayDuration.inMilliseconds > 0
                        ? (_currentPosition.inMilliseconds /
                                displayDuration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0,
                    onChanged: displayDuration != null
                        ? (value) {
                            final newPosition = Duration(
                              milliseconds:
                                  (displayDuration.inMilliseconds * value)
                                      .round(),
                            );
                            _player.seek(newPosition);
                          }
                        : null,
                  ),
                ),
                // Duration
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatVoiceDuration(_currentPosition),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        displayDuration != null
                            ? formatVoiceDuration(displayDuration)
                            : '--:--',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact voice recording button with amplitude visualization
class VoiceRecordButton extends StatefulWidget {
  final VoidCallback? onRecordingStarted;
  final void Function(VoiceRecordingResult result)? onRecordingCompleted;
  final VoidCallback? onRecordingCancelled;

  const VoiceRecordButton({
    super.key,
    this.onRecordingStarted,
    this.onRecordingCompleted,
    this.onRecordingCancelled,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  late final VoiceRecordingService _recorder;
  late final AnimationController _pulseController;
  bool _isRecording = false;
  int _durationSeconds = 0;
  double _amplitude = 0;

  @override
  void initState() {
    super.initState();
    _recorder = VoiceRecordingService();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _recorder.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isRecording = state == VoiceRecordingState.recording;
        });
      }
    });

    _recorder.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _durationSeconds = duration;
        });
      }
    });

    _recorder.amplitudeStream.listen((amplitude) {
      if (mounted) {
        setState(() {
          _amplitude = amplitude;
        });
      }
    });
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이크 권한이 필요합니다')),
        );
      }
      return;
    }

    final started = await _recorder.startRecording();
    if (started) {
      widget.onRecordingStarted?.call();
    }
  }

  Future<void> _stopRecording() async {
    final result = await _recorder.stopRecording();
    if (result != null) {
      widget.onRecordingCompleted?.call(result);
    }
  }

  Future<void> _cancelRecording() async {
    await _recorder.cancelRecording();
    widget.onRecordingCancelled?.call();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return _buildRecordingUI();
    }

    return IconButton(
      onPressed: _startRecording,
      icon: const Icon(Icons.mic),
      tooltip: '음성 메시지',
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red
                      .withValues(alpha: 0.5 + _pulseController.value * 0.5),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Duration
          Text(
            formatVoiceDurationSeconds(_durationSeconds),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          // Amplitude visualization
          SizedBox(
            width: 60,
            height: 24,
            child: CustomPaint(
              painter: _AmplitudePainter(amplitude: _amplitude),
            ),
          ),
          const SizedBox(width: 8),
          // Cancel button
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          // Stop button
          IconButton(
            onPressed: _stopRecording,
            icon: const Icon(Icons.send, color: Colors.red),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _AmplitudePainter extends CustomPainter {
  final double amplitude;

  _AmplitudePainter({required this.amplitude});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 5;
    final barWidth = size.width / (barCount * 2 - 1);

    for (var i = 0; i < barCount; i++) {
      // Create varying heights based on amplitude
      final heightFactor =
          (1 - (i - barCount ~/ 2).abs() / (barCount / 2)) * amplitude;
      final barHeight = size.height * 0.3 + size.height * 0.7 * heightFactor;
      final x = i * barWidth * 2 + barWidth / 2;
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_AmplitudePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude;
  }
}
