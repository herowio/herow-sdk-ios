//
//  LiveMomentStore.swift
//  herow_sdk_ios
//
//  Created by Damien on 11/05/2021.
//

import Foundation
protocol LiveMomentStoreProtocol {
    init(db: DataBase)
}

class LiveMomentStore: LiveMomentStoreProtocol {
    let dataBase: DataBase
    required init(db: DataBase) {
        dataBase = db
    }
}
