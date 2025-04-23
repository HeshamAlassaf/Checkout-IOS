//
//  Dictionary+Extension.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    
    /**
     Recursively updates all occurrences of a specific key with a new value throughout the dictionary and its nested structures.
     
     - Parameters:
        - key: The key to search for and update
        - value: The new value to set for the matching keys
     
     - Returns: A new dictionary with the updated values
     */
    mutating func updateAllOccurrences<T>(ofKey targetKey: String, with newValue: T) {
        for (key, value) in self {
            if key == targetKey {
                self[key] = newValue
            } else if var nestedDict = value as? [String: Any] {
                nestedDict.updateAllOccurrences(ofKey: targetKey, with: newValue)
                self[key] = nestedDict
            } else if var nestedArray = value as? [[String: Any]] {
                for i in 0..<nestedArray.count {
                    var mutableDict = nestedArray[i]
                    mutableDict.updateAllOccurrences(ofKey: targetKey, with: newValue)
                    nestedArray[i] = mutableDict
                }
                self[key] = nestedArray
            } else if var nestedAnyArray = value as? [Any] {
                // Handle arrays of mixed types
                for i in 0..<nestedAnyArray.count {
                    if var nestedDict = nestedAnyArray[i] as? [String: Any] {
                        nestedDict.updateAllOccurrences(ofKey: targetKey, with: newValue)
                        nestedAnyArray[i] = nestedDict
                    }
                }
                self[key] = nestedAnyArray
            }
        }
    }
    
    /**
     Creates a new dictionary with all occurrences of a specific key updated with a new value.
     
     - Parameters:
        - key: The key to search for and update
        - value: The new value to set for the matching keys
     
     - Returns: A new dictionary with the updated values
     */
    func updatingAllOccurrences<T>(ofKey targetKey: String, with newValue: T) -> [String: Any] {
        var copy = self
        copy.updateAllOccurrences(ofKey: targetKey, with: newValue)
        return copy
    }
}
