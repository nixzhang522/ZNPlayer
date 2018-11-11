//
//  ZNLoadingView.swift
//  ZNPlayer_Example
//
//  Created by xinpin on 2018/10/17.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import TrafficPolice

class ZNLoadingView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    lazy var loadingView: UIView = {
        var loadingView = UIView.init(frame: CGRect.zero)
        return loadingView
    }()
    
    var loadingColor: UIColor = UIColor.white
    var lineWidth: CGFloat = 2.5
    var radius: CGFloat = 12.5
    var circleLayer: CAShapeLayer?
    
    lazy var speedLabel: UILabel = {
        var speedLabel = UILabel.init(frame: .zero)
        speedLabel.textColor = .white
        speedLabel.font = UIFont.systemFont(ofSize: 12)
        return speedLabel
    }()
    
    var isAnimation = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isHidden = true

        self.addSubview(self.loadingView)
        self.addSubview(speedLabel)
        
        loadingView.snp.makeConstraints { (make) in
            make.centerX.top.equalTo(self)
            make.width.height.equalTo((lineWidth + radius) * 2)
        }
        
        speedLabel.snp.makeConstraints { (make) in
            make.centerX.bottom.equalTo(self)
        }
        
        TrafficManager.shared.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Public
    func startAnimation() {
        if isAnimation {
            return
        }
        
        let shapelayer = CAShapeLayer.init()
        self.circleLayer = shapelayer
        let width = CGFloat((radius + lineWidth) * 2)
        self.circleLayer?.frame = CGRect(x: 0, y: 0, width: width, height: width)
    
        let path = UIBezierPath.init(arcCenter: CGPoint(x: width * 0.5, y: width * 0.5), radius: width * 0.5, startAngle: 0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
        shapelayer.path = path.cgPath
        shapelayer.fillColor = UIColor.clear.cgColor
        shapelayer.strokeColor = self.loadingColor.cgColor
        shapelayer.lineWidth = self.lineWidth
        self.loadingView.layer.addSublayer(shapelayer)
        
        let anima = CABasicAnimation.init(keyPath: "strokeEnd")
        anima.fromValue = 0.0
        anima.toValue = 1.0
        anima.duration = 1.5
        anima.repeatCount = MAXFLOAT
        anima.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        anima.autoreverses = true
        anima.isRemovedOnCompletion = false
        shapelayer.add(anima, forKey: "strokeEndAniamtion")
        
        let anima2 = CABasicAnimation.init(keyPath: "transform.rotation.z")
        anima2.toValue = -Double.pi * 2
        anima2.duration = 0.8
        anima2.repeatCount = MAXFLOAT
        anima2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        self.loadingView.layer.add(anima2, forKey: "rotaionAniamtion")
        
        isAnimation = true
        self.isHidden = false
        
        TrafficManager.shared.start()
    }
    
    func stopAnimation() {
        guard isAnimation else {
            return
        }
        
        self.circleLayer?.removeAllAnimations()
        self.circleLayer?.removeFromSuperlayer()
        self.loadingView.layer.removeAllAnimations()

        isAnimation = false
        self.isHidden = true

        TrafficManager.shared.cancel()
    }
}

extension ZNLoadingView: TrafficManagerDelegate {
    func post(summary: TrafficSummary) {
        //print(summary)
        // wifi:[speed:[download: 0.1 KB/s, upload: 0.0 KB/s], data:[received: 14.9 KB, sent: 13.2 KB]],
        // wwan:[speed:[download: 0.0 KB/s, upload: 0.0 KB/s], data:[received: 0.0 KB, sent: 0.0 KB]]
        
        // Do whatever you want here!

        let speed = summary.wifi.speed.received.unitString
        speedLabel.text = "\(speed)/s"
    }
}
