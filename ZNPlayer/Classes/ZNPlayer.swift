//
//  ZNPlayer.swift
//  BoomEnglish
//
//  Created by xinpin on 2018/10/10.
//  Copyright © 2018年 Nix. All rights reserved.
//

import UIKit
import AVFoundation

enum ZNPlayerMode {
    case fill       // 撑满，会拉伸
    case aspectFit  // 等比例最长边撑满
    case aspectFill // 等比例最小边撑满，长边会裁剪
}

enum ZNPlayerState {
    case failed
    case buffering
    case playing
    case stoped
    case pause
}

@objc protocol ZNPlayerDelegate: NSObjectProtocol {
    @objc optional func zn_playerBack()
}

public class ZNPlayer: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var controlView: ZNPlayerControlView? {
        didSet{
            controlView?.pcvDelegate = self
            self.addSubview(controlView!)
            controlView?.snp.makeConstraints({ (make) in
                make.edges.equalTo(self)
            })
        }
    }
    
    var playerModel: ZNPlayerMode = .aspectFit {
        didSet {
            switch playerModel {
            case .fill:
                videoGravity = .resize
            case .aspectFit:
                videoGravity = .resizeAspect
            case .aspectFill:
                videoGravity = .resizeAspectFill
            }
            self.playerLayer?.videoGravity = videoGravity
        }
    }
    var videoGravity: AVLayerVideoGravity = .resizeAspect
    var playerState: ZNPlayerState = .stoped {
        didSet {
            self.controlView?.zn_playerActivity(state: playerState == .buffering)
            if playerState == .failed {
                self.controlView?.zn_playerLoadFailed()
            }
        }
    }
    var seekTime: Float = 0
    
    var urlAsset: AVURLAsset?
    var playerItem: AVPlayerItem? {
        willSet{
            self.disposePlayerItemMonitor()
        }
        didSet {
            NotificationCenter.default.addObserver(self, selector: #selector(videoPlayDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
            playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
            playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
            playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        }
    }
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isPauseByUser = false
    var playerDidEnd = false
    var isDragged = false
    var sliderLastValue: Float = 0
    var timeObserve: Any?
    var isFullScreen = false
    let concurrent = DispatchQueue(label: "com.nix.znplayerConcurrentQueue", attributes: .concurrent)
    public var config: ZNPlayerConfig? {
        didSet {
            if config?.controlView == nil {
                config?.controlView = ZNPlayerControlView.init(frame: .zero)
            }
            self.controlView = config?.controlView as? ZNPlayerControlView
            self.layer.contents = config?.placeholderImage?.cgImage
        }
    }
    
    // MARK: - Initialize
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addGestures()
        self.addDeviceNotifications()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("ZNPlayer deinit")
        if let timeObserve = self.timeObserve {
            self.player?.removeTimeObserver(timeObserve)
            self.timeObserve = nil
        }
        self.disposePlayerItemMonitor()
        self.playerItem = nil
    }
    
    func disposePlayerItemMonitor() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer?.frame = self.bounds
    }
    
    /// 点击手势 显示和隐藏控制层
    func addGestures() {
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTapAction))
        singleTap.numberOfTouchesRequired = 1
        singleTap.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTap)
        // 解决点击当前view时候响应其他控件事件
        singleTap.delaysTouchesBegan = true
    }
    
    /// 进入前、后台 耳机插入拔出
    func addDeviceNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterPlayground), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeListenerCallback(notification:)), name: .AVAudioSessionRouteChange, object: nil)
    }
    
    // MARK: - Public
    public func autoPlay() {

        config?.fatherView?.addSubview(self)
        self.snp.makeConstraints {[weak self] (make) in
            make.edges.equalTo((self?.config?.fatherView)!)
        }
        
        let url = config?.mediaURL
        self.urlAsset = AVURLAsset(url: url!)
        self.playerItem = AVPlayerItem(asset: self.urlAsset!)
        self.player = AVPlayer(playerItem: self.playerItem)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer?.videoGravity = videoGravity
        self.layer.insertSublayer(playerLayer!, at: 0)
        if let timeObserve = self.timeObserve {
            self.player?.removeTimeObserver(timeObserve)
            self.timeObserve = nil
        }
        self.playerState = .buffering
        self.createTimer()
        self.play()
    }
    
    // MARK: - reponse player
    func play() {
        self.controlView?.zn_playerPlayButtonState(state: true)
        if self.playerState == .pause {
            self.playerState = .playing
        }
        self.isPauseByUser = false
        self.player?.play()
    }
    
    func pause() {
        self.controlView?.zn_playerPlayButtonState(state: false)
        if (self.playerState == .playing) {
            self.playerState = .pause
        }
        self.isPauseByUser = true
        self.player?.pause()
    }
    
    func seekToTime(seconds: Float, completionHandle: @escaping(_ finished: Bool) -> ()) {
        if self.playerItem?.status == .readyToPlay {
            self.controlView?.zn_playerActivity(state: true)
            self.player?.pause()
            let dragedCMTime = CMTimeMake(Int64(seconds * 600), 600)
            self.player?.seek(to: dragedCMTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { [weak self] (finished) in
                self?.controlView?.zn_playerActivity(state: false)
                self?.player?.play()
                self?.isDragged = false
                self?.controlView?.zn_playerDraggedEnd()
                completionHandle(finished)
                if (self?.playerItem?.isPlaybackLikelyToKeepUp)! {
                    self?.playerState = .buffering
                }
            })
        }
    }
    
    func resetPlayer() {
        // 改为为播放完
        self.playerDidEnd = false
        self.playerItem = nil
        self.seekTime = 0
        if let timeObserve = self.timeObserve {
            self.player?.removeTimeObserver(timeObserve)
            self.timeObserve = nil
        }
        // 移除通知
        NotificationCenter.default.removeObserver(self)
        
        // 暂停
        self.pause()
        // 移除原来的layer
        self.playerLayer?.removeFromSuperlayer()
        // 替换PlayerItem为nil
        self.player?.replaceCurrentItem(with: nil)
        // 把player置为nil
        self.player = nil
        self.controlView?.zn_playerResetControlView()
        self.controlView = nil
    }
    
    @objc func singleTapAction(gesture: UIGestureRecognizer) {
        
        if gesture.state == .recognized {
            if !self.playerDidEnd {
                self.controlView?.zn_playerShowOrHideControlView()
            }
        }
    }
    
    // MARK: - 屏幕旋转
    func fullScreenAction() {
        if self.isFullScreen {
            self.interfaceOrientation(orientation: .portrait)
            self.isFullScreen = false
        } else {
            let orientation = UIDevice.current.orientation
            if orientation == .landscapeRight {
                self.interfaceOrientation(orientation: .landscapeLeft)
            } else {
                self.interfaceOrientation(orientation: .landscapeRight)
            }
            self.isFullScreen = true
        }
    }
    
    func interfaceOrientation(orientation: UIInterfaceOrientation) {
        if orientation == .landscapeRight || orientation == .landscapeLeft {
            self.setOrientationLandscapeConstraint(orientation: orientation)
        }
        else if orientation == .portrait {
            self.setOrientationPortraitConstraint()
        }
    }
    
    func setOrientationLandscapeConstraint(orientation: UIInterfaceOrientation) {
        self.removeFromSuperview()
        UIApplication.shared.delegate?.window??.addSubview(self)
        self.snp.remakeConstraints { (make) in
            make.width.equalTo(ZNScreenHeight)
            make.height.equalTo(ZNScreenWidth)
            make.center.equalTo((UIApplication.shared.delegate!.window!)!)
        }
        self.toOrientation(orientation: orientation)
        self.isFullScreen = true
    }
    
    func setOrientationPortraitConstraint() {
        self.removeFromSuperview()
        self.config?.fatherView?.addSubview(self)
        self.snp.remakeConstraints { (make) in
            make.edges.equalTo((self.config?.fatherView!)!)
        }
        self.toOrientation(orientation: .portrait)
        self.isFullScreen = false
    }
    
    func toOrientation(orientation: UIInterfaceOrientation) {
        // 获取到当前状态条的方向
        let currentOrientation = UIApplication.shared.statusBarOrientation
        // 判断如果当前方向和要旋转的方向一致,那么不做任何操作
        if currentOrientation == orientation {
            return
        }
        // iOS6-iOS9,设置状态条的方法能使用的前提是shouldAutorotate为NO,也就是说这个视图控制器内,旋转要关掉;
        // 也就是说在实现这个方法的时候-(BOOL)shouldAutorotate返回值要为NO
        UIApplication.shared.setStatusBarOrientation(orientation, animated: false)
        // 获取旋转状态条需要的时间:
        UIView.animate(withDuration: 0.3) {
            self.transform = .identity
            self.transform = self.getTransformRotationAngle()
        }
    }
    
    func getTransformRotationAngle() -> CGAffineTransform {
        let orientation = UIApplication.shared.statusBarOrientation
        // 根据要进行旋转的方向来计算旋转的角度
        if orientation == .portrait {
            return .identity
        } else if orientation == .landscapeLeft {
            return CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        } else if orientation == .landscapeRight {
            return CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        }
        return .identity
    }


    // MARK: - Notification KVO
    @objc func appDidEnterBackground() {
        self.player?.pause()
        self.playerState = .pause
    }
    
    @objc func appDidEnterPlayground() {
        if !self.isPauseByUser && !self.playerDidEnd {
            self.playerState = .playing
            self.play()
        }
    }
    
    @objc func audioRouteChangeListenerCallback(notification: Notification) {

        let interuptionDict = notification.userInfo
        print(type(of: interuptionDict!["AVAudioSessionRouteChangeReasonKey"]))
        let routeChangeReason = interuptionDict!["AVAudioSessionRouteChangeReasonKey"] as! AVAudioSessionRouteChangeReason
        
        switch routeChangeReason {
        case .newDeviceAvailable:
            // 耳机插入
            break
        case .oldDeviceUnavailable:
            // 耳机拔掉
            // 拔掉耳机继续播放
            self.play()
            break
        case .categoryChange:
            print("AVAudioSessionRouteChangeReason.categoryChange")
            break
        default:
            break
        }
    }
    
    @objc func videoPlayDidEnd(notification: Notification) {
        self.playerDidEnd = true
        self.controlView?.zn_playerPlayEnd()
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
       
        if object as? AVPlayerItem == playerItem {
            
            if keyPath == "status" {
                if self.player?.currentItem?.status == .readyToPlay {
                    self.setNeedsDisplay()
                    self.layoutIfNeeded()
                    // 添加playerLayer到self.layer
                    self.layer.insertSublayer(self.playerLayer!, at: 0)
                    self.playerState = .playing
                    // 跳到xx秒播放视频
                    if (self.seekTime > 0) {
                        self.seekToTime(seconds: self.seekTime) { (completed) in }
                    }
                }
                else if self.player?.currentItem?.status == .failed {
                    self.playerState = .failed
                }
            }
            else if keyPath == "loadedTimeRanges" {   // 缓冲进度
                let timeInterval = self.getBufferProgress()
                let duration = self.playerItem?.duration
                let totalDuration = CMTimeGetSeconds(duration!)
                let progress = Float.init(timeInterval / totalDuration)
                self.controlView?.zn_playerBufferProgress(progress: progress)
            }
            else if keyPath == "playbackBufferEmpty" {  // 缓冲是空的时候
                print("playbackBufferEmpty")
                if (self.playerItem?.isPlaybackBufferEmpty)! {
                    self.playerState = .buffering
                    self.bufferingSomeSecond()
                }
            }
            else if keyPath == "playbackLikelyToKeepUp" {  // 缓冲好的时候
                print("playbackLikelyToKeepUp")
                if (self.playerItem?.isPlaybackLikelyToKeepUp)! && self.playerState == .buffering {
                    self.playerState = .playing
                }
            }
        }
        
    }
    
    func createTimer() {
        
        self.timeObserve = self.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, 10), queue: concurrent, using: { [weak self] (time) in
            
            DispatchQueue.main.async(execute: {
                guard self != nil else {
                    return
                }
                let loadedRanges = self?.playerItem?.seekableTimeRanges
                if (loadedRanges?.count)! > 0 && (self?.playerItem?.duration.timescale != 0) {
                    let currentTime = CMTimeGetSeconds((self?.playerItem?.currentTime())!)
                    let totalTime = Double.init((self?.playerItem?.duration.value)!) / Double.init((self?.playerItem?.duration.timescale)!)
                    let value = currentTime / totalTime
                    self?.controlView?.zn_playerCurrentTime(currentTime: currentTime, totalTime: totalTime, sliderValue: Float.init(value))
                }
            })
        })
    }
    
    // MARK: - Buffer
    func getBufferProgress() -> TimeInterval {
        let loadTimeRanges = self.player?.currentItem?.loadedTimeRanges
        let timeRange = loadTimeRanges?.first?.timeRangeValue
        let startSeconds = CMTimeGetSeconds((timeRange?.start)!)
        let durationSeconds = CMTimeGetSeconds((timeRange?.duration)!)
        let result = startSeconds + durationSeconds
        return result
    }
    
    func bufferingSomeSecond() {

        self.playerState = .buffering
        // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
        var isBuffering = false
        if isBuffering {
            return
        }
        isBuffering = true
    
        // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
        self.player?.pause()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.isPauseByUser {
                isBuffering = false
                return
            }
            self.play()
            isBuffering = false
            guard (self.playerItem?.isPlaybackLikelyToKeepUp)! else {
                self.bufferingSomeSecond()
                return
            }
        }
    }

 
}


