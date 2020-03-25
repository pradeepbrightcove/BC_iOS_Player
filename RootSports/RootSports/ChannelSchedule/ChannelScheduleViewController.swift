//
//  ChannelScheduleViewController.swift
//  RootSports
//
//  Created by Oleksandr Haidaiev on 8/9/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit
import SafariServices

private enum Constants {
    static let estimatedRowHeigh: CGFloat = 68.0
    static let maxDaysForwardToSelect = 14
    static let maxDeltaForOnAirState: TimeInterval = 3600 // 1h
    static let pickerPresentDismissDelay = 0.3
    static let updatePeriodIfNoData: TimeInterval = 60
    static let datePickerRowHeight: CGFloat = 42.0

    static let channelScheduleCellNibName = "ChannelScheduleTableViewCell"
    static let channelScheduleCellReuseID = "ChannelScheduleTableViewCell"

    static let menuTintColor = colorFromHex("#444444")
    static let menuCancelTitleColor = colorFromHex("#fe3824")
    static let datePickerTextColor = colorFromHex("#5a5a5a")

    static let loginText = "Login"
    static let logoutText = "Logout"
    static let contactUsText = "Contact us"
    static let aboutText = "About us"
    static let careersText = "Careers"
    static let privacyText = "Privacy Policy"
    static let certificationsText = "Certifications"
    static let affiliateText = "Affiliate Resources"
    static let pressText = "Press"
    static let cancelText = "Cancel"
}

// swiftlint:disable type_body_length
class ChannelScheduleViewController: BaseViewController {

    @IBOutlet weak var regionImageView: UIImageView!
    @IBOutlet weak var currentRegionLabel: UILabel!
    @IBOutlet weak var pickDateButton: UIButton!
    @IBOutlet weak var datePickerContainer: UIView!

    @IBOutlet weak var topGradientView: GradientView!
    @IBOutlet weak var bottomGradientView: GradientView!

    @IBOutlet weak var datePickerContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var scheduleTableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!

    @IBOutlet var regionAndPickDateConstraintsNormal: [NSLayoutConstraint]!
    @IBOutlet var regionAndPickDateConstraintsiPadLandscape: [NSLayoutConstraint]!

    var currentRegion: RegionModel!
    fileprivate var serverTimeNow: TimeInterval? { // maybe we should create some TimeSynchronization manager later
        let serverTime: TimeInterval
        if let temporalServerTimeNow = temporalServerTimeNow {
            serverTime = temporalServerTimeNow
        } else {
            guard let localTimeDifferenceFromServer = localTimeDifferenceFromServer else {
                return nil
            }
            serverTime = Date().timeIntervalSince1970 - localTimeDifferenceFromServer
        }
        return serverTime
    }

    private var isDatePickerAnimated = false
    private var updateProgramsDataTimer: Timer?
    fileprivate lazy var pickedDate = Date()

    private var localTimeDifferenceFromServer: TimeInterval? // don't use it directly, use var serverTimeNow instead
    private var temporalServerTimeNow: TimeInterval? // don't use it directly, use var serverTimeNow instead

    fileprivate var dataSource = [ScheduleNodeModel]()
    fileprivate let cellDateFormatter = DateFormatter.shortTimeUSFormatterWithDeviceSettings()
    fileprivate let pickDateDateFormatter = DateFormatter(format: "EEEE, MMMM d, yyyy", locale: "en_US")

    private var loadInProgress = false

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpUI()

        let nib = UINib(nibName: Constants.channelScheduleCellNibName, bundle: nil)
        scheduleTableView.register(nib, forCellReuseIdentifier: Constants.channelScheduleCellReuseID)

