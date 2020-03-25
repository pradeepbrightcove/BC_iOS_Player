//
//  ViewController.swift
//  RootSports
//
//  Created by Pradeep Nanjappan on 05/02/20.
//  Copyright © 2020 Ooyala. All rights reserved.
//


import UIKit
import BrightcovePlayerSDK


     let PlaybackServicePolicyKey = "BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm"
    let AccountID = "3636334163001"
     let VideoID = "3666678807001"


class ViewController: UIViewController {
    // should be set during presentation
    weak var presentedByViewController: BaseViewController!
    var programs = [AuthorizedProgram]()
    var activeProgram: AuthorizedProgram?
     public var shouldAutoPlayWhenReady = true
    var viewController = BCOVPUIBasicControlView()
  //  private var controlViewController: ControlsViewController?
    
    @IBOutlet private var videoContainer: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private lazy var playbackService: BCOVPlaybackService = {
        return BCOVPlaybackService(accountId: AccountID, policyKey: PlaybackServicePolicyKey)
    }()
   
    private lazy var playbackController: BCOVPlaybackController? = {
        guard let vc = BCOVPlayerSDKManager.shared()?.createPlaybackController() else {
            return nil
        }
        vc.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        vc.delegate = self
        vc.isAutoAdvance = true
        vc.isAutoPlay = true
        vc.allowsExternalPlayback = true
        vc.add(self.controlsViewController)
        return vc
    }()
    
    private lazy var videoView: UIView = {
        let view = UIView()
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return view
    }()
    
    private lazy var controlsViewController: ControlsViewController = {
        let vc = ControlsViewController()
        vc.delegate = self
        return vc
    }()
    
    private lazy var fullscreenViewController: UIViewController = {
        return UIViewController()
    }()
    
    private lazy var standardVideoViewConstraints: [NSLayoutConstraint] = {
        return [
            videoView.topAnchor.constraint(equalTo: self.videoContainer.topAnchor),
            videoView.rightAnchor.constraint(equalTo: self.videoContainer.rightAnchor),
            videoView.leftAnchor.constraint(equalTo: self.videoContainer.leftAnchor),
            videoView.bottomAnchor.constraint(equalTo: self.videoContainer.bottomAnchor)
        ]
    }()
    
