//
//  subs.swift
//  pumper
//
//  Created by bill donner on 6/9/23.
//

import Foundation


let aiURLString = "https://api.openai.com/v1/completions"

func generateFileNameForJSON(prefixPath:String,veracity:Bool = false ) -> String {
  let date = Date()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMdd_HHmmss"
  let dateString = formatter.string(from: date)
  let fileName = prefixPath + (veracity ? "-veracityout-" : "-out-")
  + dateString + ".json"
  return fileName
}
func generateFileNameForPromptsLog(prefixPath:String,veracity:Bool = false ) -> String {
  let date = Date()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMdd_HHmmss"
  let dateString = formatter.string(from: date)
  let fileName = prefixPath + (veracity ?  "-veracitylog-" : "-log-")
  + dateString + ".txt"
  return fileName
}
