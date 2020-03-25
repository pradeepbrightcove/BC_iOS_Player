//
//  ControlsViewController.swift
//  RootSports
//
//  Created by Pradeep Nanjappan on 05/02/20.
//  Copyright © 2020 Ooyala. All rights reserved.
//



import UIKit

import BrightcovePlayerSDK


protocol PlayerControlsViewControllerDelegate: NSObjectProtocol {
    func playerControlsVCDidBack(_ playerControlsVC: UIViewController)
    func playerControls(_ playerControlsVC: LiveChannelsViewController,
                        didChangeActiveProgram program: AuthorizedProgram)
    func playerControlsDidStartPlayer(_ playerControlsVC: ControlsViewController)
}

private enum PlayerControlsVCConstants {
    static let channelBottomConstraintHidden: CGFloat = -70.0
    static let channelBottomConstraintShown: CGFloat = 0.0
    static let ownControlsHideTimout: Double = 9.2
    static let sliderMaxOpacity: CGFloat = 0.37
    
    static let nibName = "ControlsViewController"
    
    static let dimColor = UIColor.black.withAlphaComponent(0.4)
    
    static let controlsAnimationDuration = 0.3
    
    static let ccTableRowHeight = 44.0
    static let ccTableHeaderHeight = 60.0
    static let ccTableWidth = 250.0
    
    static let SelectedCCLanguageKey = "SelectedCCLanguage"
}


fileprivate struct ControlConstants {
    static let VisibleDuration: TimeInterval = 5.0
    static let AnimateInDuration: TimeInterval = 0.1
    static let AnimateOutDuraton: TimeInterval = 0.2
}
//class ControlsViewController: UIViewController ,UIPopoverPresentationControllerDelegate
class ControlsViewController: UIViewController ,UIPopoverPresentationControllerDelegate {
  
    let audioSession = AVAudioSession.sharedInstance()
    weak var delegate: ControlsViewControllerFullScreenDelegate?
    private weak var currentPlayer: AVPlayer?
    weak var playerControlsVCDelegate: PlayerControlsViewControllerDelegate?
  
    @IBOutlet weak var volumeIndicator: VolumeIndicatorView!
    @IBOutlet private weak var controlsContainer: UIView!
    
 
    @IBOutlet weak var playbackControlsView: UIView!
    
    @IBOutlet weak var channelsViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var channelsView: UIView!//syncui not implemented

    @IBOutlet weak var volumeButton: UIButton! //syncui not implemented
    @IBOutlet weak var progressLabel: UILabel! //syncui not implemented
    @IBOutlet weak var liveLabel: UILabel!//syncui not implemented
        {
        didSet {
            liveLabel.font = Branding.errorButtonFont
        }
    }
    @IBOutlet weak var ccButton: UIButton!
        {
        didSet {
            ccButton.titleLabel?.font = Branding.errorButtonFont
        }
    }
    

    
      var programs = [AuthorizedProgram]()
    var activeProgram: AuthorizedProgram?
    
    lazy var liveChannelsVC: LiveChannelsViewController = {
        var liveChannelsVC = LiveChannelsViewController(nibName: "LiveChannelsViewController", bundle: Bundle.main)
        
        liveChannelsVC.playerControlsVCDelegate = self.playerControlsVCDelegate
        liveChannelsVC.programs = self.programs
        liveChannelsVC.activeProgram = self.activeProgram
        liveChannelsVC.view.translatesAutoresizingMaskIntoConstraints = false
       
        
        return liveChannelsVC
    }()
   
    
    func update(activeProgram program: AuthorizedProgram) {
        activeProgram = program
        
        DispatchQueue.main.async {
            self.liveChannelsVC.update(activeProgram: program)
            
           
        }
    }
  
    @IBOutlet weak var playPauseButton: UIButton!
      var volumeObservation: NSKeyValueObservation?
    
