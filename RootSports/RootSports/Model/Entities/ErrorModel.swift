//
//  ErrorModel.swift
//  RootSports
//
//  Created by Olena Lysenko on 9/5/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

private enum Constants {
    static let messageKey = "Message"
    static let titleKey = "Title"
    static let extendedMessageKey = "ExtendedMessage"
    static let codeKey = "Code"
    static let iconClassKey = "IconClass"
}

enum ErrorIconClass: String {
    case subscription = "error__icon-subscription"
    case location = "error__icon-location"
    case unknown = "error__icon-unknown"
}

class ErrorModel: NSObject, NSCoding {
    var message = ErrorConstants.undefinedError
    var title = ErrorConstants.errorTitle
    var extendedMessage = ""
    var code = 0
    var iconClass: ErrorIconClass = .unknown

    override init() {
        super.init()
    }

    init?(fromDictionary dict: [String: Any]) {
        if let body = dict[ModelConstants.ErrorModelBodyField] as? String {

            do {
                let regex = try NSRegularExpression(pattern: "\\{(.*?)\\}", options: .caseInsensitive)
                let range = NSRange(location: 0, length: body.count)
                let newBody = regex.stringByReplacingMatches(in: body, options: [], range: range, withTemplate: "%@")

                self.message = newBody

            } catch {
                self.message = body
            }
        }

        if let recoverySuggestion = dict[ModelConstants.ErrorModelRecoveryField] as? String {
            self.extendedMessage = recoverySuggestion
        }

        if let header = dict[ModelConstants.ErrorModelHeaderField] as? String {
            self.title = header
        }

        if let code = dict[ModelConstants.ErrorModelCodeField] as? NSNumber {
            self.code = code.intValue
        }

        if let icon = dict[ModelConstants.ErrorModelIconField] as? String {
            switch icon {
            case ErrorIconClass.location.rawValue:
                self.iconClass = .location
            case ErrorIconClass.subscription.rawValue:
                self.iconClass = .subscription
            default:
                break
            }
        }
    }

    // MARK: NSCoding

    required convenience init?(coder aDecoder: NSCoder) {

        guard let message = aDecoder.decodeObject(forKey: Constants.messageKey) as? String,
            let title = aDecoder.decodeObject(forKey: Constants.titleKey) as? String,
            let extMessage = aDecoder.decodeObject(forKey: Constants.extendedMessageKey) as? String,
            let iconClass = aDecoder.decodeObject(forKey: Constants.iconClassKey) as? String  else { return nil }

        self.init()
        self.message = message
        self.title = title
        self.extendedMessage = extMessage
        self.code = aDecoder.decodeInteger(forKey: Constants.codeKey)
        self.iconClass = ErrorIconClass(rawValue: iconClass)!
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.message, forKey: Constants.messageKey)
        aCoder.encode(self.title, forKey: Constants.titleKey)
        aCoder.encode(self.extendedMessage, forKey: Constants.extendedMessageKey)
        aCoder.encode(self.code, forKey: Constants.codeKey)
        aCoder.encode(self.iconClass.rawValue, forKey: Constants.iconClassKey)
    }
}
