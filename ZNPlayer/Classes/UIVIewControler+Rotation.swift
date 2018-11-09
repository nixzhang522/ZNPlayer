//
//  UIVIewControler+Rotation.swift
//  BoomEnglish
//
//  Created by xinpin on 2018/10/15.
//  Copyright © 2018年 Nix. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
    open override var shouldAutorotate: Bool {
        return false
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (self.topViewController?.supportedInterfaceOrientations)!
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return (self.topViewController?.preferredInterfaceOrientationForPresentation)!
    }
    
    open override var childViewControllerForStatusBarStyle: UIViewController? {
        return self.topViewController
    }
    
    open override var childViewControllerForStatusBarHidden: UIViewController? {
        return self.topViewController
    }
}

extension UITabBarController {
    
    open override var shouldAutorotate: Bool {
        let vc = self.viewControllers![self.selectedIndex]
        if vc is UINavigationController {
            let nav = vc as! UINavigationController
            return (nav.topViewController?.shouldAutorotate)!
        } else {
            return vc.shouldAutorotate
        }
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let vc = self.viewControllers![self.selectedIndex]
        if vc is UINavigationController {
            let nav = vc as! UINavigationController
            return (nav.topViewController?.supportedInterfaceOrientations)!
        } else {
            return vc.supportedInterfaceOrientations
        }
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        let vc = self.viewControllers![self.selectedIndex]
        if vc is UINavigationController {
            let nav = vc as! UINavigationController
            return (nav.topViewController?.preferredInterfaceOrientationForPresentation)!
        } else {
            return vc.preferredInterfaceOrientationForPresentation
        }
    }
}
