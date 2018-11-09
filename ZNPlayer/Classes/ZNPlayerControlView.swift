//
//  ZNPlayerControlView.swift
//  BoomEnglish
//
//  Created by xinpin on 2018/10/11.
//  Copyright © 2018年 Nix. All rights reserved.
//

import UIKit
import SnapKit

let ZNPlayerAnimationTimeInterval             = 7.0
let ZNPlayerControlAutoFadeOutTimeInterval    = 0.35

public class ZNPlayerControlView: ZNBaseControlView {
    
    /// 顶部控制层背景
    lazy var topImageView: UIImageView = {
        var imageView = UIImageView.init(image: Bundle.bundleImage(named: "ZNPlayer_Top_Shadow"))
        imageView.isUserInteractionEnabled = true

        imageView.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(0)
            make.left.equalTo(10)
            make.width.equalTo(50)
        }
        return imageView
    }()
    
    /// 返回按钮
    lazy var backButton: UIButton = {
        var button = UIButton(type: UIButtonType.custom)
        button.setImage(Bundle.bundleImage(named: "ZNPlayer_Back"), for: .normal)
        button.isHidden = true
        button.addTarget(self, action: #selector(clickFailButtonAction(button:)), for: .touchUpInside)
        return button
    }()
    
    /// 失败
    lazy var failButton: UIButton = {
        var button = UIButton(type: UIButtonType.custom)
        return button
    }()
    
    /// 重播
    lazy var repeatButton: UIButton = {
        var button = UIButton(type: UIButtonType.custom)
        button.setImage(Bundle.bundleImage(named: "ZNPlayer_Repeat"), for: .normal)
        button.addTarget(self, action: #selector(clickRepeatButtonAction(button:)), for: .touchUpInside)
        button.isHidden = true
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowOpacity = 0.5
        button.layer.shadowColor = UIColor.black.cgColor
        return button
    }()
    
    /// 底部控制层背景
    lazy var bottomImageView: UIImageView = {
        var imageView = UIImageView.init(image: Bundle.bundleImage(named: "ZNPlayer_Bottom_Shadow"))
        imageView.isUserInteractionEnabled = true
        
        imageView.addSubview(playButton)
        imageView.addSubview(currentTimeLabel)
        imageView.addSubview(bufferProgressView)
        imageView.addSubview(slider)
        imageView.addSubview(totalTimeLabel)
        imageView.addSubview(screenButton)
        
        playButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(imageView)
            make.left.equalTo(10)
            make.width.height.equalTo(40)
        }
        
        currentTimeLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(imageView)
            make.left.equalTo(playButton.snp.right)
            make.width.equalTo(40)
        }

        bufferProgressView.snp.makeConstraints { (make) in
            make.centerY.equalTo(imageView)
            make.left.equalTo(currentTimeLabel.snp.right).offset(10)
            make.right.equalTo(totalTimeLabel.snp.left).offset(-10)
        }

        slider.snp.makeConstraints { (make) in
            make.left.right.equalTo(bufferProgressView)
            make.centerY.equalTo(bufferProgressView.snp.centerY).offset(-1)
        }

        totalTimeLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(imageView)
            make.right.equalTo(screenButton.snp.left)
            make.width.equalTo(40)
        }
        
        screenButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(imageView)
            make.right.equalTo(-10)
            make.width.height.equalTo(40)
        }
        return imageView
    }()
    
    /// 左下角播放按钮
    lazy var playButton: UIButton = {
        var button = UIButton(type: UIButtonType.custom)
        button.setImage(Bundle.bundleImage(named: "ZNPlayer_Pause"), for: .normal)
        button.setImage(Bundle.bundleImage(named: "ZNPlayer_Play"), for: .selected)
        button.addTarget(self, action: #selector(clickPlayButtonAction(button:)), for: .touchUpInside)
        return button
    }()
    
    /// 当前播放时间
    lazy var currentTimeLabel: UILabel = {
        var label = UILabel.init()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .center
        label.text = "00:00"
        return label
    }()
    
    /// 进度条滑块
    lazy var slider: UISlider = {
        var slider = UISlider.init()
        slider.setThumbImage(Bundle.bundleImage(named: "ZNPlayer_Slider"), for: .normal)
        slider.maximumValue = 1
        slider.minimumValue = 0
        slider.minimumTrackTintColor = UIColor.white
        slider.maximumTrackTintColor = UIColor.init(white: 1, alpha: 0.15)
        slider.addTarget(self, action: #selector(sliderTouchBegin), for: UIControlEvents.touchDown)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: UIControlEvents.valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchEnd), for: [.touchCancel, .touchUpInside, .touchUpOutside])
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(sliderTap(tap:)))
        slider.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer.init(target: self, action: nil)
        pan.delegate = self
        pan.maximumNumberOfTouches = 1
        pan.delaysTouchesBegan = true
        pan.delaysTouchesEnded = true
        pan.cancelsTouchesInView = true
        slider.addGestureRecognizer(pan)

        return slider
    }()
    
    /// 是否正在拖拽进度条
    var isDragged = false
    
    /// 缓冲进度条
    lazy var bufferProgressView: UIProgressView = {
        var progressView = UIProgressView.init(progressViewStyle: UIProgressViewStyle.default)
        progressView.progressTintColor = UIColor.init(white: 1, alpha: 0.3)
        progressView.trackTintColor = UIColor.clear
        return progressView
    }()
    
    /// 总时长
    lazy var totalTimeLabel: UILabel = {
        var label = UILabel.init()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "00:00"
        label.textAlignment = .center
        return label
    }()

    /// 全屏按钮
    lazy var screenButton: UIButton = {
        var button = UIButton(type: UIButtonType.custom)
        button.setImage(Bundle.bundleImage(named: "ZNPlayer_FullScreen"), for: .normal)
        button.setImage(Bundle.bundleImage(named: "ZNPlayer_ShrinkScreen"), for: .selected)
        button.addTarget(self, action: #selector(clickScreenButtonAction(button:)), for: .touchUpInside)
        return button
    }()
    
    /// 是否播放结束
    var playeEnd = false
    
    /// 控制层是否显示
    var isShowing = false
    
    
    // MARK: - life scyle
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(topImageView)
        self.addSubview(repeatButton)
        self.addSubview(bottomImageView)
        
        topImageView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self)
            make.height.equalTo(50)
        }
        
        repeatButton.snp.makeConstraints { (make) in
            make.center.equalTo(self)
            make.size.equalTo(CGSize(width: 30, height: 45))
        }
        
        bottomImageView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalTo(self)
            make.height.equalTo(50)
        }
        
        self.zn_playerResetControlView()
        self.hideControlView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    //MARK: - Response
    @objc func clickPlayButtonAction(button: UIButton) {
        button.isSelected = !button.isSelected
        self.pcvDelegate?.zn_controlView?(view: self, playAction: button)
    }
    
    @objc func clickRepeatButtonAction(button: UIButton) {
        self.zn_playerResetControlView()
        self.pcvDelegate?.zn_controlView?(view: self, repeatAction: button)
        self.autoFadeOutControlView()
    }
    
    @objc func clickScreenButtonAction(button: UIButton) {
        button.isSelected = !button.isSelected
        self.hideControlView()
        self.pcvDelegate?.zn_controlView?(view: self, fullScreenAction: button)
    }

    @objc func clickFailButtonAction(button: UIButton) {
        button.isHidden = true
        self.pcvDelegate?.zn_controlView?(view: self, failAction: button)
    }
    
    // MARK: - Slider
    @objc func sliderTap(tap: UITapGestureRecognizer) {
        let view = tap.view
        if view == slider {
            let point = tap.location(in: view)
            let length = view?.frame.size.width
            let tapValue = Float.init(point.x / length!)
            self.pcvDelegate?.zn_controlView?(view: self, sliderTapValue: tapValue)
        }
    }
    
    @objc func sliderTouchBegin(slider: UISlider) {
        self.pcvDelegate?.zn_controlView?(view: self, sliderTouchBegain: slider)
    }
    
    @objc func sliderValueChanged(slider: UISlider) {
        self.pcvDelegate?.zn_controlView?(view: self, sliderValueChanged: slider)
    }
    
    @objc func sliderTouchEnd(slider: UISlider) {
        self.pcvDelegate?.zn_controlView?(view: self, sliderTouchEnd: slider)
    }
    
    
    // MARK: - Private Method
    func showControlView() {
        self.isShowing = true
        self.topImageView.alpha    = 1
        self.bottomImageView.alpha = 1
        self.backgroundColor = UIColor.init(white: 0, alpha: 0.15)
    }
    
    func hideControlView() {
        self.isShowing = false
        self.backgroundColor = UIColor.clear
        if self.playeEnd {
            self.topImageView.alpha = 1
            self.bottomImageView.alpha = 1
        } else {
            self.topImageView.alpha = 0
            self.bottomImageView.alpha = 0
        }
    }
    
    func autoFadeOutControlView() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(zn_playerHideControlView), object: nil)
        self.perform(#selector(zn_playerHideControlView), with: nil, afterDelay: ZNPlayerAnimationTimeInterval)
    }

}

