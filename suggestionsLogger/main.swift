//
//  main.swift
//  suggestionsLogger
//
//  Created by Quentin Roy on 2019-11-06.
//  Copyright © 2019 Quentin Roy. All rights reserved.
//

import Foundation
import AppKit
import CSV

enum ConversionError: Error {
    case fileNotFound(fileName: String)
    case wordOutOfBound
}

func getSentenceSuggestions(sentence: String) -> (String, [String]?, [String]?, String?, String, [String]?) {
    let checker = NSSpellChecker.shared
    let language = checker.language()

    let nsString = NSString(string: sentence)
    let lastSpaceRange = nsString.range(of: " ", options: .backwards)
    // If there are no spaces, lastSpace.location will be a super large number.
    let lastWordRange = lastSpaceRange.location > sentence.count
        ? NSMakeRange(0, sentence.count)
        : NSMakeRange(lastSpaceRange.location + 1, sentence.count - lastSpaceRange.location - 1)
    let lastWord = nsString.substring(with: lastWordRange)
    
    let completions = checker.completions(
        forPartialWordRange: lastWordRange,
        in: sentence,
        language: language,
        inSpellDocumentWithTag: 0
    )
    
    let guesses = checker.guesses(
        forWordRange: lastWordRange,
        in: sentence,
        language: language,
        inSpellDocumentWithTag: 0
    )
    
    let correction = checker.correction(
        forWordRange: lastWordRange,
        in: sentence,
        language: language,
        inSpellDocumentWithTag: 0
    )
    
    var correctedSentence = sentence
    var completionsOnCorrection: [String]? = nil
    if let foundCorrection = correction {
        correctedSentence = "\(sentence.prefix(lastWordRange.location))\(foundCorrection)"
        completionsOnCorrection = checker.completions(
            forPartialWordRange: NSMakeRange(lastWordRange.location, correctedSentence.count - lastWordRange.location),
            in: correctedSentence,
            language: language,
            inSpellDocumentWithTag: 0
        )
    }
    
    return (lastWord, completions, guesses, correction, correctedSentence, completionsOnCorrection)
}


func writeCSVSuggestions(
    fromCSVAtPath inputPath: String,
    toFileAtPath path: String,
    forNumberOfSuggestions numberOfSuggestions: Int,
    withSentenceColumn sentenceColumn: String? = nil
) throws {
    // Create the input reader and the output writer.
    let inputStream = InputStream(fileAtPath: inputPath)!
    let inputCsv = try CSVReader(stream: inputStream, hasHeaderRow: sentenceColumn != nil)
    let outputStream = OutputStream(toFileAtPath: path, append: false)!
    let outputCsv = try CSVWriter(stream: outputStream)
    
   
    // This needs to be a variable. The compiler fails to type check if I am trying to
    // concatenate all these arrays at once...
    let inputHeaderRow = sentenceColumn == nil ? ["sentence"] : inputCsv.headerRow!
    var headerRow = inputHeaderRow
    headerRow +=  ["last_word"]
    headerRow += (1...numberOfSuggestions).map { "completion_\($0)" }
    headerRow += (1...numberOfSuggestions).map { "guess_\($0)" }
    headerRow += ["correction", "corrected_sentence"]
    headerRow += (1...numberOfSuggestions).map { "completion_on_correction_\($0)" }
    
    // Write the output header.
    try outputCsv.write(row: headerRow)
        
    // Read every lines in input, get the suggestions, and write them in output.
    while let row = inputCsv.next() {
        outputCsv.beginNewRow()
        let sentence = sentenceColumn == nil ? row[0] : inputCsv[sentenceColumn!]!
        let (
            lastWord,
            optionalCompletions,
            optionalGuesses,
            optionalCorrection,
            correctedSentence,
            optionalCompletionsOnCorrection
        ) = getSentenceSuggestions(sentence: sentence)
          
        let completions: [String] = optionalCompletions ?? []
        let guesses: [String] = optionalGuesses ?? []
        let completionsOnCorrection: [String] = optionalCompletionsOnCorrection ?? []
        
         for col in sentenceColumn == nil ? [sentence] : inputHeaderRow.map { inputCsv[$0]! } {
             try outputCsv.write(field: col)
         }
        
        try outputCsv.write(field: lastWord)
        
        for i in 0...(numberOfSuggestions - 1) {
            if completions.indices.contains(i) {
                try outputCsv.write(field: completions[i])
            } else {
                try outputCsv.write(field: "")
            }
        }
        
        for i in 0...(numberOfSuggestions - 1) {
            if guesses.indices.contains(i) {
                try outputCsv.write(field: guesses[i])
            } else {
                try outputCsv.write(field: "")
            }
        }
        
        if let correction = optionalCorrection {
            try outputCsv.write(field: correction)
        } else {
            try outputCsv.write(field: "")
        }
        
        try outputCsv.write(field: correctedSentence)
        
        for i in 0...(numberOfSuggestions - 1) {
            if completionsOnCorrection.indices.contains(i) {
                try outputCsv.write(field: completionsOnCorrection[i])
            } else {
                try outputCsv.write(field: "")
            }
        }
    }
    
    // Close the output stream.
    outputCsv.stream.close()
}

