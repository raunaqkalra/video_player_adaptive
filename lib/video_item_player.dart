library video_player_adaptive_example;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_adaptive/custom_video_player_controls.dart';
import 'package:video_player_adaptive/util/util.dart';
import 'package:video_player_adaptive/video_fullscreen.dart';

class VideoItemPlayer extends StatefulWidget {
  /// Video URL to stream
  final String videoUrl;

  /// to hide/unhide the duration of video as a live video does not have any duration
  final bool isLive;

  ///to enable or disable the resolution settings icon so the user cannot change the video quality manually
  final bool isSettingsEnabled;

  const VideoItemPlayer({
    required this.videoUrl,
    this.isLive = false,
    this.isSettingsEnabled = true,
    super.key,
  });

  @override
  State<VideoItemPlayer> createState() => _VideoItemPlayerState();
}

class _VideoItemPlayerState extends State<VideoItemPlayer> {
  int _controlVisibilityCounter = 0;
  String selectedUrl = '';

  List<(String resolution, String link)>? qualityLink;

  Timer? _timer;

  // MethodChannel timeoutManagerChannel =
  //     const MethodChannel('timeout.manager.dev/channel');

  _VideoItemPlayerState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
      if ((_videoPlayerController?.value.isInitialized ?? false) &&
          _controlVisibilityCounter == 0) {
        ++_controlVisibilityCounter;
        initTimer();
      }
      if (((((_videoPlayerController?.value.position.inMilliseconds ?? 0) *
                      100) /
                  (_videoPlayerController?.value.duration.inMilliseconds ??
                      1)) >=
              100) &&
          !isHundredPercentTriggered) {
        _videoPlayerController?.removeListener(listener ?? () {});
      }
    };
  }

  bool isHundredPercentTriggered = false;

  VoidCallback? listener;
  VideoPlayerController? _videoPlayerController;
  bool isVisible = true;

  // StreamSubscription<ConnectivityResult>? connectivityStream;
  Duration? _position;
  bool isForcefullyPaused = true;

  ///used for android devices to not timeout while playing videos
  ///doing for android only because it already works for for ios
  // Future<dynamic> setTimeoutToNever() async {
  //   if (Platform.isAndroid) {
  //     try {
  //       //Method channel for screen timeout handling
  //       return timeoutManagerChannel.invokeMethod('keepScreenOn');
  //     } on PlatformException catch (e) {
  //       return "Failed to Invoke: '${e.message}'.";
  //     }
  //   }
  // }
  //
  // Future<dynamic> setTimeoutToDefault() async {
  //   if (Platform.isAndroid) {
  //     try {
  //       //Method channel for screen timeout handling
  //       return timeoutManagerChannel.invokeMethod('keepDefault');
  //     } on PlatformException catch (e) {
  //       return "Failed to Invoke: '${e.message}'.";
  //     }
  //   }
  // }

  @override
  void initState() {
    // setTimeoutToNever();
    _playVideo();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    getQualities();
    super.initState();
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

  Future<void> getQualities() async {
    selectedUrl = widget.videoUrl;
    if (widget.videoUrl.contains('.m3u8')) {
      final response = await Dio().get(
        widget.videoUrl,
      );
      final data = response.data;
      qualityLink = Util.searchResolutions(data);
    }
  }

  void changeQuality(String quality) {
    setState(() {
      _videoPlayerController?.pause();
      _videoPlayerController?.dispose();
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(
          selectedUrl.replaceAll(
            selectedUrl.split('/').last,
            quality,
          ),
        ),
        videoPlayerOptions: VideoPlayerOptions(),
      )
        ..addListener(listener ?? () {})
        ..initialize().then((value) => _videoPlayerController?.play());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // setTimeoutToDefault();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _playVideo() {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(),
    )
      ..addListener(listener ?? () {})
      ..initialize().then((value) => _videoPlayerController?.play());
  }

  void onSettingsTap() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: (qualityLink?.length ?? 0) + 1,
        itemBuilder: (context, index) => ListTile(
          onTap: () {
            Navigator.pop(context);
            changeQuality(
              (index == qualityLink?.length)
                  ? widget.videoUrl.split('/').lastOrNull ?? ''
                  : qualityLink?.elementAt(index).$2 ?? '',
            );
          },
          title: Text(
            (index == qualityLink?.length)
                ? 'Auto'
                : qualityLink?.elementAt(index).$1 ?? '',
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  void _playToPosition() {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(),
    )
      ..addListener(listener ?? () {})
      ..initialize().then(
        (value) => _videoPlayerController?.play().then((value) {
          _videoPlayerController?.seekTo(_position ?? Duration.zero);
          if (isForcefullyPaused) {
            _videoPlayerController?.pause();
          }
        }),
      );
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

  void pushToFullScreen() {
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

  @override
  Widget build(BuildContext context) {
    //to get last position before reset
    if (_videoPlayerController?.value.position != Duration.zero) {
      _position = _videoPlayerController?.value.position;
    }
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: () => hideControls(),
          // onPanUpdate: (details) => onDragDown(details, context),
          child: Stack(
            children: [
              if (_videoPlayerController!.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(
                      _videoPlayerController!,
                    ),
                  ),
                ),
              ValueListenableBuilder(
                //ignore: avoid-non-null-assertion
                valueListenable: _videoPlayerController!,
                builder: (context, VideoPlayerValue value, child) {
                  return value.errorDescription == null &&
                          (!value.isInitialized || value.isBuffering)
                      ? Center(
                          child: Transform.scale(
                            scale: 1.4,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
              // if (isVisible)
              ValueListenableBuilder(
                valueListenable: _videoPlayerController!,
                builder: (context, VideoPlayerValue value, child) {
                  return AnimatedOpacity(
                    opacity: isVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: AbsorbPointer(
                      absorbing: !isVisible,
                      child: CustomVideoPlayerControls(
                        videoPlayerController: _videoPlayerController!,
                        fullScreen: pushToFullScreen,
                        isFullScreen: false,
                        isLive: widget.isLive,
                        onSettingsTap: onSettingsTap,
                        isSettingsEnabled: (qualityLink?.length ?? 0) > 1 &&
                            widget.isSettingsEnabled,
                        onPlayToggle: (bool isPaused) {
                          isForcefullyPaused = isPaused;
                        },
                      ),
                    ),
                  );
                },
              ),
              if (Navigator.of(context).canPop())
                Padding(
                  padding: const EdgeInsets.only(
                    left: 18,
                    top: 14,
                  ),
                  child: BackButton(
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      return VideoFullScreen(
        videoPlayerController: _videoPlayerController!,
        isLive: widget.isLive,
        onSettingsTap: onSettingsTap,
      );
    }
  }
}
