//
//  pumperstuff.swift
//  pumper
//
//  Created by bill donner on 6/24/23.
//

import Foundation
import q20kshare


func handleAIResponseNormal(ctx:ChatContext,_ cleaned: [String]) {
  func handleNormalMode(ctx:ChatContext,item:String ) throws {
   // 1. verify we got a proper AIReturns json
   let aireturns = try JSONDecoder().decode(AIReturns.self,from:item.data(using:.utf8)!)
   // 2. make a Challenge from the stuff from AI
   let challenge:Challenge = aireturns.toChallenge()
   // 3. write JSON to file
   if let fileHandle = jsonOutHandle  {
     // append response with prepended comma if we need one
     if ctx.global_index == 0 {
       fileHandle.write(",".data(using: .utf8)!)
       ctx.global_index = 1
     }
     // 4. encode Challenge as JSON and write that out
     let encoder = JSONEncoder()
     encoder.outputFormatting = .prettyPrinted
     let data = try encoder.encode(challenge)
     let str = String(data:data,encoding: .utf8)
     if let str = str {
       fileHandle.write(str.data(using: .utf8)!)
     }
   }
 }
  // check to make sure it's valid and write to output file
  for idx in 0..<cleaned.count {
    do {
      let item = cleaned [idx]
     
        try handleNormalMode(ctx:ctx,item:item)
   
    }// do
    catch {
      print(">Could not decode \(error), \n>*** BAD JSON FOLLOWS ***\n\(cleaned[idx])\n>*** END BAD JSON ***\n")
      ctx.badJsonCount += 1
      print("*** continuing ***\n")
    }
  }
}
 
