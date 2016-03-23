//
//  String+Substring.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 3/5/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

extension String {
    subscript (r: Range<Int>) -> String {
        get {
            let rangeStartIndex = startIndex.advancedBy(r.startIndex)
            let rangeEndIndex = rangeStartIndex.advancedBy(r.endIndex - r.startIndex)
            return self[rangeStartIndex..<rangeEndIndex]
            // return self[Range(start: rangeStartIndex, end: rangeEndIndex)]
        }
    }
}
