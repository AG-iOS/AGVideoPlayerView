//
//  VideoPlayerView.swift
//
//  Created by andrii.golovin on 31.07.17.
//  Copyright © 2017 Andrey Golovin. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import PINRemoteImage

extension Notification.Name {
    static let playerDidChangeFullscreenMode = Notification.Name("playerDidEnterFullscreenMode")
}

class AGVideoPlayerView: UIView {
    
    //MARK: Public variables
    var videoUrl: URL? {
        didSet {
            prepareVideoPlayer()
        }
    }
    var previewImageUrl: URL? {
        didSet {
            previewImageView.pin_setImage(from: previewImageUrl, placeholderImage: UIImage())
            previewImageView.isHidden = false
        }
    }
    
    //Automatically play the video when its view is visible on the screen.
    var shouldAutoplay: Bool = false {
        didSet {
            if shouldAutoplay {
                runTimer()
            } else {
                removeTimer()
            }
        }
    }

    //Automatically replay video after playback is complete.
    var shouldAutoRepeat: Bool = false {
        didSet {
            if oldValue == shouldAutoRepeat { return }
            if shouldAutoRepeat {
                NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
            }
        }
    }
    
    //Automatically switch to full-screen mode when device orientation did change to landscape.
    var shouldSwitchToFullscreen: Bool = false {
        didSet {
            if oldValue == shouldSwitchToFullscreen { return }
            if shouldSwitchToFullscreen {
                NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange(_:)), name: .UIDeviceOrientationDidChange, object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
            }
        }
    }
    
    //Use AVPlayer's controls or custom. Now custom control view has only "Play" button. Add additional controls if needed.
    var showsCustomControls: Bool = true {
        didSet {
            playerController.showsPlaybackControls = !showsCustomControls
            customControlsContentView.isHidden = !showsCustomControls
        }
    }
    
    //Value from 0.0 to 1.0, which sets the minimum percentage of the video player's view visibility on the screen to start playback.
    var minimumVisibilityValueForStartAutoPlay: CGFloat = 0.9
    
    //Mute the video.
    var isMuted: Bool = false {
        didSet {
            playerController.player?.isMuted = isMuted
        }
    }
    
    //MARK: Private variables
    fileprivate let playerController = AVPlayerViewController()
    fileprivate var isPlaying: Bool = false
    fileprivate var videoAsset: AVURLAsset?
    fileprivate var displayLink: CADisplayLink?
    
    fileprivate var previewImageView: UIImageView!
    fileprivate var customControlsContentView: UIView!
    fileprivate var playIcon: UIImageView!
    fileprivate var isFullscreen = false
    
    //MARK: Life cycle
    deinit {
        NotificationCenter.default.removeObserver(self)
        removePlayerObservers()
        displayLink?.invalidate()
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            pause()
            removeTimer()
        } else {
            if shouldAutoplay {
                runTimer()
            }
        }
    }
}

//MARK: View configuration
extension AGVideoPlayerView {
    fileprivate func setUpView() {
        self.backgroundColor = .black
        addVideoPlayerView()
        configurateControls()
    }
    
    private func addVideoPlayerView() {
        playerController.view.frame = self.bounds
        playerController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerController.showsPlaybackControls = false
        self.insertSubview(playerController.view, at: 0)
    }
    
