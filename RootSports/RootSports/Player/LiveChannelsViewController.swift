//
//  LiveChannelsViewController.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/3/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

private enum LiveChannelsVCConstants {
    static let cellReuseIdentifier = "Cell"
    static let collectionHeaderNibName = "LiveChannelsCollectionHeader"
    static let collectionHeaderReuseIdentifier = "LiveChannelsCollectionHeader"
    static let collectionCellNibName = "LiveChannelCollectionViewCell"
    static let collectionCellMinWidth: CGFloat = 240.0
    static let collectionCellHeight: CGFloat = 72.0
    static let collectionCellTitleWidth: CGFloat = 180.0
    static let collectionCellWidthStep: CGFloat = 20.0
    static let collectionCellTitleMaxHeight: CGFloat = 50.0
}

class LiveChannelsViewController: UICollectionViewController {

    var programs = [AuthorizedProgram]()
    var activeProgram: AuthorizedProgram?
    
    var interactionEnabled = true

    weak var playerControlsVCDelegate: PlayerControlsViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Register cell classes
        self.collectionView?.register(UINib(nibName: LiveChannelsVCConstants.collectionCellNibName,
                                            bundle: Bundle.main),
                                      forCellWithReuseIdentifier: LiveChannelsVCConstants.cellReuseIdentifier)

        self.collectionView?.register(UINib(nibName: LiveChannelsVCConstants.collectionHeaderNibName,
                                            bundle: Bundle.main),
                                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                      withReuseIdentifier: LiveChannelsVCConstants.collectionHeaderReuseIdentifier)
    }

    // MARK: Public

    func update(activeProgram program: AuthorizedProgram) {
        activeProgram = program
        collectionView?.reloadData()
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
        
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier: LiveChannelsVCConstants.cellReuseIdentifier,
                                               for: indexPath)
                as? LiveChannelCollectionViewCell else { return UICollectionViewCell() }

      
        
            cell.statusLabel.text = "WATCHING NOW"
            cell.startButton.isHidden = true
      

        cell.titleLabel.textColor = UIColor.white
        cell.statusLabel.textColor = UIColor.white
        cell.titleLabel.text = isATTApp ? activeProgram?.programTitleBrief?.uppercased() : activeProgram?.programTitleBrief
       // cell.startButton.setImage(UIImage(named: "play-ic"), for: .normal)

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        let reuseId = LiveChannelsVCConstants.collectionHeaderReuseIdentifier
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: reuseId,
                                                                   for: indexPath)
        if  let view = view as? LiveChannelsCollectionHeader {
            view.delegate = self
        }

        return view
    }

   
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        collectionView.reloadData()
    }



extension LiveChannelsViewController: LiveChannelsCollectionHeaderDelegate {
    func liveChannelsCollectionHeaderTapped(_ cell: LiveChannelsCollectionHeader) {
        if  let delegate = playerControlsVCDelegate {
            delegate.playerControlsVCDidBack(self)
        }
    }
}

