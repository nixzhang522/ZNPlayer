//
//  ZNPlayerControlViewDelegate.swift
//  BoomEnglish
//
//  Created by xinpin on 2018/10/12.
//  Copyright © 2018年 Nix. All rights reserved.
//

import Foundation
import UIKit

@objc protocol ZNPlayerControlViewProtocol: NSObjectProtocol {
    
    @objc optional func zn_playerCurrentTime(currentTime: Double, totalTime: Double, sliderValue: Float)
    @objc optional func zn_playerPlayEnd()
    @objc optional func zn_playerPlayButtonState(state: Bool)
    @objc optional func zn_playerBufferProgress(progress: Float)
    @objc optional func zn_playerLoadFailed()
    @objc optional func zn_playerActivity(state: Bool)
    
    @objc optional func zn_playerDraggedTime(dragedSeconds: Float, totalTime: Float, isForward: Bool)
    @objc optional func zn_playerDraggedEnd()
    
    @objc optional func zn_playerShowOrHideControlView()
    @objc optional func zn_playerShowControlView()
    @objc optional func zn_playerHideControlView()
    @objc optional func zn_playerResetControlView()
    @objc optional func zn_playerCancelAutoFadeOutControlView()
    
}

public class ZNBaseControlView: UIView, ZNPlayerControlViewProtocol {
    
    weak var pcvDelegate: ZNPlayerControlViewDelegate?
    
}

@objc protocol ZNPlayerControlViewDelegate: NSObjectProtocol {
    
    @objc optional func zn_controlView(view: UIView, backAction backButton: UIButton)
    @objc optional func zn_controlView(view: UIView, playAction playButton: UIButton)
    @objc optional func zn_controlView(view: UIView, repeatAction repeatButton: UIButton)
    @objc optional func zn_controlView(view: UIView, failAction failButton: UIButton)
    @objc optional func zn_controlView(view: UIView, sliderTapValue sliderValue: Float)
    @objc optional func zn_controlView(view: UIView, sliderTouchBegain slider: UISlider)
    @objc optional func zn_controlView(view: UIView, sliderValueChanged slider: UISlider)
    @objc optional func zn_controlView(view: UIView, sliderTouchEnd slider: UISlider)
    @objc optional func zn_controlView(view: UIView, fullScreenAction fullScreenButton: UIButton)
    
}
