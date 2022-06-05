//
//  Vocabulary.swift
//  AppQualityAnalysis
//
//  Created by Vlad Nechyporenko on 11.11.2021.
//

import Foundation

//class that is used to create a vocabulary in MetricModelConstants
class Vocabulary {
    
    //MARK: - Properties
    
    var vocabulary = [String:Int]()
    
    //text data(for example book)
    private var vocabularyData = ""
    
    //MARK: - Init
    
    init(path: String){
        readText(name: path)
        studyModel()
    }
    
    //MARK: - Functions
    
    private func studyModel()
    {
        vocabulary = [String:Int]()
        var substring = ""
        vocabularyData = vocabularyData.removingWhitespaces().lowercased().letters
        for character in vocabularyData {
            substring += String(character)
            if substring.count == VocabularyConstants.charactersInSubstring {
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
    
    private func readText(name: String) {
        let path = "/Users/vladnechiporenko/Downloads/" + name
        do {
            let fileContents = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            vocabularyData += fileContents
        } catch {
            print("Opps there was a problem reading the file contents")
        }
    }
}

//MARK: - Constants

private struct VocabularyConstants {
    static let charactersInSubstring = 2
}
