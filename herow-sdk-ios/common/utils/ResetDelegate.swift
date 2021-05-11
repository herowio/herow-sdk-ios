//
//  ResetDelegate.swift
//  ConnectPlaceCommon
//
//  Created by Olivier Stevens on 31/08/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

@objc public protocol ResetDelegate: AnyObject {
     func reset(completion: @escaping ()->())
}

extension ResetDelegate {
    func reset() {
        reset {
            // do nothing
        }
    }
}


