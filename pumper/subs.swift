//
//  subs.swift
//  pumper
//
//  Created by bill donner on 6/9/23.
//

import Foundation
struct ChatGPTResponse: Codable {
  let choices: [ChatGPTChoice]
}

struct ChatGPTChoice: Codable {
  let text: String
}

let aiURLString = "https://api.openai.com/v1/completions"

func generateFileNameForJSON(prefixPath:String) -> String {
  let date = Date()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMdd_HHmmss"
  let dateString = formatter.string(from: date)
  let fileName = prefixPath + "-out-" + dateString + ".json"
  return fileName
}
func generateFileNameForPromptsLog(prefixPath:String) -> String {
  let date = Date()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMdd_HHmmss"
  let dateString = formatter.string(from: date)
  let fileName = prefixPath + "-log-" + dateString + ".txt"
  return fileName
}

func standardSubstitutions(source:String)->String {
  let source0 = source.replacingOccurrences(of:"$INDEX", with: "\(global_index)")
  let source1 = source0.replacingOccurrences(of:"$NOW", with: "\(Date())")
  let source2 = source1.replacingOccurrences(of: "$UUID", with: UUID().uuidString)
  return source2
}

func extractSubstringsInBrackets(input: String) -> [String] {
  var matches: [String] = []
  var completed: [Bool] = []
  var idx = 0 // into matches
  var inside = false
  matches.append("")
  completed.append(false)
  for c in input {
    switch c {
    case "{":
      if inside { continue }//fatalError("already inside")}
      inside = true
      matches [idx].append("{")
      completed [idx] =  false
    case "}":
      if !inside {  continue }//fatalError("not inside")}
      inside = false
      matches [idx].append("}")
      completed [idx] = true
      idx += 1
      matches.append("")
      completed.append(false)
    default: if inside {
      matches [idx].append(c)
    }
   }
  }
  if !completed[idx] {
    matches.removeLast()
  }
  return matches.filter {
    $0 != ""
  }
}
 
func stripComments(source: String, commentStart: String) -> String {
  let lines = source.split(separator: "\n")
  var keeplines:[String] = []
  for line in lines  {
    if !line.hasPrefix(commentStart) {
      keeplines += [String(line)]
    }
  }
  return keeplines.joined(separator: "\n")
}