func findWord(inSentence sentence: String, atIndex index: Int) throws -> (Int, String) {
    var current = 0
    for (wordIndex, word) in sentence.components(separatedBy: " ").enumerated() {
        if (word.count + current >= index) {
            return (wordIndex, word)
        }
        // Adding 1 because we are skipping white spaces.
        current += word.count + 1
    }
    throw ConversionError.wordOutOfBound
}

func writeCSVSuggestions(
    fromTextAtPath inputPath: String,
    toFileAtPath path: String,
    forNumberOfSuggestions numberOfSuggestions: Int
) throws {
    let pathURL = URL(fileURLWithPath: inputPath)
    guard FileManager.default.fileExists(atPath: pathURL.path) else {
        throw ConversionError.fileNotFound(fileName: inputPath)
    }
    let streamReader = StreamReader(url: pathURL)!
    
    let outputStream = OutputStream(toFileAtPath: path, append: false)!
    let outputCsv = try CSVWriter(stream: outputStream)
    
    // This needs to be a variable. The compiler fails to type check if I am trying to
    // concatenate all these arrays at once...
    var headerRow = ["sentence_num", "full_sentence", "char_num", "input", "full_last_word", "word_num", "last_word_input"]
    headerRow += (1...numberOfSuggestions).map { "completion_\($0)" }
    headerRow += (1...numberOfSuggestions).map { "guess_\($0)" }
    headerRow += ["correction", "corrected_sentence"]
    headerRow += (1...numberOfSuggestions).map { "completion_on_correction_\($0)" }
    
    // Write the output header.
    try outputCsv.write(row: headerRow)

    let start = NSDate().timeIntervalSince1970
    var sentenceNum = -1
    var totalChar = 0
    while let line: String = streamReader.nextLine() {
        for comp in line.components(separatedBy: ".") {
            let sentence = comp.trimmingCharacters(in: .whitespacesAndNewlines)
            let now = NSDate().timeIntervalSince1970
            let speed = now == start ? Float(0) : Float(totalChar) / Float(now - start)
            sentenceNum += 1
            totalChar += sentence.count
            print("Creating suggestions for sentence \(sentenceNum) (\(speed) char/s)...\r", terminator: "")
            fflush(stdout)
            for charNum in 0...sentence.count {
                outputCsv.beginNewRow()
                let input = String(sentence.prefix(charNum))
                let (lastWordIndex, lastWord) = try findWord(inSentence: sentence, atIndex: charNum)
                let (
                    lastWordInput,
                    optionalCompletions,
                    optionalGuesses,
                    optionalCorrection,
                    correctedSentence,
                    optionalCompletionsOnCorrection
                ) = getSentenceSuggestions(sentence: input)
                
                let completions: [String] = optionalCompletions ?? []
                let guesses: [String] = optionalGuesses ?? []
                let completionsOnCorrection: [String] = optionalCompletionsOnCorrection ?? []
                
                try outputCsv.write(field: String(sentenceNum))
                try outputCsv.write(field: sentence)
                try outputCsv.write(field: String(charNum))
                try outputCsv.write(field: input)
                try outputCsv.write(field: lastWord)
                try outputCsv.write(field: String(lastWordIndex))
                try outputCsv.write(field: lastWordInput)
                
                for i in 0...(numberOfSuggestions - 1) {
                    if completions.indices.contains(i) {
                        try outputCsv.write(field: completions[i])
                    } else {
                        try outputCsv.write(field: "")
                    }
                }
                
                for i in 0...(numberOfSuggestions - 1) {
                    if guesses.indices.contains(i) {
                        try outputCsv.write(field: guesses[i])
                    } else {
                        try outputCsv.write(field: "")
                    }
                }
                
                try outputCsv.write(field: optionalCorrection ?? "")
                
                try outputCsv.write(field: correctedSentence)
                
                for i in 0...(numberOfSuggestions - 1) {
                    if completionsOnCorrection.indices.contains(i) {
                        try outputCsv.write(field: completionsOnCorrection[i])
                    } else {
                        try outputCsv.write(field: "")
                    }
                }
            }
        }
    }
    print("\nDone!")
}

