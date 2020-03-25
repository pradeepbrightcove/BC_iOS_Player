//
//  GradientView.swift
//  RootSports
//
//  Created by Oleksandr Haidaiev on 8/23/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class GradientView: UIView {

    var colors: [UIColor] = [UIColor.white, UIColor.black] {
        didSet {
            setNeedsDisplay()
        }
    }
    var startPointRelative = CGPoint.zero {
        didSet {
            setNeedsDisplay()
        }
    }
    var endPointRelative = CGPoint(x: 0, y: 1) {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Overrides

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let colorsCg = colors.map({$0.cgColor})
        let start = CGPoint(x: startPointRelative.x * bounds.size.width,
                            y: startPointRelative.y * bounds.size.height)
        let end = CGPoint(x: endPointRelative.x * bounds.size.width,
                          y: endPointRelative.y * bounds.size.height)

        var colorLocations: [CGFloat] = []
        for counter in 0 ..< colors.count {
            let value = CGFloat(counter) / CGFloat(colors.count - 1)
            colorLocations.append(value)
        }

        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colorsCg as CFArray,
                                     locations: colorLocations) {
            context?.drawLinearGradient(gradient,
                                        start: start,
                                        end: end,
                                        options: CGGradientDrawingOptions(rawValue: 0))
        }
    }

    // MARK: - Private

    private func setup() {
        self.backgroundColor = UIColor.clear
    }
}