    private var controlTimer: Timer?
    private var playingOnSeek: Bool = false
    
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.paddingCharacter = "0"
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
    
    
  
    
    override func loadView() {
        super.loadView()
        Bundle.main.loadNibNamed(PlayerControlsVCConstants.nibName, owner: self, options: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
   
        //to auto orientation
       
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        
        
        

      
        //to hide the progress label
        progressLabel.isHidden = true
        
        controlsContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
       
        
        channelsViewBottomConstraint.constant = PlayerControlsVCConstants.channelBottomConstraintHidden
       
        addChild(liveChannelsVC)
        channelsView.addSubview(liveChannelsVC.view)
        liveChannelsVC.didMove(toParent: self)
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|",
                                                                   options: .alignAllCenterY,
                                                                   metrics: nil,
                                                                   views: ["childView": liveChannelsVC.view])
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|",
                                                                 options: .alignAllLeading,
                                                                 metrics: nil,
                                                                 views: ["childView": liveChannelsVC.view])
        NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints)
        
        
        let notification = NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateVolumeIndicator),
                                               name: notification,
                                               object: nil)
        
        
        // Used for hiding and showing the controls.
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)

}
    

   
    override var shouldAutorotate: Bool {
     //   dismiss()
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        listenVolumeButton()
        
       
        
        
        
        
    }
    //to auto orientation
    
    

    
    
    func listenVolumeButton() {
        do {
            try audioSession.setActive(true)
        } catch {
            print("some error")
        }
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            print("Hello")
            updateVolumeIndicator()
        }
    }
    
    @objc func updateVolumeIndicator()
    {
        volumeIndicator.volume =  Double(currentPlayer?.volume ?? 0.0) > 0 ? AVAudioSession.sharedInstance().outputVolume : 0
        volumeButton.isSelected = (currentPlayer?.volume == 0)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showControls()
        
        volumeObservation =
            AVAudioSession.sharedInstance().observe(\.outputVolume,
                                                    options: [.new, .old]) { [unowned self] _, change in
                                                        guard let new = change.newValue, let old = change.oldValue else { return }
                                                        
                                                        if old < new {
                                                            // unmute
                                                            self.currentPlayer?.volume = 1.0
                                                        }
                                                        if new == 0 {
                                                            // mute
                                                            self.currentPlayer?.volume = 0.0
                                                        }
        }
    }

   
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            
        }
        catch {
            debugPrint("\(error)")
            
        }
        volumeObservation?.invalidate()
        volumeObservation = nil
    }
    
    @objc private func tapDetected() {
        if playPauseButton.isSelected {
            if controlsContainer.alpha == 0.0 {
                fadeControlsIn()
            } else if (controlsContainer.alpha == 1.0) {
                fadeControlsOut()
            }
        }
    }
    
    private func fadeControlsIn() {
        UIView.animate(withDuration: ControlConstants.AnimateInDuration, animations: {
            self.showControls()
        }) { [weak self](finished: Bool) in
            if finished {
                self?.reestablishTimer()
            }
        }
    }
    
    @objc private func fadeControlsOut() {
        UIView.animate(withDuration: ControlConstants.AnimateOutDuraton) {
            self.hideControls()
        }
        
    }
    
    private func reestablishTimer() {
        controlTimer?.invalidate()
        controlTimer = Timer.scheduledTimer(timeInterval: ControlConstants.VisibleDuration, target: self, selector: #selector(fadeControlsOut), userInfo: nil, repeats: false)
    }
    
    private func hideControls() {
        controlsContainer.alpha = 0.0
    }
    
    private func showControls() {
        controlsContainer.alpha = 1.0
    }
    
    private func invalidateTimerAndShowControls() {
        controlTimer?.invalidate()
        showControls()
    }
    
    private func formatTime(timeInterval: TimeInterval) -> String {
        if (timeInterval.isNaN || !timeInterval.isFinite || timeInterval == 0) {
            return "00:00"
        }
        
        let hours  = floor(timeInterval / 60.0 / 60.0)
        let minutes = (timeInterval / 60).truncatingRemainder(dividingBy: 60)
        let seconds = timeInterval.truncatingRemainder(dividingBy: 60)
        
        guard let formattedMinutes = numberFormatter.string(from: NSNumber(value: minutes)), let formattedSeconds = numberFormatter.string(from: NSNumber(value: seconds)) else {
            return ""
        }
        
        return hours > 0 ? "\(hours):\(formattedMinutes):\(formattedSeconds)" : "\(formattedMinutes):\(formattedSeconds)"
}
    
    
    
    
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
//        if let delegate = playerControlsVCDelegate
//        {
//            delegate.playerControlsVCDidBack(self)
//        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playPauseButton(_ sender: UIButton) {
        
        if sender.isSelected {
            currentPlayer?.pause()
        } else {
            currentPlayer?.play()
        }
    }
    @IBAction func ccButtonPressed(_ sender: UIButton) {
    }
    
    
    @IBAction func controlsSwipe(_ sender: UISwipeGestureRecognizer) {
        
        if sender.direction == .up {
            
            showChannelView()
        } else if sender.direction == .down {
           
             print("down")
            hideChannelView()
        }
        
    }
    func showChannelView() {
        view.layoutIfNeeded()
        
        channelsViewBottomConstraint.constant = PlayerControlsVCConstants.channelBottomConstraintShown
        
        UIView.animate(withDuration: PlayerControlsVCConstants.controlsAnimationDuration, animations: {
            self.view.layoutIfNeeded()
            self.playbackControlsView.alpha = 0
            self.controlsContainer.backgroundColor = PlayerControlsVCConstants.dimColor
        }, completion: { _ in
            self.playbackControlsView.isHidden = true
        })
    }
    
    private func hideChannelView() {
        view.layoutIfNeeded()
        
        playbackControlsView.isHidden = false
        channelsViewBottomConstraint.constant = PlayerControlsVCConstants.channelBottomConstraintHidden
        
        UIView.animate(withDuration: PlayerControlsVCConstants.controlsAnimationDuration, animations: {
            self.view.layoutIfNeeded()
            self.playbackControlsView.alpha = 1
            self.controlsContainer.backgroundColor = UIColor.clear
        })
    }
    
    var isChannelViewShown: Bool {
        if playbackControlsView == nil { return false }
        return playbackControlsView.isHidden
    }

  @IBAction func volumeMuteUnmuteAction(_ sender: UIButton) {
       
        if Double(currentPlayer?.volume ?? 0.0) > 0{
            currentPlayer?.volume = 0.0
        } else {
            currentPlayer?.volume = 1.0
        }
        
        volumeButton.isSelected = (currentPlayer?.volume == 0)
        volumeIndicator.volume = (currentPlayer?.volume ?? 0.0) > Float(0) ? AVAudioSession.sharedInstance().outputVolume : 0
    }
    
   
 
    
}



