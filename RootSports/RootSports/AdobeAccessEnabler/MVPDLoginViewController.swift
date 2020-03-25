//
//  MVPDLoginViewController.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/17/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class MVPDLoginViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var loginUrl: String?

    var dismissCallback: BoolCompletion?

    var hasLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLoginView()

        webView.scrollView.backgroundColor = UIColor.white
        webView.backgroundColor = UIColor.white

        navigationItem.hidesBackButton = true
    }

    override func viewDidAppear(_ animated: Bool) {
        let loginURLRequest = URLRequest(url: URL(string: loginUrl!)!)

        webView.delegate = self
        webView.loadRequest(loginURLRequest)

        activityIndicator.startAnimating()
    }

    override func closeButtonPressed(_ sender: Any) {
        if let callback = dismissCallback {
            callback(false)
        }

        dismiss(animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if hasLoaded {
            zoomToFit()
        }
    }

    override func setupLoginView() {
        super.setupLoginView()

        let backButton = UIButton(type: .custom)
        let backButtonImage = UIImage(named: "arrow-left-ic")?.withRenderingMode(.alwaysTemplate)
        backButton.setImage(backButtonImage, for: .normal)
        backButton.addTarget(self, action: #selector(providerBackButtonPressed(_:)), for: [.touchUpInside])
        backButton.tintColor = Branding.loginNavigationBarItemTint
        backButton.sizeToFit()

        var containerFrame = backButton.bounds
        containerFrame.size.height += 10
        let backContainer = UIView(frame: containerFrame)
        backContainer.addSubview(backButton)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backContainer)
    }

    @objc func providerBackButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: UIWebViewDelegate
extension MVPDLoginViewController: UIWebViewDelegate {

    func webView(_ webView: UIWebView,
                 shouldStartLoadWith request: URLRequest,
                 navigationType: UIWebView.NavigationType) -> Bool {
        let absolutePath = request.url?.absoluteString
        //check for authn completion

        print("Should start load \(request)")

        if absolutePath == "adobepass://ios.app" {
            //authentication finished,
            //close the webview and attempt to fetch the authn token
            AccessEnablerManager.shared.handleExternalURL(absolutePath)

            if let callback = dismissCallback {
                callback(true)
            }

            self.dismiss(animated: true, completion: nil)

            return false
        }

        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicator.stopAnimating()

        hasLoaded = true

        zoomToFit()
    }

    func zoomToFit() {
        let scrollView = webView.scrollView

        let zoom = webView.bounds.size.width / scrollView.contentSize.width

        scrollView.minimumZoomScale = zoom

        scrollView.zoomScale = zoom
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
}
// MARK: End UIWebViewDelegate
