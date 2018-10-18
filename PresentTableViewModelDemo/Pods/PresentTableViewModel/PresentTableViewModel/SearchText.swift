//
//  Search.swift
//  Present
//
//  Created by Patrick Niemeyer on 5/15/18.
//  Copyright © 2018 Present Company. All rights reserved.
//

import Foundation

/// Codify the difference between no search, empty search, and search text.
public enum SearchText {
    case noSearch
    case empty
    case value(String)
    
    public static func forText(_ text: String?) -> SearchText {
        if let text = text?.trimmingWhitespace() {
            return text == "" ? .empty : .value(text)
        } else {
            return .noSearch
        }
    }
}

