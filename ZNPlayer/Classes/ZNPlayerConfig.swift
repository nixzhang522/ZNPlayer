//
//  ZNPlayerConfig.swift
//  BoomEnglish
//
//  Created by xinpin on 2018/10/15.
//  Copyright © 2018年 Nix. All rights reserved.
//

import Foundation
import UIKit

let ZNScreenWidth = UIScreen.main.bounds.width
let ZNScreenHeight = UIScreen.main.bounds.height

public struct ZNPlayerConfig {
    
    var placeholderImage: UIImage? = UIImage.init(named: "ZNPlayer_Placeholder")
    
    weak var fatherView: UIView?
    
    var mediaURL: URL?
    
    var controlView: UIView?
    
    var seekTime: Float = 0
    
    public init(fatherView: UIView, mediaURL: URL) {
        self.fatherView = fatherView
        self.mediaURL = mediaURL
    }
}