extension ZNPlayerControlView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        let rect = self.slider.thumbRect(forBounds: self.slider.bounds, trackRect: self.slider.trackRect(forBounds: self.slider.bounds), value: self.slider.value)
        let point = touch.location(in: self.slider)
        if (touch.view is UISlider) { // 如果在滑块上点击就不响应pan手势
            if (point.x <= rect.origin.x + rect.size.width && point.x >= rect.origin.x) {
                return false
            }
        }
        return true
    }
}

extension ZNPlayerControlView {
   
    @objc func zn_playerShowOrHideControlView() {
        if (self.isShowing) {
            self.zn_playerHideControlView()
        } else {
            self.zn_playerShowControlView()
        }
    }
    
    @objc func zn_playerShowControlView() {
        self.zn_playerCancelAutoFadeOutControlView()
        UIView.animate(withDuration: ZNPlayerControlAutoFadeOutTimeInterval , animations: {
            self.showControlView()
        }) { (finished) in
            self.isShowing = true
            self.autoFadeOutControlView()
        }
    }
    
    @objc func zn_playerHideControlView() {
        self.zn_playerCancelAutoFadeOutControlView()
        UIView.animate(withDuration: ZNPlayerControlAutoFadeOutTimeInterval, animations: {
            self.hideControlView()
        }) { (finished) in
            self.isShowing = false
        }
    }
    