extension ZNPlayer: ZNPlayerControlViewDelegate {
    
    func zn_controlView(view: UIView, backAction backButton: UIButton) {
        // 返回按钮
    }
    
    func zn_controlView(view: UIView, playAction playButton: UIButton) {
        self.isPauseByUser = !self.isPauseByUser
        if self.isPauseByUser {
            self.pause()
            if self.playerState == .playing {
                self.playerState = .pause
            }
        } else {
            self.play()
            if self.playerState == .pause {
                self.playerState = .playing
            }
        }
    }
    
    func zn_controlView(view: UIView, repeatAction repeatButton: UIButton) {
        // 没有播放完
        self.playerDidEnd = false
        // 重播改为NO
        self.seekToTime(seconds: 0) { (completed) in }
        self.playerState = .buffering
    }
    
    func zn_controlView(view: UIView, fullScreenAction fullScreenButton: UIButton) {
        self.fullScreenAction()
    }
    
    func zn_controlView(view: UIView, failAction failButton: UIButton) {
        self.autoPlay()
    }
    
    
    func zn_controlView(view: UIView, sliderTapValue sliderValue: Float) {
        let total = Float((self.playerItem?.duration.value)!) / Float((self.playerItem?.duration.timescale)!)
        let dragedSeconds = floorf(total * sliderValue)
        self.controlView?.zn_playerPlayButtonState(state: true)
        self.seekToTime(seconds: dragedSeconds) { (finished) in }
    }
    

