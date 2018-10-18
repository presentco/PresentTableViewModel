//
//  OptionalExtensions.swift
//  Present
//
//  Created by Patrick Niemeyer on 4/21/18.
//  Copyright © 2018 Present Company. All rights reserved.
//

import Foundation

extension Optional {
    
    // From SwifterSwift
    public func unwrapped(or error: Error) throws -> Wrapped {
        guard let wrapped = self else { throw error }
        return wrapped
    }
    
    public func unwrappedOrFatal(_ message: String? = nil) -> Wrapped {
        guard let wrapped = self else {
            if let message = message {
                fatalError(message)
            } else {
                fatalError()
            }
        }
        return wrapped
    }
    
}
