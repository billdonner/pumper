//
//  callAI.swift
//  pumper
//
//  Created by bill donner on 6/9/23.
//

import Foundation
import q20kshare

let ChatGPTModel = "text-davinci-003"

func callTheAI(ctx:ChatContext,  _ prompt: String, _ veracityMode:Bool) {

  // going to call the ai
  let start_time = Date()
  do {
    let start_count = ctx.pumpCount
    try callChatGPT(ctx:ctx,
                    prompt : prompt,
                    outputting:  { response in
      
      let cleaned = veracityMode ? [response.trimmingCharacters(in: .whitespacesAndNewlines)]
      : extractSubstringsInBrackets(input: "{ "  + response)
      if veracityMode {
        handleAIResponseVeracity(ctx: ctx, cleaned )
      } else {
        handleAIResponseNormal(ctx:ctx, cleaned )
      }// if not good then pumpCount not
      if cleaned.count == 0 {
        print("\n>AI Response #\(ctx.tag): no challenges  \n")
        return
      }
      ctx.pumpCount += 1
      let elapsed = Date().timeIntervalSince(start_time)
      print("\n>AI Response #\(ctx.tag): \(ctx.pumpCount-start_count)/\(cleaned.count) challenges returned in \(elapsed) secs\n")
      if ctx.pumpCount >= ctx.max {
        Pumper.exit()
      }
    }, wait:true)
    // did not throw
  } catch {
    // if callChapGPT throws we end up here and just print a message and continu3
    let elapsed = Date().timeIntervalSince(start_time)
    print("\n>AI Response #\(ctx.tag): ***ERROR \(error) no challenges returned in \(elapsed) secs\n")
  }
}


