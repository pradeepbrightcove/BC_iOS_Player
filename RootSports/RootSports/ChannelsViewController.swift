//
//  ChannelsViewController.swift
//  RootSports
//
//  Created by Artak on 7/31/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

private enum ChannelsVCConstants {
    static let estimatedRowHeight: CGFloat = 22.0
    static let cellHeightProportion: CGFloat = 14.0
    static let segueToChannelScheduleVCId = "showRootSchedule"

}
class ChannelsViewController: BaseViewController {

    @IBOutlet weak var channelsTableView: UITableView!
    var currentRegions: [RegionModel]!

    override func viewDidLoad() {
        super.viewDidLoad()

        channelsTableView.estimatedRowHeight = ChannelsVCConstants.estimatedRowHeight
        channelsTableView.backgroundColor = UIColor.clear
        channelsTableView.isScrollEnabled = (self.currentRegions.count > 3)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ChannelsVCConstants.segueToChannelScheduleVCId,
            let destinationVC = segue.destination as? ChannelScheduleViewController,
            let index = channelsTableView.indexPathForSelectedRow?.row {

            destinationVC.currentRegion = currentRegions[index/2]
        }
    }
}

// MARK: - UITableViewDelegate
extension ChannelsViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row % 2 == 1 {
            print(tableView.bounds.size.height)
            return tableView.bounds.size.height / ChannelsVCConstants.cellHeightProportion
        }
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

// MARK: - UITableViewDataSource
extension ChannelsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentRegions.count * 2 - 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row % 2 == 1 {
            let cellId: String = "DummyTableCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
                             as? DummyTableCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            return cell
        }

        let cellId: String = "ChannelTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
                         as? ChannelTableViewCell else { return UITableViewCell() }
        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = UIColor.gray.cgColor

        cell.chanelNameLabel.text = self.currentRegions[indexPath.row / 2].regionName.uppercased()

        cell.selectionStyle = .none

        return cell
    }
}
