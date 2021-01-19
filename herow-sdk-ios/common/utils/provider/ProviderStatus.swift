//
//  ProviderStatus.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 10/04/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

public enum ProviderStatus {
    case inProgress,
    success,
    networkError,
    backendError,
    dbError

    public func getErrorCode() -> Int16 {
        switch self {
        case .networkError:
            return 21
        case .backendError:
            return 22
        case .dbError:
            return 23
        default:
            return 0
        }
    }
}
