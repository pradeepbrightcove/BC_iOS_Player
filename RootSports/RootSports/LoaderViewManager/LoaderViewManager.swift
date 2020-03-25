//
//  LoaderViewManager.swift
//  RootSports
//
//  Created by Artak on 8/11/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

private enum LoaderViewConstants {
    static let attImageCount: Int = 47
    static let rootSportsImageCount = 44
    static let animationDuration: Double = 1.8
    static let windowBackgroundColor = UIColor.black.withAlphaComponent(0.6)

}

class LoaderViewManager: UIView {
    fileprivate var loaderImageView: UIImageView!
    fileprivate var loaderCount: Int = 0
    fileprivate var isAnimating = false

    static let sharedInstance = LoaderViewManager()

    init() {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = LoaderViewConstants.windowBackgroundColor

        var images: [UIImage] = [UIImage]()
        let imageCount = isATTApp ? LoaderViewConstants.attImageCount : LoaderViewConstants.rootSportsImageCount
        for counter in 0 ... imageCount {
            images.append(UIImage(named: "Loader_\(counter)")!)
        }

        loaderImageView = UIImageView(image: UIImage(named: "Loader_0"))
        loaderImageView.animationImages = images
        loaderImageView.animationDuration = LoaderViewConstants.animationDuration
        loaderImageView.center = center
        addSubview(loaderImageView)

        loaderImageView.translatesAutoresizingMaskIntoConstraints = true
        loaderImageView.autoresizingMask = [.flexibleLeftMargin,
                                            .flexibleRightMargin,
                                            .flexibleTopMargin,
                                            .flexibleBottomMargin]

        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.flexibleWidth,
                            .flexibleHeight,
                            .flexibleLeftMargin,
                            .flexibleRightMargin,
                            .flexibleTopMargin,
                            .flexibleBottomMargin]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation() {
        DispatchQueue.main.async {
            self.loaderCount += 1

            if self.isAnimating {
                return
            }

            self.frame = UIScreen.main.bounds
            self.loaderImageView.startAnimating()
            self.isAnimating = true

            guard let delegate = UIApplication.shared.delegate as? AppDelegate, let window = delegate.window else {
                assertionFailure("\(self): can't add view to window")
                return
            }

            window.addSubview(self)
        }
    }

    func stopAnimation() {
        DispatchQueue.main.async {
            self.loaderCount -= 1

            if !self.isAnimating || self.loaderCount > 0 {
                return
            }

            self.removeFromSuperview()
            self.loaderImageView.stopAnimating()
            self.isAnimating = false
        }
    }

    func stopAll() {
        DispatchQueue.main.async {
            self.removeFromSuperview()
            self.loaderImageView.stopAnimating()
            self.isAnimating = false
            self.loaderCount = 0
        }
    }
}
