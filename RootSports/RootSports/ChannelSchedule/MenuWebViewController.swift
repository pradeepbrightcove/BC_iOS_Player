//
//  MenuWebViewController.swift
//  RootSports
//
//  Created by Sergii Shulga on 9/11/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit
import SafariServices

private enum Constants {
    static let backButtonTintColor = colorFromHex("#757575")
}

class MenuWebViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!

    var html: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        webView.delegate = self

        if let html = html {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    private func setupUI() {
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo-navigation.png"))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow-left-ic"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(onBack(_:)))
        navigationItem.leftBarButtonItem?.tintColor = Constants.backButtonTintColor
        navigationController?.navigationBar.barTintColor = UIColor.Branding.mainNavigationBg
    }

    // MARK: Actions

    @objc func onBack(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
}

extension MenuWebViewController: UIWebViewDelegate {
    func webView(_ webView: UIWebView,
                 shouldStartLoadWith request: URLRequest,
                 navigationType: UIWebView.NavigationType) -> Bool {
        if let requestUrl = request.url {
            if requestUrl.absoluteString != "about:blank" {
                let safari = SFSafariViewController(url: requestUrl)
                present(safari, animated: true)
                return false
            }
        }

        return true
    }
}
