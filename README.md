# ZNPlayer

#### 项目介绍
AVPlayer播放器学习~

## Author

Nix, 351235445@qq.com


> 用到播放器的界面需要添加下面代码来旋转屏幕
```
// MARK: - 屏幕旋转
extension PLPlayerViewController {

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
```
