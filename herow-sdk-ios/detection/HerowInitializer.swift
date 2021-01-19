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

    private override init() {

    }

    @objc public func configPlatform(_ platform: String) -> HerowInitializer {
        self.apiManager = APIManager(plateform: platform , dataHolder: DataHolderUserDefaults(suiteName: "HerowInitializer"))
        return self
    }

    @objc public func configApp(identifier: String, sdkKey: String) -> HerowInitializer {
        self.apiManager?.user = User(login: identifier, password: sdkKey)
        return self
    }


    @objc public func synchronize() {
        self.apiManager?.getAndSaveToken(completion: { (token, error) in
            print (" token request: \(String(describing: token)) error: \(String(describing: error))")
        })
    }
}