        scheduleTableView.rowHeight = UITableView.automaticDimension
        scheduleTableView.estimatedRowHeight = Constants.estimatedRowHeigh

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        checkAuthAndLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)

        if !loadInProgress {
            loadInProgress = true
            updateProgramsDataUserInitiated(true)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        checkSpecificLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        checkSpecificLayout()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetUpdateProgramsDataTimer()
    }

    // MARK: - Actions

    @IBAction func pickDatePressed(_ sender: UIButton) {
        presentDatePicker()
    }

    @IBAction func pickDateDonePressed(_ sender: UIButton) {
        setTitleForPickDateButton(date: dateForSelectedRow())
        updateProgramsDataUserInitiated(true)
        dismissDatePicker()
    }

    @IBAction func tapGestureAction(_ sender: UITapGestureRecognizer) {
        if !datePickerContainer.isHidden {

            let tapLocation = sender.location(in: datePickerContainer)
            if !datePickerContainer.bounds.contains(tapLocation) {
                dismissDatePicker()
            }
        }
    }

    @IBAction func navigationItemBackAction(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func onMenu(_ sender: UIBarButtonItem) {

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = Constants.menuTintColor

        actionSheet.addAction(userStateAction())

        if let menuItems = CoreServices.shared.config.menuItems[currentRegion.regionCode] {
            for menuItem in menuItems where menuItem.key != ModelConstants.UserAgreementValue {
                actionSheet.addAction(menuAction(title: menuItem.name, menuKey: menuItem.key))
            }
        }

        let cancelAction = UIAlertAction(title: Constants.cancelText, style: .cancel)
        // To customize action button we can only use KVC
        cancelAction.setValue(Constants.menuCancelTitleColor, forKey: "titleTextColor")

        actionSheet.addAction(cancelAction)

        if isIpad {
            actionSheet.modalPresentationStyle = .popover

            let popover = actionSheet.popoverPresentationController
            popover?.barButtonItem = sender

            present(actionSheet, animated: true)
        } else {
            present(actionSheet, animated: true)
        }
    }

    // MARK: - Private
    private func checkAuthAndLoad() {
        LoaderViewManager.sharedInstance.startAnimation()

        loadInProgress = true

        AccessEnablerManager.shared.checkLoginStatus { [weak self] isLoggedIn, _ in
            if isLoggedIn {
                if AccessEnablerManager.shared.mvpdId == nil {
                    AccessEnablerManager.shared.logout(completion: { (_, _) in
                    })

                    LoaderViewManager.sharedInstance.stopAnimation()
                } else {
                    self?.authAndGetSchedule()
                }

            } else {
                self?.updateProgramsDataUserInitiated(true)
            }
        }
    }

    private func authAndGetSchedule() {
        let resources = self.currentRegion.resourceIds()

        DispatchQueue.main.async {
            self.checkAuthorizationAndRun(resources: resources, completion: { [weak self] _ in
                LoaderViewManager.sharedInstance.stopAnimation()

                self?.updateProgramsData()
            })
        }
    }

    private func userStateAction() -> UIAlertAction {
        var userStateAction: UIAlertAction!

        if AccessEnablerManager.shared.isLoggedIn {
            userStateAction = UIAlertAction(title: Constants.logoutText, style: .default) { (_) in
                LoaderViewManager.sharedInstance.startAnimation()
                AccessEnablerManager.shared.logout(completion: { [weak self] (_: Bool, _: Error?) in
                    LoaderViewManager.sharedInstance.stopAnimation()
                    self?.updateProgramsData()
                })
            }
        } else {
            userStateAction = UIAlertAction(title: Constants.loginText, style: .default, handler: { (_) in
                LoaderViewManager.sharedInstance.startAnimation()

                AccessEnablerManager.shared.showLoginCallback = {
                }

                AccessEnablerManager.shared.hideLoginCallback = {(success: Bool) in
                    if success {
                        LoaderViewManager.sharedInstance.startAnimation()
                    }
                }

                AccessEnablerManager.shared.login(resources: [], completion: { [weak self] _, error in
                    if let error = error {
                        self?.handle(error: error)
                        LoaderViewManager.sharedInstance.stopAnimation()
                    } else {
                        LoaderViewManager.sharedInstance.startAnimation()
                    }

                    self?.authAndGetSchedule()
                })
            })
        }

        return userStateAction
    }

    private func menuAction(title: String, menuKey: String) -> UIAlertAction {
        let action = UIAlertAction(title: title, style: .default) { (_) in

            guard let menu = CoreServices.shared.config
                .menuItems[self.currentRegion.regionCode]?.filter({ $0.key == menuKey }).first else {
                self.handle(error: ServerLogicalError.undefined)
                return
            }

            switch menu.type {
            case .html:
                self.presentWebView(html: menu.data)
            case .link:
                self.presentSafari(link: menu.urlString)
            default:
                self.handle(error: ServerLogicalError.undefined)
            }
        }
        return action
    }

    fileprivate func presentWebView(html: String) {
        guard let webViewController =
            UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "MenuWebViewController")
            as? MenuWebViewController else { return }
        webViewController.html = html
        navigationController?.pushViewController(webViewController, animated: true)
    }

    fileprivate func presentSafari(link: String) {
        if let url = URL(string: link) {
            let safari = SFSafariViewController(url: url)
            present(safari, animated: true)
        }
    }

    private func setTitleForPickDateButton(date: Date) {
        pickedDate = date
        pickDateButton.setTitle(pickDateDateFormatter.string(from: date).uppercased(), for: .normal)
    }

    private func setUpUI() {
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo-navigation.png"))
        currentRegionLabel.text = currentRegion.regionName.uppercased()
        currentRegionLabel.font = Branding.channelScheduleRegionFont
        pickDateButton.titleLabel?.font = Branding.channelSchedulePickDateButtonFont
        pickDateButton.addSpaceBetweenTitleAndImage(spacing: 11)
        setTitleForPickDateButton(date: pickedDate)

        datePickerContainer.isHidden = true
        datePickerContainerBottomConstraint.constant = -datePickerContainer.bounds.size.height

        view.backgroundColor = UIColor.Branding.mainBg
        navigationController?.navigationBar.barTintColor = UIColor.Branding.mainNavigationBg
        scheduleTableView.backgroundColor = UIColor.Branding.mainDarkSeparator
        scheduleTableView.contentInset = UIEdgeInsets(top: 0,
                                                      left: 0,
                                                      bottom: bottomGradientView.bounds.size.height,
                                                      right: 0)

        if !hasPreviousVC() {
            navigationItem.leftBarButtonItem = nil
        }

        #if ATT
            regionImageView.image = UIImage(named: "channel-schedule-bg")
            topGradientView.removeFromSuperview()
        #else
            topGradientView.colors = [UIColor.milkChocolate, UIColor.milkChocolate.withAlphaComponent(0)]
        #endif

        bottomGradientView.colors = [UIColor.Branding.gradientBottom.withAlphaComponent(0),
                                     UIColor.Branding.gradientBottom]
    }

    private func runUpdateProgramsDataTimer() {
        resetUpdateProgramsDataTimer()

        var timeToNextProgram = Constants.updatePeriodIfNoData

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        components.minute = components.minute! + 1

        if let endOfMinute = calendar.date(from: components) {
            timeToNextProgram = min(timeToNextProgram, endOfMinute.timeIntervalSince(Date()))
        }

// commenting out this logic, just update every minute
//        guard let serverTimeNow = serverTimeNow else {
//            return
//        }
//        
//        if dataSource.count > 1 {
//            timeToNextProgram = TimeInterval(dataSource[1].start) - serverTimeNow
//        } else if let scheduleModel = dataSource.first {
//            timeToNextProgram = TimeInterval(scheduleModel.start + 60) - serverTimeNow
//        }
//
        if timeToNextProgram > 0 {
            updateProgramsDataTimer = Timer.scheduledTimer(timeInterval: timeToNextProgram,
                                                           target: self,
                                                           selector: #selector(updateProgramsData),
                                                           userInfo: nil,
                                                           repeats: false)
        }
    }

    private func resetUpdateProgramsDataTimer() {
        if updateProgramsDataTimer != nil {
            updateProgramsDataTimer?.invalidate()
            updateProgramsDataTimer = nil
        }
    }

    @objc private func didEnterForeground() {
        if self.presentedViewController == nil {
            setUpUI()
            updateProgramsData()
        }
    }

    @objc private func didEnterBackground() {
        resetUpdateProgramsDataTimer()
    }

    @objc private func updateProgramsData() {
        updateProgramsDataUserInitiated(false)
    }

    private func updateProgramsDataUserInitiated(_ userInitiated: Bool) {
        resetUpdateProgramsDataTimer()

        guard let currentRegion = currentRegion else {
            return handle(error: ServerLogicalError.undefined)
        }

        LoaderViewManager.sharedInstance.startAnimation()

        _ = CoreServices.shared.scheduleProvider
            .schedule(forDate: pickedDate,
                      region: currentRegion.regionCode,
                      completion: { [weak self] (nodes: [ScheduleNodeModel]?, time: Int?, error: Error?) in
            LoaderViewManager.sharedInstance.stopAll()

            if let strongSelf = self {
                self?.loadInProgress = false

                guard error == nil else {
                    //                    NSLog("RECEIVED ERROR %@", error.debugDescription )
                    DispatchQueue.main.async {
                        if userInitiated {
                            strongSelf.handle(error: error!)
                        }
                        strongSelf.runUpdateProgramsDataTimer()
                    }

                    return
                }

                if let nodes = nodes, let time = time {
                    DispatchQueue.main.async {
                        strongSelf.temporalServerTimeNow = TimeInterval(time)
                        strongSelf.localTimeDifferenceFromServer = Date().timeIntervalSince1970 - TimeInterval(time)
                        strongSelf.dataSource = nodes
                        strongSelf.runUpdateProgramsDataTimer()
                        strongSelf.scheduleTableView.reloadData()
                        strongSelf.scheduleTableView.setContentOffset(.zero, animated: true)
                        strongSelf.temporalServerTimeNow = nil // need to reset it, because it will be outdated from now

                        if nodes.count == 0 {
                            showAlertForError(code: ServerLogicalError.noPrograms, isPlayer: false)
                        }
                    }

                } else {
                    assertionFailure("no required parameters")
                }
            }
        })
    }

    private func presentDatePicker() {
        if !isDatePickerAnimated {
            isDatePickerAnimated = true
            datePickerContainer.isHidden = false

            self.datePickerContainerBottomConstraint.constant = 0
            UIView.animate(withDuration: Constants.pickerPresentDismissDelay,
                           animations: { self.view.layoutIfNeeded() },
                           completion: { _ in
                self.isDatePickerAnimated = false
            })
        }
    }

    private func dismissDatePicker() {
        if !isDatePickerAnimated {
            isDatePickerAnimated = true

            datePickerContainerBottomConstraint.constant = -datePickerContainer.bounds.height
            UIView.animate(withDuration: Constants.pickerPresentDismissDelay,
                           animations: { self.view.layoutIfNeeded() },
                           completion: { _ in
                self.isDatePickerAnimated = false
                self.datePickerContainer.isHidden = true
            })
        }
    }

    fileprivate func presentPlayer(programs: [AuthorizedProgram],
                                   selectedProgram: ProgramModel? = nil,
                                   shouldAutoPlay: Bool = true) {
        guard let player =
            UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "ViewController")
                as? ViewController else { return }

   // player.presentedByViewController = self
  //     player.programs = programs

        var activeProgram = programs.first

        if let selectedProgram = selectedProgram {
            for authProgram in programs where selectedProgram.channelCode == authProgram.channelCode {
                activeProgram = authProgram
            }
        } else {
            activeProgram = programs.first
        }

    player.activeProgram = activeProgram
   player.shouldAutoPlayWhenReady = shouldAutoPlay

        self.present(player, animated: true, completion: nil)
    }

    // MARK: - overriding error handlers
    override func handleBillingZipAuthError(context: AnyObject? = nil,
                                            action: EmptyCompletion? = nil,
                                            completion: BoolCompletion? = nil) {

        var mvpd = ErrorConstants.mvpdName

        guard let context = context as? [String: Any] else {
            self.navigationController?.popToRootViewController(animated: true)
            showErrorFor(code: ServerLogicalError.billingZipAuthorization)
            return
        }

        if let mvpdName = context[ContextKey.mvpd] as? String {
            mvpd = mvpdName
        }

        if let altName = context[ContextKey.alternate] as? String {

            let action = AlertAction(title: altName) {
                if let programs = context[ContextKey.programs] as? [AuthorizedProgram] {
                    self.presentPlayer(programs: programs)
                }
            }

            let closeAlertCompletion: BoolCompletion = { (onAction) in
                if let alertCompletion = completion {
                    alertCompletion(true)
                }

                if !onAction {
                    CoreServices.shared.concurrencyProvider.deleteCurrentSession({ (_, _) in
                    })
                }
            }

            showErrorFor(code: ServerLogicalError.billingZipAuthorization,
                         params: [mvpd, altName],
                         extendedMessage: true,
                         alertAction: action,
                         completion: closeAlertCompletion)

        } else {
            CoreServices.shared.concurrencyProvider.deleteCurrentSession({ (_, _) in
            })

            showErrorFor(code: ServerLogicalError.billingZipAuthorization, params: [mvpd])
        }
    }

    override func handleAuthZFailure(context: AnyObject? = nil,
                                     action: EmptyCompletion? = nil,
                                     completion: BoolCompletion? = nil) {
        var mvpd = ErrorConstants.mvpdName
        if let mvpdName = AccessEnablerManager.shared.mvpdName {
            mvpd = mvpdName
        }

        if let context = context as? [String: Any], let altName = context[ContextKey.alternate] as? String {

            let action = AlertAction(title: altName) {
                if let programs = context[ContextKey.programs] as? [AuthorizedProgram] {
                    self.presentPlayer(programs: programs)
                }
            }

            showErrorFor(code: ServerLogicalError.authZFailure,
                         params: [mvpd, altName],
                         extendedMessage: true,
                         alertAction: action,
                         completion: nil)

        } else {

            goToRegionOrScheduleScreen()

            showErrorFor(code: ServerLogicalError.authZFailure, params: [mvpd])
        }
    }

    override func handleDeviceZipNotAllowedProduct(context: AnyObject? = nil,
                                                   action: EmptyCompletion? = nil,
                                                   completion: BoolCompletion? = nil) {
        if let context = context as? [String: Any],
           let altName = context[ContextKey.alternate] as? String {

            let action = AlertAction(title: altName) {
                if let programs = context[ContextKey.programs] as? [AuthorizedProgram] {
                    self.presentPlayer(programs: programs)
                }
            }

            showErrorFor(code: ServerLogicalError.deviceZipProduct,
                         params: [altName],
                         extendedMessage: true,
                         alertAction: action,
                         completion: nil)
        } else {
            showErrorFor(code: ServerLogicalError.deviceZipProduct)
        }
    }

    override func handleBillingZipNotAllowedProduct(context: AnyObject? = nil,
                                                    action: EmptyCompletion? = nil,
                                                    completion: BoolCompletion? = nil) {
        if let context = context as? [String: Any],
           let altName = context[ContextKey.alternate] as? String {

            let action = AlertAction(title: altName) {
                if let programs = context[ContextKey.programs] as? [AuthorizedProgram] {
                    self.presentPlayer(programs: programs)
                }
            }

            showErrorFor(code: ServerLogicalError.billingZipProduct,
                         params: [altName],
                         extendedMessage: true,
                         alertAction: action,
                         completion: nil)
        } else {
            showErrorFor(code: ServerLogicalError.billingZipProduct)
        }
    }

    override func handleNoProgramsError(context: AnyObject?,
                                        action: EmptyCompletion?,
                                        completion: BoolCompletion?) {
        if let context = context as? [String: Any],
           let altName = context[ContextKey.alternate] as? String {

            let action = AlertAction(title: altName) {
                if let programs = context[ContextKey.programs] as? [AuthorizedProgram] {
                    self.presentPlayer(programs: programs)
                }
            }

            showErrorFor(code: ServerLogicalError.noProgramsOnAir,
                         params: [altName],
                         extendedMessage: true,
                         alertAction: action,
                         completion: nil)
        } else {
            showErrorFor(code: ServerLogicalError.noProgramsOnAir)
        }
    }

    private func checkSpecificLayout() {
        for regionAndPickDateConstraints in regionAndPickDateConstraintsNormal +
                                            regionAndPickDateConstraintsiPadLandscape {
            regionAndPickDateConstraints.isActive = false
        }

        for constraintiPadLandscape in regionAndPickDateConstraintsiPadLandscape {
            constraintiPadLandscape.isActive = isIPadLandscape
        }
        for constraintNormal in regionAndPickDateConstraintsNormal {
            constraintNormal.isActive = !isIPadLandscape
        }
    }
}