    private func configurateControls() {
        customControlsContentView = UIView(frame: self.bounds)
        customControlsContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        customControlsContentView.backgroundColor = .clear
        
        previewImageView = UIImageView(frame: self.bounds)
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewImageView.clipsToBounds = true
        
        playIcon = UIImageView(image: UIImage(named:"video_player_play_icon"))
        playIcon.isUserInteractionEnabled = true
        playIcon.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        playIcon.center = previewImageView!.center
        playIcon.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        addSubview(previewImageView!)
        customControlsContentView?.addSubview(playIcon)
        addSubview(customControlsContentView!)
        let playAction = UITapGestureRecognizer(target: self, action: #selector(didTapPlay))
        playIcon.addGestureRecognizer(playAction)
        let pauseAction = UITapGestureRecognizer(target: self, action: #selector(didTapPause))
        customControlsContentView.addGestureRecognizer(pauseAction)
    }
}

//MARK: Timer part
extension AGVideoPlayerView {
    fileprivate func runTimer() {
        if displayLink != nil {
            displayLink?.isPaused = false
            return
        }
        displayLink = CADisplayLink(target: self, selector: #selector(timerAction))
        if #available(iOS 10.0, *) {
            displayLink?.preferredFramesPerSecond = 5
        } else {
            displayLink?.frameInterval = 5
        }
        displayLink?.add(to: RunLoop.current, forMode: .commonModes)
    }
    
    fileprivate func removeTimer() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func timerAction() {
        guard videoUrl != nil else {
            return
        }
        if isVisible() {
            play()
        } else {
            pause()
        }
    }
}

//MARK: Logic of the view's position search on the app screen.
extension AGVideoPlayerView {
    fileprivate func isVisible() -> Bool {
        if self.window == nil {
            return false
        }
        let displayBounds = UIScreen.main.bounds
        let selfFrame = self.convert(self.bounds, to: UIApplication.shared.keyWindow)
        let intersection = displayBounds.intersection(selfFrame)
        let visibility = (intersection.width * intersection.height) / (frame.width * frame.height)
        return visibility >= minimumVisibilityValueForStartAutoPlay
    }
}

//MARK: Video player part
extension AGVideoPlayerView {
    fileprivate func prepareVideoPlayer() {
        playerController.player?.removeObserver(self, forKeyPath: "rate")
        guard let url = videoUrl else {
            videoAsset = nil
            playerController.player = nil
            return
        }
        videoAsset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: videoAsset!)
        let player = AVPlayer(playerItem: item)
        playerController.player = player
        addPlayerObservers()
    }
    
    @objc fileprivate func didTapPlay() {
        displayLink?.isPaused = false
        play()
    }
    
    @objc fileprivate func didTapPause() {
        displayLink?.isPaused = true
        pause()
    }
    
    fileprivate func play() {
        if isPlaying { return }
        isPlaying = true
        videoAsset?.loadValuesAsynchronously(forKeys: ["playable", "tracks", "duration"], completionHandler: { [weak self] _ in
            DispatchQueue.main.async {
                if self?.isPlaying == true {
                    self?.playIcon.isHidden = true
                    self?.previewImageView.isHidden = true
                    self?.playerController.player?.play()
                }
            }
        })
    }
    
    fileprivate func pause() {
        if isPlaying {
            isPlaying = false
            playIcon.isHidden = false
            playerController.player?.pause()
        }
    }
    
    @objc fileprivate func itemDidFinishPlaying() {
        if isPlaying {
            playerController.player?.seek(to: kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            playerController.player?.play()
        }
    }
}

//MARK: Player size observing part
extension AGVideoPlayerView {
    fileprivate func addPlayerObservers() {
        playerController.player?.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
        playerController.contentOverlayView?.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)
    }
    
    fileprivate func removePlayerObservers() {
        playerController.player?.removeObserver(self, forKeyPath: "rate")
        playerController.contentOverlayView?.removeObserver(self, forKeyPath: "bounds")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath! {
        case "rate":
            self.previewImageView.isHidden = true
        case "bounds":
            let fullscreen = playerController.contentOverlayView?.bounds == UIScreen.main.bounds
            if isFullscreen != fullscreen {
                isFullscreen = fullscreen
                NotificationCenter.default.post(name: .playerDidChangeFullscreenMode, object: isFullscreen)
            }
        default:
            break
        }
    }
}

//MARK: Device orientation observing
extension AGVideoPlayerView {
    @objc fileprivate func deviceOrientationDidChange(_ notification: Notification) {
        if isFullscreen || !isVisible() { return }
        if let orientation = (notification.object as? UIDevice)?.orientation, orientation == .landscapeLeft || orientation == .landscapeRight {
            playerController.forceFullScreenMode()
            updateDeviceOrientation(with: orientation)
        }
    }
    
    private func updateDeviceOrientation(with orientation: UIDeviceOrientation) {
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        })
    }
}

//MARK: AVPlayerViewController extension for force fullscreen mode
extension AVPlayerViewController {
    func forceFullScreenMode() {
        let selectorName : String = {
            if #available(iOS 11, *) {
                return "_transitionToFullScreenAnimated:completionHandler:"
            } else {
                return "_transitionToFullScreenViewControllerAnimated:completionHandler:"
            }
        }()
        let selectorToForceFullScreenMode = NSSelectorFromString(selectorName)
        if self.responds(to: selectorToForceFullScreenMode) {
            self.perform(selectorToForceFullScreenMode, with: true, with: nil)
        }
    }
}
