//
//  RegionProvider.swift
//  RootSports
//
//  Created by Artak on 8/17/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

typealias RegionCompletion = (_ regions: [RegionModel]?, _ error: Error?) -> Void

protocol RegionNetworkServiceProtocol {
    func regions(applicationId: String, completion: @escaping (_ regions: [[String: Any]?]?, _ error: Error?) -> Void)
}

class RegionProvider {
    private let networkService: RegionNetworkServiceProtocol

    init(networkService: RegionNetworkServiceProtocol) {
        self.networkService = networkService
    }

    func regions(applicationId: String, compilation : @escaping RegionCompletion) {
        networkService.regions(applicationId: applicationId, completion: { (responseArray, error) in

            if error == nil {
                var regionModels = [RegionModel]()
                for dict in responseArray! {
                    if let regionDict = dict {
                        if let region = RegionModel(fromDictionary: regionDict) {
                            regionModels.append(region)
                        }
                    }
                }
                compilation(regionModels, nil)
            }
        })
    }

}