// MARK: - UITableViewDataSource
extension ChannelScheduleViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].uniqueProgramsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier:
            Constants.channelScheduleCellReuseID) as? ChannelScheduleTableViewCell else {
                return UITableViewCell()
        }

        let index = indexPath.row
        let cellCount = dataSource[indexPath.section].uniqueProgramsCount
        let programModel = dataSource[indexPath.section].programs[index]

        cell.setUp(cellData: dataForCell(program: programModel,
                                         cellIndex: index,
                                         cellCount: cellCount))
        cell.delegate = self

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChannelScheduleViewController: UITableViewDelegate {

}

// MARK: - ChannelScheduleTableViewCellDelegate

extension ChannelScheduleViewController: ChannelScheduleTableViewCellDelegate {

    func channelCellDidSelect(_ cell: ChannelScheduleTableViewCell) {

        guard let indexPath = scheduleTableView.indexPath(for: cell) else {
            return
        }

        let program = dataSource[indexPath.section].programs[indexPath.row]
        guard program.isOnAir(serverTimeNow: serverTimeNow) && program.allowed else {
            return // looks like our data is outdated
        }

        NonFatalErrorProvider.shared.debugInfo[DebugInfoKey.selectedChannel] = program.channelCode
        NonFatalErrorProvider.shared.debugInfo[DebugInfoKey.selectedProgram] = program.programCode

        var resources = [String]()

        if let region = CoreServices.shared.scheduleProvider.regionForChannel(program.channelCode) {
            resources = region.resourceIds()

        } else {
            for model in dataSource {
                for scheduledProgram in model.programs {
                    if scheduledProgram.isOnAir(serverTimeNow: serverTimeNow) {
                        resources.append(scheduledProgram.resourceId)
                    }
                }
            }
        }

        LoaderViewManager.sharedInstance.startAnimation()

        checkAuthorizationAndRun(resources: resources) { [weak self] (success: Bool) in
            LoaderViewManager.sharedInstance.stopAnimation()

            if success {
                self?.checkConcurrencyAndPlay(program)
            } else {
                DispatchQueue.main.async {
                    self?.handleAuthZFailure()
                }
            }
        }
    }

