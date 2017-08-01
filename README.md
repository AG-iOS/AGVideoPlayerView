# AGVideoPlayerView

It's a simple video player view based on AVPlayer with ability to autoplay video when view visible on the screen.

## Installing

1. Copy AGVideoPlayerView folder to your project.
2. Create UIView in the storyboard and set AGVideoPlayerView custom class for that view or create AGVideoPlayerView with ```AGVideoPlayerView(frame:)```.
3. Add PINRemoteImage to your project or replace it in the AGVideoPlayerView class with your implementation. 
(PINRemoteImage is required for asynchronous loading and caching of preview images for video.)

**Sample**

```
let playerView = AGVideoPlayerView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
view.addSubview(playerView)

playerView.videoUrl = URL(string: "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_1mb.mp4")
playerView.previewImageUrl = URL(string: "https://i.ytimg.com/vi/aqz-KE-bpKQ/maxresdefault.jpg")

playerView.shouldAutoplay = true //Automatically play the video when its view is visible on the screen. false by default.
playerView.shouldAutoRepeat = true //Automatically replay video after playback is complete. false by default.
playerView.showsCustomControls = true //Use AVPlayer's controls or custom. Now custom control view has only "Play" button. Add additional controls if needed.
playerView.isMuted = true //Mute the video.
playerView.minimumVisibilityValueForStartAutoPlay = 0.9 //Value from 0.0 to 1.0, which sets the minimum percentage of the video player's view visibility on the screen to start playback.

```

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
