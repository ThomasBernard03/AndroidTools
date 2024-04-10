//
//  StringExtensions.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 10/04/2024.
//

import Foundation

extension String {
    func substringAfterLast(_ delimiter: String) -> String {
        guard let range = self.range(of: delimiter, options: .backwards) else {
            return self
        }

        let indexAfterDelimiter = self.index(range.upperBound, offsetBy: 0)
        return String(self[indexAfterDelimiter...])
    }
}
