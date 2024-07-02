# video_player_adaptive

Adaptive Video Player.

## Getting Started

dart pub add video_player_adaptive

This package supports multiple video URLs like HLS/DASH/MP4.
Provide a URL in VideoItemPlayer(url: '<URL Here>') widget.
This video player adapts to multiple bitrate resolutions according to the network bandwidth.
It also has the option to change the video quality, if the URL supports.

Example:
`VideoItemPlayer(
    videoUrl:
    'https://cph-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
    )`

I hope this helps. :)
Also request you to contribute to this project.
