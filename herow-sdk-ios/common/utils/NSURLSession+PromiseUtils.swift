//
//  NSURLSession+PromiseUtils.swift
//  ConnectPlaceCommon
//
//  Created by Amine on 31/05/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import PromiseKit

extension URLSession {
    public func dataTask(_: PMKUtilsNamespacer, with convertible: URLRequestConvertible)
        -> Promise<(data: Data, response: URLResponse)> {
        return self.dataTask(.promise, with: convertible).validate()
    }
}
public enum PMKUtilsNamespacer {
    case promiseWithError
}

#if swift(>=3.1)
extension PMKHTTPError {
    public var statusCode: Int {
        switch self {
        case .badStatusCode(let code, _, _):
            return code
        }
    }
}
#endif
