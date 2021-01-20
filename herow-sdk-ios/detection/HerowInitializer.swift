//
//  HerowInitializer.swift
//  herow-sdk-ios
//
//  Created by Damien on 14/01/2021.
//

import Foundation

@objc public class HerowInitializer: NSObject {
   public static let instance = HerowInitializer()
    private var apiManager: APIManager?
    private var netWorkDataHolder: NetworkDataStorageProtocol
    private var dataHolder: DataHolder
    private override init() {
        dataHolder = DataHolderUserDefaults(suiteName: "HerowInitializer")
        netWorkDataHolder = NetworkDataStorage(dataHolder: dataHolder)
    }

    @objc public func configPlatform(_ platform: String) -> HerowInitializer {
        self.apiManager = APIManager(plateform: platform , netWorkDataStorage: netWorkDataHolder)
        return self
    }

    @objc public func configApp(identifier: String, sdkKey: String) -> HerowInitializer {
        self.apiManager?.user = User(login: identifier, password: sdkKey)
        return self
    }


    @objc public func synchronize() {
        self.apiManager?.getUserInfo(completion: { _,_ in
            self.apiManager?.getConfig()
        })

    }
}
