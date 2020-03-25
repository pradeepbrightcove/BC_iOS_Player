//
//  Extensions.swift
//  RootSports
//
//  Created by Oleksandr Haidaiev on 8/16/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

extension UIColor {
    static let milkChocolate = colorFromHex("#5a1a1a")
    static let liveChannelsCellLowBright = UIColor(white: 1, alpha: 0.4)

    enum Branding {

        static let mainBg               = isATTApp ? colorFromHex("#353a3b") : colorFromHex("#161616")
        static let mainBrightBg         = isATTApp ? colorFromHex("#525556") : colorFromHex("#444444")
        static let mainNavigationBg     = isATTApp ? colorFromHex("#353a3b") : colorFromHex("#161616")
        static let mainBright           = isATTApp ? colorFromHex("#26a8e6") : colorFromHex("#b3191a")
        static let mainLowBright        = isATTApp ? colorFromHex("#37474f") : colorFromHex("#5a1a1a")
        static let mainVeryBright       = isATTApp ? colorFromHex("#4fc6ff") : colorFromHex("#e42426")

        static let mainLowDarkSeparator = isATTApp ? colorFromHex("#898B8B") : colorFromHex("#2f2f2f")
        static let mainDarkSeparator    = isATTApp ? colorFromHex("#494e4e") : UIColor.black

        static let errorButton          = isATTApp ? colorFromHex("#26a8e6") : colorFromHex("#b62025")
        static let errorBackground      = isATTApp ? colorFromHex("#353a3b") : colorFromHex("#ffffff")
        static let errorTitle           = isATTApp ? colorFromHex("#ffffff") : colorFromHex("#b62025")
        static let errorMessage         = isATTApp ? colorFromHex("#ffffff") : colorFromHex("#000000")
        static let debugErrorButton     = isATTApp ?
            colorFromHex("#ffffff").withAlphaComponent(0.4) : colorFromHex("#626262")

        static let liveChannelsCellBright         = isATTApp ? colorFromHex("#26a8e6") : colorFromHex("#b62025")
        static let recordedChannelsCellBright     = isATTApp ?
            colorFromHex("#ffffff").withAlphaComponent(0.4) : colorFromHex("#161616")
        static let selectedChannelsCellTitleColor = isATTApp ? colorFromHex("#26a8e6") : colorFromHex("#626262")

        static let gradientBottom                 = isATTApp ? colorFromHex("#353a3b") : UIColor.black
    }
}

extension UIButton {
    func addSpaceBetweenTitleAndImage(spacing: Double) { // TODO: add support if Image on left
        let insetAmount = CGFloat(spacing / 2)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount * 2, bottom: 0, right: insetAmount * 2)
    }
}

extension Date {
    var dayTimestamp: Int {

        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let midnight = calendar.startOfDay(for: self)

        return Int(midnight.timeIntervalSince1970)
    }

    func timeComponents(with formatter: DateFormatter) -> TimeComponents {
        let fullTime = formatter.string(from: self)
        var amPm: String?
        var digits = fullTime

        if !formatter.is24TimeFormat {
            if let amString = formatter.amSymbol, let rangeOfAm = fullTime.range(of: amString) {
                amPm = amString
                digits.removeSubrange(rangeOfAm)
            } else if let pmString = formatter.pmSymbol, let rangeOfPm = fullTime.range(of: pmString) {
                amPm = pmString
                digits.removeSubrange(rangeOfPm)
            }
            digits = digits.trimmingCharacters(in: .whitespaces)
        }
        return TimeComponents(amPm: amPm, digits: digits)
    }
}

extension DateFormatter {
    convenience init(format: String, locale: String? = nil) {
        self.init()
        self.dateFormat = format

        if let locale = locale {
            self.locale = Locale(identifier: locale)
        }
    }

    // 6:00 PM or 18:00 according to '24 time format' setting
    static func shortTimeUSFormatterWithDeviceSettings() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let sameFormat = formatter.dateFormat
        formatter.dateFormat = sameFormat // required or format will always be 'h:mm a' - looks like a bag in iOS
        formatter.locale = Locale(identifier: "en_US") // 'AM/PM' shouldn't be localizable
        return formatter
    }

    var is24TimeFormat: Bool {
        return self.dateFormat.range(of: "a") == nil
    }
}

extension UIImageView {
    func downloadedFrom(url: URL,
                        contentMode mode: UIView.ContentMode = .scaleAspectFit,
                        success: @escaping () -> Void) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)

                else {
                    return
            }

            DispatchQueue.main.async { () -> Void in
                self.image = image
                success()
            }

            }.resume()
    }

    func downloadedFrom(link: String,
                        contentMode mode: UIView.ContentMode = .scaleAspectFit,
                        success: @escaping () -> Void) {
        guard let url = URL(string: link) else {
            return
        }

        downloadedFrom(url: url, contentMode: mode, success: success)
    }
}

extension UIViewController {
    var isIPadLandscape: Bool {
        return self.view.bounds.size.width > self.view.bounds.size.height && UIDevice.current.userInterfaceIdiom == .pad
    }
}

extension UIScreen {
    static var isIPadLandscape: Bool {
        return isIpad && self.main.bounds.size.width > self.main.bounds.size.height
    }
}
