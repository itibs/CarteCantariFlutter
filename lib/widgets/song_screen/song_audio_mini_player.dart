import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

String formatAudioPosition(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class SongAudioMiniPlayer extends StatefulWidget {
  final AudioPlayer player;
  final bool showPlayHint;
  final String? errorMessage;
  final VoidCallback onPlayed;
  final VoidCallback onClose;

  const SongAudioMiniPlayer({
    Key? key,
    required this.player,
    required this.showPlayHint,
    this.errorMessage,
    required this.onPlayed,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SongAudioMiniPlayer> createState() => _SongAudioMiniPlayerState();
}

class _SongAudioMiniPlayerState extends State<SongAudioMiniPlayer> {
  double? _dragValueMs;

  Future<void> _onPlayPressed(PlayerState state) async {
    widget.onPlayed();
    if (state.playing) {
      await widget.player.pause();
      return;
    }
    if (state.processingState == ProcessingState.completed) {
      await widget.player.seek(Duration.zero);
    }
    await widget.player.play();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showPlayHint)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 8, 4),
                  child: Text(
                    'Apasă Redă pentru a porni muzica',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              if (widget.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 8, 4),
                  child: Text(
                    widget.errorMessage!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              StreamBuilder<PlayerState>(
                stream: widget.player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data ?? widget.player.playerState;
                  final processing = playerState.processingState;
                  final loading = processing == ProcessingState.loading ||
                      processing == ProcessingState.buffering;
                  final playing = playerState.playing &&
                      processing != ProcessingState.completed;

                  return Row(
                    children: [
                      FilledButton.icon(
                        onPressed: loading || widget.errorMessage != null
                            ? null
                            : () => _onPlayPressed(playerState),
                        icon: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          size: 28,
                        ),
                        label: Text(playing ? 'Pauză' : 'Redă'),
                      ),
                      Expanded(
                        child: _SeekBar(
                          player: widget.player,
                          dragValueMs: _dragValueMs,
                          onDragChanged: (value) {
                            setState(() {
                              _dragValueMs = value;
                            });
                          },
                          onDragEnd: (value) async {
                            await widget.player.seek(
                              Duration(milliseconds: value.round()),
                            );
                            if (mounted) {
                              setState(() {
                                _dragValueMs = null;
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: 'Închide',
                        icon: const Icon(Icons.close),
                        iconSize: 28,
                        onPressed: widget.onClose,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeekBar extends StatelessWidget {
  final AudioPlayer player;
  final double? dragValueMs;
  final ValueChanged<double> onDragChanged;
  final ValueChanged<double> onDragEnd;

  const _SeekBar({
    required this.player,
    required this.dragValueMs,
    required this.onDragChanged,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds.toDouble();

        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final positionMs = dragValueMs ??
                position.inMilliseconds.toDouble().clamp(0, maxMs < 1 ? 0 : maxMs);
            final displayPosition = Duration(milliseconds: positionMs.round());

            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    formatAudioPosition(displayPosition),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: maxMs < 1 ? 1 : maxMs,
                    value: maxMs < 1 ? 0 : positionMs.clamp(0, maxMs),
                    onChanged: maxMs < 1 ? null : onDragChanged,
                    onChangeEnd: maxMs < 1 ? null : onDragEnd,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    formatAudioPosition(duration),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