    private func checkConcurrencyAndPlay(_ program: ProgramModel) {
        guard let subscriberId = AccessEnablerManager.shared.subscriberId,
            let mvpdId = AccessEnablerManager.shared.mvpdId else {
            return
        }

        LoaderViewManager.sharedInstance.startAnimation()

        CoreServices.shared.concurrencyProvider.createSession(mvpdId: mvpdId,
                                                              subscriberId: subscriberId) { [weak self] _, error in
            LoaderViewManager.sharedInstance.stopAnimation()

            if let error = error {
                DispatchQueue.main.async {
                    self?.handle(error: error)
                }
            } else {
                self?.getProgramDataAndPlay(program)
            }
        }
    }

    private func getProgramDataAndPlay(_ program: ProgramModel) {
        LoaderViewManager.sharedInstance.startAnimation()

        let authProvider = CoreServices.shared.authorizationProvider

        authProvider.programMeta(program,
                                 regionCode: self.currentRegion.regionCode,
                                 completion: { [weak self] programs, error in
            DispatchQueue.main.async {
                LoaderViewManager.sharedInstance.stopAnimation()

                if let error = error {

                    if let programs = programs {
                        let channels = programs.map { program -> String in
                            return program.channelCode
                        }

                        if let duplicates = self?.duplicatesForProgram(program), duplicates.count > 0 {
                            for duplicate in duplicates {
                                if channels.contains(duplicate.channelCode) {
                                    self?.presentPlayer(programs: programs, selectedProgram: duplicate)
                                    return
                                }
                            }
                        }
                    }

                    var context: [String: Any] = [ContextKey.mvpd: AccessEnablerManager.shared.mvpdName ?? "MVPD"]

                    if let programs = programs, let name = programs.first?.programTitleBrief {
                        context[ContextKey.alternate] = name
                        context[ContextKey.programs] = programs
                    }

                    context[ModelConstants.ChannelCodeField] = program.channelCode
                    context[ModelConstants.ProgramCodeField] = program.programCode

                    self?.handle(error: error, context: context as AnyObject)

                } else if let programs = programs {
                    self?.presentPlayer(programs: programs, selectedProgram: program/*, shouldAutoPlay: false*/)
                }
            }
        })
    }

