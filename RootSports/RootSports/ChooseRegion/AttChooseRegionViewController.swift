//
//  AttChooseRegionViewController.swift
//  RootSports
//
//  Created by Artak on 8/7/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

private enum ChooseRegionVCConstants {
    static let cellHeight: CGFloat = 90.0
    static let cellId: String = "ChooseRegionTableCell"
    static let segueToChannelScheduleVCId = "ToChannelScheduleViewController"
}

class AttChooseRegionViewController: BaseViewController {

    @IBOutlet weak var regionsTableView: UITableView!
    var currentRegions: [RegionModel]!

    override func viewDidLoad() {
        super.viewDidLoad()

        regionsTableView.isScrollEnabled =
            CGFloat(self.currentRegions.count) * ChooseRegionVCConstants.cellHeight >
                                                            regionsTableView.bounds.size.height
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ChooseRegionVCConstants.segueToChannelScheduleVCId,
            let destinationVC = segue.destination as? ChannelScheduleViewController,
            let index = regionsTableView.indexPathForSelectedRow?.row {

            destinationVC.currentRegion = currentRegions[index]
        }
    }
}

// MARK: - UITableViewDelegate
extension AttChooseRegionViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ChooseRegionVCConstants.cellHeight
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 1.0))
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return view
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }

}

// MARK: - UITableViewDataSource
extension AttChooseRegionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentRegions!.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =
            tableView.dequeueReusableCell(withIdentifier: ChooseRegionVCConstants.cellId)
                as? ChooseRegionTableCell else { return UITableViewCell() }
        cell.regionNameLabel.text = self.currentRegions[indexPath.row].regionName.uppercased()
        return cell
    }
}