enum InputType: String {
    case csv = "csv"
    case text = "text"
}

func main() -> Int32 {
    do {
        let optionDefinitions = [
            CommandLineOptionDefinition(
                name: "help",
                letter: "h",
                valueType: .noValue,
                briefHelp: "Show this help message"),

            CommandLineOptionDefinition(
                name: "input-file",
                letter: "i",
                valueType: .string("path"),
                briefHelp: "Specify input file path"),

            CommandLineOptionDefinition(
                name: "output-file",
                letter: "o",
                valueType: .string("path"),
                briefHelp: "Specify output file path"),
            
            CommandLineOptionDefinition(
                name: "sentence-column",
                letter: "s",
                valueType: .string("sentence"),
                briefHelp: "(optional) CSV-type only: specify the name of the column in the input file to use as a sentence. If unspecified, the program will use the first column and assume that there are no headers."),
            
            CommandLineOptionDefinition(
                name: "input-type",
                letter: "t",
                valueType: .string("type"),
                briefHelp: "The type of input file (csv or text, default: text)")
        ]
        let result = try CommandLineParseResult(arguments: CommandLine.arguments, optionDefinitions: optionDefinitions)
        
        if !result.isPresent(optionNamed: "input-file") || !result.isPresent(optionNamed: "output-file") {
            printHelp(optionDefinitions: optionDefinitions, firstColumnWidth: 30)
            return result.isPresent(optionNamed: "help") ? 0: 1
        }
        
        var sentenceColumn: String? = nil
        if case let .string(s) = result.value(optionNamed: "sentence-column") {
            sentenceColumn = s
        }
        
        var type: InputType? = nil;
        if case let .string(inputTypeArg) = result.value(optionNamed: "input-type") {
            type = InputType(rawValue: inputTypeArg)
        } else {
            type = .text
        }
    
        if case .csv = type,
            case let .string(inputFile) = result.value(optionNamed: "input-file"),
            case let .string(outputFile) = result.value(optionNamed: "output-file") {
                try writeCSVSuggestions(
                    fromCSVAtPath: inputFile,
                    toFileAtPath: outputFile,
                    forNumberOfSuggestions: 10,
                    withSentenceColumn: sentenceColumn
                )
                return 0
        } else if case .text = type,
            case nil = sentenceColumn,
            case let .string(inputFile) = result.value(optionNamed: "input-file"),
            case let .string(outputFile) = result.value(optionNamed: "output-file") {
                try writeCSVSuggestions(
                    fromTextAtPath: inputFile,
                    toFileAtPath: outputFile,
                    forNumberOfSuggestions: 10
                )
                return 0
        }
        
        printHelp(optionDefinitions: optionDefinitions, firstColumnWidth: 30)
        return 1
        
    } catch {
        print("Unexpected error: \(error).")
        return 1
    }
}

exit(main())
