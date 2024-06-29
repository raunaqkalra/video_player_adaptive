import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_adaptive/custom_video_player_controls.dart';

class VideoFullScreen extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final bool isLive;
  final void Function()? onSettingsTap;

  const VideoFullScreen({
    super.key,
    required this.videoPlayerController,
    this.isLive = false,
    this.onSettingsTap,
  });

  @override
  State<VideoFullScreen> createState() => _VideoFullScreenState();
}

class _VideoFullScreenState extends State<VideoFullScreen> {
  bool isVisible = false;

  VoidCallback? listener;

  Timer? _timer;

  _VideoFullScreenState() {
    listener = () {
      if (!mounted) {
        return;
      }
      //ignore: no-empty-block
      setState(() {});
      if ((((widget.videoPlayerController.value.position.inMilliseconds) *
                  100) /
              (widget.videoPlayerController.value.duration.inMilliseconds)) >=
          100) {
        //ignore: no-empty-block
        widget.videoPlayerController.removeListener(listener ?? () {});
      }
    };
  }

  void initTimer() {
    _timer?.cancel();
    _timer = Timer(
      const Duration(seconds: 4),
      () => setState(() {
        isVisible = false;
      }),
    );
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    ); // to re-show bars
    _timer?.cancel();
    //ignore: no-empty-block
    widget.videoPlayerController.removeListener(listener ?? () {});
    super.dispose();
  }

  void hideControls() {
    if (mounted) {
      setState(() {
        isVisible = !isVisible;
      });
      if (isVisible) {
        initTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => hideControls(),
          child: ValueListenableBuilder(
            valueListenable: widget.videoPlayerController,
            builder: (context, VideoPlayerValue value, child) {
              return Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: value.aspectRatio,
                        child: VideoPlayer(
                          widget.videoPlayerController,
                        ),
                      ),
                    ),
                    if (!value.isInitialized || value.isBuffering)
                      Center(
                        child: Transform.scale(
                          scale: 1.4,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    AnimatedOpacity(
                      opacity: isVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: AbsorbPointer(
                        absorbing: !isVisible,
                        child: CustomVideoPlayerControls(
                          videoPlayerController: widget.videoPlayerController,
                          fullScreen: pushToSmallScreen,
                          isFullScreen: true,
                          isLive: widget.isLive,
                          onSettingsTap: widget.onSettingsTap,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void pushToSmallScreen() {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    Future.delayed(
      const Duration(seconds: 5),
      () => SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
      ]),
    );
  }
}