    private lazy var fullscreenVideoViewConstraints: [NSLayoutConstraint] = {
        var insets = UIEdgeInsets.zero
        if #available(iOS 11, *) {
            insets = view.safeAreaInsets
        }
        return [
            videoView.topAnchor.constraint(equalTo: self.fullscreenViewController.view.topAnchor, constant:insets.top),
            videoView.rightAnchor.constraint(equalTo: self.fullscreenViewController.view.rightAnchor),
            videoView.leftAnchor.constraint(equalTo: self.fullscreenViewController.view.leftAnchor),
            videoView.bottomAnchor.constraint(equalTo: self.fullscreenViewController.view.bottomAnchor, constant:-insets.bottom)
        ]
    }()
    
    // MARK: - View Lifecyle
    
    override func viewDidLoad() {
        super.viewDidLoad()

         controlsViewController.playerControlsVCDelegate = self
        controlsViewController.programs = self.programs
       controlsViewController.activeProgram = self.activeProgram
        guard let playbackController = playbackController else {
            return
        }
        
        // Add the playbackController view
        // to videoView and setup its constraints
        videoView.addSubview(playbackController.view)
        playbackController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playbackController.view.topAnchor.constraint(equalTo: self.videoView.topAnchor),
            playbackController.view.rightAnchor.constraint(equalTo: self.videoView.rightAnchor),
            playbackController.view.leftAnchor.constraint(equalTo: self.videoView.leftAnchor),
            playbackController.view.bottomAnchor.constraint(equalTo: self.videoView.bottomAnchor)
            ])
        
        // Setup controlsViewController by
        // adding it as a child view controller,
        // adding its view as a subview of videoView
        // and adding its constraints
        addChild(controlsViewController)
        videoView.addSubview(controlsViewController.view)
        controlsViewController.didMove(toParent: self)
        controlsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controlsViewController.view.topAnchor.constraint(equalTo: self.videoView.topAnchor),
            controlsViewController.view.rightAnchor.constraint(equalTo: self.videoView.rightAnchor),
            controlsViewController.view.leftAnchor.constraint(equalTo: self.videoView.leftAnchor),
            controlsViewController.view.bottomAnchor.constraint(equalTo: self.videoView.bottomAnchor)
            ])
        
        // Then add videoView as a subview of videoContainer
        videoContainer.addSubview(videoView)
        
        // Activate the standard view constraints
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(standardVideoViewConstraints)
        
        requestContentFromPlaybackService()
        
        addObservers()
    }
    func addObservers() {

        if !isIpad {
            rotate()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(rotate),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
        }
    }
    @objc func rotate() {
        let newTransform = transformForCurrentOrientation()
        
        if view.transform != newTransform {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.transform = newTransform
            })
        }
    }
    
    override var shouldAutorotate: Bool {
        return isIpad
    }

    
    func transformForCurrentOrientation() -> CGAffineTransform {
        if UIDevice.current.orientation == .landscapeLeft {
            return CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        }
        if UIDevice.current.orientation == .landscapeRight {
            return CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        }
        if view.transform == CGAffineTransform.identity {
            return CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        }
        return view.transform
    }
    
    func play(program: AuthorizedProgram, forcePlay: Bool = true) {
        play(programCode: program.programCode,
             channelCode: program.channelCode,
             resourceId: program.resourceId,
             forcePlay: forcePlay)
    }
    
    private func play(programCode: String,
              channelCode: String,
              resourceId: String,
              forcePlay: Bool = true) {
         let getProgramDataAndPlay = {
            let regionCode: String! = CoreServices.shared.scheduleProvider.regionCode
            
            CoreServices.shared.authorizationProvider.programMeta(programCode: programCode,
                                                                  channelCode: channelCode,
                                                                  regionCode: regionCode,
                                                                  completion: { [weak self] (programs, error) in
             DispatchQueue.main.async {
                // let ignoreError = false
                LoaderViewManager.sharedInstance.stopAnimation()
                // this will be executed only at the end of current DispatchQueue.main.async {}
                // and looks like this is excess
                //var ignoreError = false
                if let error = error as? ServerLogicalError,
                    error == ServerLogicalError.noProgramsOnAir,
                    let programs = programs,
                    programs.count > 0 {
                    for program in programs where program.channelCode == channelCode {
                        //ignoreError = true
                        break
                    }
                }

            }
        })
        }
        if AccessEnablerManager.shared.isAuthorizedForResources([resourceId]) {
            getProgramDataAndPlay()
            //playActiveProgram(forcePlay: forcePlay)
        } else {
            process(error: ServerLogicalError.authZFailure, forPrograms: nil)
        }
    }
    

    fileprivate func process(error: Error, forPrograms programs: [AuthorizedProgram]?) {
        //playerViewController.player.pause()
        
        var context = [ContextKey.mvpd: AccessEnablerManager.shared.mvpdName ?? "MVPD"]
        
        if let programs = programs, let name = programs.first?.programTitleBrief {
            self.programs = programs
            activeProgram = programs.first
            context[ContextKey.alternate] = name
        }
        
        //handle(error: error, context: context as AnyObject)
    }
    
    fileprivate func resourceIdForChannelCode(_ channelCode: String) -> String {
        for program in programs where program.channelCode == channelCode {
            return program.resourceId
        }
        return activeProgram?.resourceId ?? ""
    }
    // MARK: - Misc
    
    private func requestContentFromPlaybackService() {
        playbackService.findVideo(withVideoID:VideoID, parameters: nil) { [weak self] (video: BCOVVideo?, json: [AnyHashable:Any]?, error: Error?) in
            
            if let video = video {
                self?.playbackController?.setVideos([video] as NSFastEnumeration)
            }
            
            if let error = error {
                print("ViewController Debug - Error retrieving video playlist: \(error.localizedDescription)")
            }
            
        }
    }
    
    
}

// MARK: - BCOVPlaybackControllerDelegate

extension ViewController: BCOVPlaybackControllerDelegate {
    
    func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
        print("ViewController Debug - Advanced to new session.")
    }
    
}

// MARK: - ControlsViewControllerFullScreenDelegate





extension ViewController: ControlsViewControllerFullScreenDelegate {
    
    func handleExitFullScreenButtonPressed() {
        dismiss(animated: false) {
            
            self.addChild(self.controlsViewController)
            self.videoContainer.addSubview(self.videoView)
            NSLayoutConstraint.deactivate(self.fullscreenVideoViewConstraints)
            NSLayoutConstraint.activate(self.standardVideoViewConstraints)
            self.controlsViewController.didMove(toParent: self)
            
        }
    }
    
    func handleEnterFullScreenButtonPressed() {
        fullscreenViewController.addChild(controlsViewController)
        fullscreenViewController.view.addSubview(videoView)
        NSLayoutConstraint.deactivate(self.standardVideoViewConstraints)
        NSLayoutConstraint.activate(self.fullscreenVideoViewConstraints)
        controlsViewController.didMove(toParent: fullscreenViewController)
        
        present(fullscreenViewController, animated: false, completion: nil)
    }
    
}




extension ViewController: PlayerControlsViewControllerDelegate {
    func playerControlsVCDidBack(_ playerControlsVC: UIViewController) {
        dismiss(animated: true)  {
            return true
            //CoreServices.shared.firebaseService.remove(observer: self as! FirebaseServiceObserver) //OS: to avoid retain cycle
            
        }
    }
    
    func playerControls(_ playerControlsVC: LiveChannelsViewController, didChangeActiveProgram program: AuthorizedProgram) {
    print ("Hello, World!")
    }

    func playerControlsDidStartPlayer(_ playerControlsVC: ControlsViewController) {
        print ("Hello, World!")
    }

    
}
