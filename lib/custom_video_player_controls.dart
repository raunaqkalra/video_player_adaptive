import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayerControls extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final Function()? fullScreen;
  final bool isFullScreen;
  final void Function(bool isPaused)? onPlayToggle;
  final void Function()? onSettingsTap;
  final bool? isSettingsEnabled;
  final bool isLive;

  const CustomVideoPlayerControls({
    super.key,
    required this.videoPlayerController,
    this.fullScreen,
    required this.isFullScreen,
    this.onPlayToggle,
    this.isLive = false,
    this.onSettingsTap,
    this.isSettingsEnabled,
  });

  @override
  State<CustomVideoPlayerControls> createState() =>
      _CustomVideoPlayerControlsState();
}

class _CustomVideoPlayerControlsState extends State<CustomVideoPlayerControls> {
  bool isVisible = false;
  bool isFullScreen = false;
  bool mute = false;

  void muteUnmuteVideo(double vol) {
    if (vol == 0) {
      widget.videoPlayerController.setVolume(1);
    } else {
      widget.videoPlayerController.setVolume(0);
    }
  }

  String _getDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitHours = twoDigits(duration.inHours.remainder(24));
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String totalTime = '$twoDigitMinutes:$twoDigitSeconds';
    if (twoDigitHours != '00') {
      totalTime = '$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds';
    }
    return totalTime;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(
            widget.videoPlayerController.value.isInitialized &&
                    !widget.videoPlayerController.value.isBuffering
                ? 0.5
                : 0,
          ),
        ),
        if (widget.isFullScreen && Navigator.of(context).canPop())
          Padding(
            padding: const EdgeInsets.only(
              left: 18,
              top: 14,
            ),
            child: BackButton(
              onPressed: widget.isFullScreen
                  ? widget.fullScreen
                  : () => Navigator.of(context).pop(),
              color: Colors.white,
            ),
          ),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!widget.isLive)
                GestureDetector(
                  onTap: () => widget.videoPlayerController.seekTo(
                    widget.videoPlayerController.value.position -
                        const Duration(seconds: 10),
                  ),
                  child: const Icon(
                    Icons.replay_10,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              if (widget.videoPlayerController.value.isInitialized &&
                  !widget.videoPlayerController.value.isBuffering)
                ValueListenableBuilder(
                  valueListenable: widget.videoPlayerController,
                  builder: (context, VideoPlayerValue value, child) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 40, right: 40),
                      child: GestureDetector(
                        onTap: () => {
                          if (value.isPlaying)
                            widget.videoPlayerController.pause()
                          else
                            widget.videoPlayerController.play(),
                          widget.onPlayToggle?.call(value.isPlaying),
                        },
                        child: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                )
              else
                const SizedBox(
                  width: 135,
                ),
              if (!widget.isLive)
                GestureDetector(
                  onTap: () => widget.videoPlayerController.seekTo(
                    widget.videoPlayerController.value.position +
                        const Duration(seconds: 10),
                  ),
                  child: const Icon(
                    Icons.forward_10,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: widget.isFullScreen ? 20 : 6,
          left: 16,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.isLive)
                const Text(
                  '--/--',
                )
              else
                ValueListenableBuilder(
                  valueListenable: widget.videoPlayerController,
                  builder: (context, VideoPlayerValue value, child) {
                    //Do Something with the value.
                    return Text(
                      '${_getDuration(value.position)}/${_getDuration(value.duration)}',
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
              Row(
                children: [
                  ValueListenableBuilder(
                    valueListenable: widget.videoPlayerController,
                    builder: (context, VideoPlayerValue value, child) {
                      return RawMaterialButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        onPressed: () => muteUnmuteVideo(value.volume),
                        child: Icon(
                          value.volume == 0
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  if (widget.isSettingsEnabled ?? false)
                    RawMaterialButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      onPressed: widget.onSettingsTap,
                      child: const Icon(
                        Icons.settings,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: RawMaterialButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      onPressed: widget.fullScreen,
                      child: Icon(
                        widget.isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: widget.isFullScreen ? 16 : 0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 7,
              child: VideoProgressIndicator(
                widget.videoPlayerController,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  bufferedColor:
                      widget.isLive ? const Color(0xffFFA329) : Colors.grey,
                  playedColor: const Color(0xffFFA329),
                  backgroundColor:
                      widget.isLive ? const Color(0xffFFA329) : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