    private func duplicatesForProgram(_ program: ProgramModel) -> [ProgramModel]? {
        for node in dataSource where node.start == program.start {
            return node.duplicatePrograms(program)
        }
        return nil
    }
}

// MARK: - Helpers
private typealias Helpers = ChannelScheduleViewController
private extension Helpers {
    func dataForCell(program: ProgramModel, cellIndex: Int, cellCount: Int) -> ChannelScheduleCellData {

        func timeTextFrom(program: ProgramModel) -> (NSAttributedString, Bool) {

            var localTimeDifferenceFromServer: Double = 0
            if let serverTimeNow = serverTimeNow {
                localTimeDifferenceFromServer = Double(Date().timeIntervalSince1970 - serverTimeNow)
                localTimeDifferenceFromServer = round(localTimeDifferenceFromServer / 3600.0) * 3600.0
                // we need rounded value by hours, b.c server time may be different from global
            }

            let date = Date(timeIntervalSince1970: TimeInterval(program.start) +
                                                   TimeInterval(localTimeDifferenceFromServer))
            let timeComponents = date.timeComponents(with: cellDateFormatter)
            var attr = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let attributedText = NSMutableAttributedString(string: timeComponents.digits,
                                                           attributes: attr)
            var is24timeFormat = true
            if let amPm = timeComponents.amPm {
                is24timeFormat = false
                attr = [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.3)]
                attributedText.append(NSMutableAttributedString(string: " " + amPm,
                                                                attributes: attr))
            }

            return (NSAttributedString(attributedString: attributedText), is24timeFormat)
        }

