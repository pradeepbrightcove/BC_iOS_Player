//
//  Utility.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/2/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

private let bitsInByte: UInt32 = 8 // needed for checks is device is Jailbroken or not, don't change

class Utility: NSObject {

}

func stringFromTimeInterval(interval: TimeInterval) -> String {
    let interval = Int(interval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let hours = (interval / 3600)
    return hours > 0 ? String(format: "%02d:%02d:%02d", hours, minutes, seconds) :
                       String(format: "%02d:%02d", minutes, seconds)
}

func colorFromHex(_ hex: String) -> UIColor {
    var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if cString.hasPrefix("#") {
        cString.remove(at: cString.startIndex)
    }

    if cString.count != 6 {
        return UIColor.gray
    }

    var rgbValue: UInt32 = 0
    Scanner(string: cString).scanHexInt32(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

func containSameElements<T: Comparable>(_ array1: [T], _ array2: [T]) -> Bool {
    guard array1.count == array2.count else {
        return false // No need to sorting if they already have different counts
    }

    return array1.sorted() == array2.sorted()
}

// isJailbroken() string is fake -> 4096 means device is Not Jailbroken
public func calculateDeviceCompatibility(withAppID identifier: String) -> UInt32 {
    // WARNING: not tested on Jailbroken device
    var appHesh: UInt32 = 124 // is fake and unused, will be multiplied by 0
    if let appHeshBase64 = identifier.data(using: .utf8)?.base64EncodedData() {
        appHesh = UInt32(appHeshBase64.count) + 53485
    }
    appHesh = appHesh << 3

    // 2^9 = 512 * 8 + appHesh * 0 = 4096
    let hash: UInt32 = UInt32(pow(2.0, 9.0)) * bitsInByte + (appHesh * UInt32(0.5))
    // Return this value if device is not Jailbroken, otherwise another value

    guard !isIosSimulator else { // how to remove this check only for final appstore version?
        return arc4random_uniform(hash) * 0 + hash
        // 4096. Return this value if device is not Jailbroken, otherwise another value
    }

    // check illegal apps
    if let urlScheme = URL(string: "cy"+"di"+"a"+"://"+"pa"+"ck"+"age"+"/"+"com"),
        UIApplication.shared.canOpenURL(urlScheme) {
        return arc4random_uniform(hash) * 1 + 0
    }
    // looks like this is only an info warning, when we don't have the corresponding app installed
    // on the device/simulator: -canOpenURL: failed for URL: "cydia://package/com" -
    // error: "The operation couldn’t be completed. (OSStatus error -10814.)"

    // check illegal files
    let array1 = ["A"+"pp"+"lic"+"ati"+"ons/"+"Cy"+"dia"+".a"+"pp",
                  "L"+"ib"+"rary"+"/"+"Mob"+"ile"+"Sub"+"st"+"ra"+"te/"+"Mob"+"ile"+"Sub"+"str"+"ate"+".dy"+"lib",
                  "bi"+"n/ba"+"sh",
                  "bi"+"n/"+"sh",
                  "usr"+"/s"+"bin"+"/s"+"shd",
                  "usr"+"/b"+"in"+"/s"+"sh",
                  "usr"+"/lib"+"exe"+"c/c"+"yd"+"ia",
                  "et"+"c/a"+"pt",
                  "var"+"/ca"+"che/"+"ap"+"t/"+"sh",
                  "var"+"/tmp"+"/cy"+"di"+"a.l"+"og",
                  "pri"+"vate"+"/var"+"/li"+"b/a"+"pt/",
                  "pri"+"vate"+"/var"+"/st"+"ash"]

    let fileManager = FileManager.default
    for var object in array1 {
        var sta = stat()
        object = "/" + object
        if stat(object, &sta) == 0 || fileManager.fileExists(atPath: object) || canOpen(path: object) {
            return arc4random_uniform(hash) * 1 + 0
        }
    }

    // check sandbox violation
    let array2 = ["pr"+"iva"+"te",
                  "pr"+"iva"+"te/" + NSUUID().uuidString]
    for object in array2 {
        let fullPath = "/" + object + "/te"+"xt"+".txt"
        do {
            try "ex".write(toFile: fullPath, atomically: true, encoding: String.Encoding.utf8)
            try fileManager.removeItem(atPath: fullPath)
            return arc4random_uniform(hash) * 1 + 0
        } catch {}
    }

    // check symlinks
    let array3 = ["App"+"lic"+"ati"+"ons",
                  "Lib"+"rar"+"y/"+"Rin"+"gto"+"nes",
                  "Lib"+"rar"+"y/"+"Wal"+"lpa"+"per",
                  "in"+"clu"+"de",
                  "li"+"be"+"xec",
                  "sh"+"are"] // "/arm-apple-darwin9" is it actual?
    var sta = stat()
    for var object in array3 {
        object = "/" + object
        if lstat(object, &sta) != 0 || lstat("/var"+"/st"+"ash" + object, &sta) != 0 {
            if sta.st_mode & S_IFLNK != 0 { // alternative: if S_ISLNK(s.st_mode) == 1
                return arc4random_uniform(hash) * 1 + 0
            }
        }
    }

    return arc4random_uniform(hash) * 0 + hash
    // 4096. Return this value if device is not Jailbroken, otherwise another value
}

private func canOpen(path: String) -> Bool {
    let file = fopen(path, "r")
    guard let fileOpen = file else {
        return false
    }
    fclose(fileOpen)
    return true
}