extension ControlsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // This makes sure that we don't try and hide the controls if someone is pressing any of the buttons
        // or slider.
        
        guard let view = touch.view else {
            return true
        }
        
        if ( view.isKind(of: UIButton.classForCoder()) || view.isKind(of: UISlider.classForCoder()) ) {
            return false
        }
        
        return true
    }
    
}



// MARK: - BCOVPlaybackSessionConsumer

extension ControlsViewController: BCOVPlaybackSessionConsumer {
    
    func didAdvance(to session: BCOVPlaybackSession!) {
        currentPlayer = session.player
        
        // Reset State
      //  playingOnSeek = false
        //playheadLabel.text = formatTime(timeInterval: 0)
       // playheadSlider.value = 0.0
        
      //  invalidateTimerAndShowControls()
    }
    
    func playbackSession(_ session: BCOVPlaybackSession!, didChangeDuration duration: TimeInterval) {
       // durationLabel.text = formatTime(timeInterval: duration)
    }
    
    func playbackSession(_ session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
      //  playheadLabel.text = formatTime(timeInterval: progress)
        
        guard let currentItem = session.player.currentItem else {
            return
        }
        
        let duration = CMTimeGetSeconds(currentItem.duration)
        let percent = Float(progress / duration)
     //   playheadSlider.value = percent.isNaN ? 0.0 : percent
    }
    
    func playbackSession(_ session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
        
        switch lifecycleEvent.eventType {
        case kBCOVPlaybackSessionLifecycleEventPlay:
            playPauseButton?.isSelected = true
            reestablishTimer()
        case kBCOVPlaybackSessionLifecycleEventPause:
            playPauseButton.isSelected = false
            invalidateTimerAndShowControls()
        default:
            break
        }
        
    }
    
}

// MARK: - ControlsViewControllerFullScreenDelegate

protocol ControlsViewControllerFullScreenDelegate: class {
    func handleEnterFullScreenButtonPressed()
    func handleExitFullScreenButtonPressed()
}


//class NavigationController: UINavigationController {
//
//    override var shouldAutorotate: Bool {
//        return false
//    }
//
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .landscapeRight
//    }
//
//}

//class NavigationController: UINavigationController{
//
//    override var shouldAutorotate: Bool {
//        return false
//    }
//
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .portrait
//    }
//
//}
