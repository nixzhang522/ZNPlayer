//
//  ViewController.swift
//  ZNPlayer
//
//  Created by Nix on 11/09/2018.
//  Copyright (c) 2018 Nix. All rights reserved.
//

import UIKit
import ZNPlayer

class ViewController: UIViewController {

    @IBOutlet weak var playerContainerView: UIView!
    
    lazy var playerView: ZNPlayer = {
        var player = ZNPlayer.init(frame: CGRect.zero)
        player.config = self.config
        return player
    }()
    
    lazy var config: ZNPlayerConfig = {
        let controlView = ZNPlayerControlView.init(frame: .zero)
        
        let url = "https://cdn-files-prod.boomschool.cn/boom-en-china-prod/scene/21/video_content_low/DuK6aNv_Tje0f8skcuejmg==.m4v"
        //let url = "https://cdn-files-prod.boomschool.cn/boom-en-china-prod/scenario/scene/19/video_content/7kSu3IqVT7qHnJ1WLrB_wA==.m4v"
        let config = ZNPlayerConfig.init(fatherView: playerContainerView, mediaURL: URL.init(string: url)!)
        return config
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.playerView.autoPlay()
    }
    
    deinit {
        print("PLPlayerViewController deinit")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - 屏幕旋转
extension ViewController {
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}
