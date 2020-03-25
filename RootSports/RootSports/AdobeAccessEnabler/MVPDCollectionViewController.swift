//
//  MVPDCollectionViewController.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/16/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class MVPDCollectionViewController: UICollectionViewController {

    var mvpds: [Any]! = []

    var selectionHandler: ((_ mvpd: MVPD) -> Void)?

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mvpds.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                               for: indexPath) as? MVPDPickerCollectionViewCell else {
                                                return UICollectionViewCell()
        }

        guard let mvpd = mvpds[indexPath.row] as? MVPD else {
            return cell
        }

        cell.plceholderView.isHidden = false
        cell.titleLabel.text = mvpd.displayName

        cell.logoImageView.image = nil
        cell.logoImageView.downloadedFrom(link: mvpd.logoURL) {
            cell.plceholderView.isHidden = true
        }

        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectionHandler = selectionHandler, let mvpd = mvpds[indexPath.row] as? MVPD else {
            return
        }

        selectionHandler(mvpd)
    }

}