    @objc func zn_playerCancelAutoFadeOutControlView() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    @objc func zn_playerResetControlView() {
        self.slider.value = 0
        self.bufferProgressView.progress = 0
        self.currentTimeLabel.text = "00:00";
        self.repeatButton.isHidden = true
        self.failButton.isHidden = true
        self.backgroundColor = .clear
        self.playeEnd = false
    }
    
    @objc func zn_playerActivity(state: Bool) {
        
    }
    
    
    
    @objc func zn_playerPlayEnd() {
        self.repeatButton.isHidden = false
        self.playeEnd = true
    }
    
    @objc func zn_playerLoadFailed() {
        self.failButton.isHidden = false
    }
    
    @objc func zn_playerBufferProgress(progress: Float) {
        self.bufferProgressView.progress = progress
    }
    
    @objc func zn_playerCurrentTime(currentTime: Double, totalTime: Double, sliderValue: Float) {
        
        let current = Int.init(currentTime)
        let currentMin = current / 60
        let currentSec = current % 60
        
        let total = Int.init(totalTime)
        let totalMin = total / 60
        let totalSec = total % 60
        
        self.currentTimeLabel.text = String.init(format: "%02d:%02d", currentMin, currentSec)
        self.totalTimeLabel.text = String.init(format: "%02d:%02d", totalMin, totalSec)
        
        if isDragged {
            return
        }
        self.slider.value = sliderValue
    }
    
    @objc func zn_playerPlayButtonState(state: Bool) {
        self.playButton.isSelected = state
    }
    
    @objc func zn_playerDraggedTime(dragedSeconds: Float, totalTime: Float, isForward: Bool) {
        isDragged = true
        let draggedValue = dragedSeconds / totalTime
        self.slider.value = draggedValue
    }
    
    @objc func zn_playerDraggedEnd() {
        isDragged = false
    }
    
    
}


extension Bundle {
    class func bundleImage(named name: String) -> UIImage? {
        let bundle = Bundle(for: ZNBaseControlView.self)
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}