        func isProgramContinued(program: ProgramModel) -> Bool {
            let programStartDate = Date(timeIntervalSince1970: TimeInterval(program.start))
            let currentDate = pickedDate

            let isCurrentDay = Calendar.current.isDate(programStartDate, inSameDayAs: currentDate)
            return !isCurrentDay
        }

        let timeTuple: (time: NSAttributedString, is24: Bool) = timeTextFrom(program: program)
        let isContinued = isProgramContinued(program: program)
        return ChannelScheduleCellData(timeText: timeTuple.time,
                                       is24timeFormat: timeTuple.is24,
                                       programText: program.programTitleBrief ?? "Unknown program",
                                       isOnAirNow: program.isOnAir(serverTimeNow: serverTimeNow),
                                       isRecorded: !program.live,
                                       isStartCell: cellIndex == 0,
                                       isEndCell: cellIndex == cellCount - 1,
                                       isContinued: isContinued,
                                       isAllowed: program.allowed)
    }

    func hasPreviousVC() -> Bool {
        if let navigationVC = navigationController {
            let stackOfVC = navigationVC.viewControllers
            for counter in (1 ..< stackOfVC.count).reversed() where stackOfVC[counter] == self {
                return true
            }
        }
        return false
    }

    func datesForPicker() -> [(String, Date)] {
        var dates: [(String, Date)] = []

        let calendar = Calendar(identifier: .gregorian)
        var dateComponent = DateComponents()
        let currentDate = Date()

        for day in 0...Constants.maxDaysForwardToSelect {
            dateComponent.day = day
            if let newDate = calendar.date(byAdding: dateComponent, to: currentDate) {
                let formattedDate = pickDateDateFormatter.string(from: newDate)
                dates.append((formattedDate, newDate))
            }
        }

        return dates
    }
}

extension ChannelScheduleViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return datesForPicker().count
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView,
                    viewForRow row: Int,
                    forComponent component: Int,
                    reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = Branding.channelSchedulePickDateButtonFont
        label.textColor = Constants.datePickerTextColor

        if row >= datesForPicker().count {
            print("No valid date")
            return label
        }

        let (title, _) = datesForPicker()[row]
        label.text = title.uppercased()

        label.sizeToFit()

        return label
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return Constants.datePickerRowHeight
    }

    func dateForSelectedRow() -> Date {
        let selectedRow = pickerView.selectedRow(inComponent: 0)

        if selectedRow >= datesForPicker().count {
            print("No valid date to select")
            return Date()
        }

        let (_, date) = datesForPicker()[selectedRow]

        return date
    }
}
