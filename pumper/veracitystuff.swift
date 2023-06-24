//
//  veracitystuff.swift
//  pumper
//
//  Created by bill donner on 6/24/23.
//

import Foundation
import q20kshare
func handleAIResponseVeracity(ctx:ChatContext,_ cleaned: [String]) {
  func handleVeracityMode(ctx:ChatContext,item:String) throws {
    let opinion = try getOpinion(item,source:ChatGPTModel)
    if let opinion = opinion {
      // 3. write JSON to file
      if let fileHandle = jsonOutHandle  {
        // append response with prepended comma if we need one
        if !ctx.first {
          fileHandle.write(",".data(using: .utf8)!)
        } else {
          ctx.first  = false
        }
        // 4. encode Challenge as JSON and write that out
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(opinion)
        let str = String(data:data,encoding: .utf8)
        if let str = str {
          fileHandle.write(str.data(using: .utf8)!)
        }
      }
      
    }
  }

  // check to make sure it's valid and write to output file
  for idx in 0..<cleaned.count {
    do {
      let item = cleaned [idx]
        try handleVeracityMode(ctx:ctx,item:item)
    }// do
    catch {
      print(">Could not decode \(error), \n>*** BAD JSON FOLLOWS ***\n\(cleaned[idx])\n>*** END BAD JSON ***\n")
      ctx.badJsonCount += 1
      print("*** continuing ***\n")
    }
  }
}