    func zn_controlView(view: UIView, sliderTouchBegain slider: UISlider) {
        
    }
    
    func zn_controlView(view: UIView, sliderValueChanged slider: UISlider) {
        // 拖动改变视频播放进度
        if self.playerItem?.status == .readyToPlay {
            self.isDragged = true
            var style = false
            let value = slider.value - self.sliderLastValue
            if value > 0 { style = true }
            if value < 0 { style = false }
            if value == 0 { return }
            
            self.sliderLastValue = slider.value;
            let totalTime = Float((playerItem?.duration.value)!) / Float((playerItem?.duration.timescale)!)
            //计算出拖动的当前秒数
            let dragedSeconds = floorf(totalTime * slider.value)
            
            controlView?.zn_playerDraggedTime(dragedSeconds: dragedSeconds, totalTime: totalTime, isForward: style)
            
            if totalTime <= 0 {
                slider.value = 0;
            }
        } else { // player状态加载失败
            // 此时设置slider值为0
            slider.value = 0;
        }
    }
    
    func zn_controlView(view: UIView, sliderTouchEnd slider: UISlider) {
        if self.playerItem?.status == .readyToPlay {
            self.isPauseByUser = false
            self.isDragged = true
            // 视频总时间长度
            let total = Float((playerItem?.duration.value)!) / Float((playerItem?.duration.timescale)!)
            //计算出拖动的当前秒数
            let dragedSeconds = floorf(total * slider.value)
            self.seekToTime(seconds: dragedSeconds) { (finished) in
                
            }
        }
    }
}
