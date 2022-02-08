//
//  Vocabulary.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechiporenko on 11.11.2021.
//

import Foundation

class Vocabulary {
    
    var vocabulary = [String:Int]()
    var vocabularyData = ""
    
    init(path: String){
        readText(name: path)
    }
    
    func studyModel()
    {
        vocabulary = [String:Int]()
        var substring = ""
        vocabularyData = vocabularyData.removingWhitespaces().lowercased().letters
        for x in vocabularyData {
            substring += String(x)
            if substring.count == 2 {
                if vocabulary.keys.contains(substring) {
                    vocabulary[substring]! += 1
                }
                else {
                    vocabulary[substring] = 1
                }
                substring = ""
            }
        }
        print(vocabulary)
    }
    
    func readText(name: String) {
        let path = "/Users/vladnechiporenko/Downloads/" + name
        do {
            let fileContents = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            
            vocabularyData += fileContents
        } catch {
            print("Opps there was a problem reading the file contents")
        }
    }
}

extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    var letters: String {
        return String(unicodeScalars.filter(CharacterSet.letters.contains))
    }
}
