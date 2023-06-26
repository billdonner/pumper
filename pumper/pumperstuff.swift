//
//  pumperstuff.swift
//  pumper
//
//  Created by bill donner on 6/24/23.
//

import Foundation
import q20kshare

extension Pumper:ChatBotInterface {

  func callTheAI(ctx:ChatContext,prompt: String,jsonOut:FileHandle? ) throws {
    // going to call the ai
    let start_time = Date()
    do {
      let start_count = ctx.pumpCount
      try callChatGPT(ctx:ctx,
                      prompt : prompt,
                      outputting:  { response in
        // process response from chatgpt
        let cleaned = extractSubstringsInBrackets(input: "{ "  + response)
        handleAIResponse(ctx:ctx, cleaned:cleaned, jsonOut:jsonOut )
        // if not good then pumpCount not
        if cleaned.count == 0 {
          print("\n>AI Response #\(ctx.tag): no challenges  \n")
          return
        }
        ctx.pumpCount += 1
        let elapsed = Date().timeIntervalSince(start_time)
        print("\n>AI Response #\(ctx.tag): \(ctx.pumpCount-start_count)/\(cleaned.count) challenges returned in \(elapsed) secs\n")
        if ctx.pumpCount >= ctx.max {
         return // Pumper.exit()
        }
      }, wait:true)
      // did not throw
    } catch {
      // if callChapGPT throws we end up here and just print a message and continu3
      let elapsed = Date().timeIntervalSince(start_time)
      print("\n>AI Response #\(ctx.tag): ***ERROR \(error) no challenges returned in \(elapsed) secs\n")
    }
  }
  
  func handleAIResponse(ctx:ChatContext,cleaned: [String],jsonOut:FileHandle?) {
    func handleItem(ctx:ChatContext,item:String ) throws {
      // 1. verify we got a proper AIReturns json
      let aireturns = try decoder.decode(AIReturns.self,from:item.data(using:.utf8)!)
      // 2. make a Challenge from the stuff from AI
      let challenge:Challenge = aireturns.toChallenge(source:ChatGPTModel)
      
      // 3. write JSON to file
      if let fileHandle = jsonOut {
        // append response with prepended comma if we need one
        if ctx.global_index != 1 {
          fileHandle.write(",".data(using: .utf8)!)
        }
        // 4. encode Challenge as JSON and write that out
        
        let data = try encoder.encode(challenge)
        let str = String(data:data,encoding: .utf8)
        if let str = str {
          fileHandle.write(str.data(using: .utf8)!)
        }
      }
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let decoder = JSONDecoder()
    // check to make sure it's valid and write to output file
    for idx in 0..<cleaned.count {
      do {
        try handleItem(ctx:ctx,item:cleaned [idx])
      }
      catch {
        print(">Could not decode \(error), \n>*** BAD JSON FOLLOWS ***\n\(cleaned[idx])\n>*** END BAD JSON ***\n")
        ctx.badJsonCount += 1
        print("*** continuing ***\n")
      }
    }
  }
  func  prepOutputChannels(ctx:ChatContext)throws -> FileHandle? {
    func prep(_ x:String, initial:String) throws  -> FileHandle? {
      if (FileManager.default.createFile(atPath: x, contents: nil, attributes: nil)) {
        print(">Pumper created \(x)")
      } else {
        print("\(x) not created."); throw PumpingErrors.badOutputURL
      }
      guard let  newurl = URL(string:x)  else {
        print("\(x) is a bad url"); throw PumpingErrors.badOutputURL
      }
      do {
        let  fh = try FileHandle(forWritingTo: newurl)
        fh.write(initial.data(using: .utf8)!)
        return fh
      } catch {
        print("Cant write to \(newurl), \(error)"); throw PumpingErrors.cantWrite
      }
    }
    
    
    guard  ctx.outURL.absoluteString.hasPrefix("file://") else
    {
      throw PumpingErrors.onlyLocalFilesSupported
    }
    let s = String(ctx.outURL.deletingPathExtension().absoluteString.dropFirst(7))
    let x = s + ".json"
    return  try prep(x,initial:"[")
  }

  func pumpItUp(ctx:ChatContext, templates: [String],jsonOut:FileHandle) throws {

    while ctx.pumpCount<=ctx.max {
      // keep doing until we hit user defined limit
      for (idx,t) in templates.enumerated() {
        guard ctx.pumpCount <= ctx.max else { throw PumpingErrors.reachedMaxLimit }
        let prompt0 = stripComments(source: String(t), commentStart: ctx.comments_pattern)
        if t.count > 0 {
          let prompt = standardSubstitutions(source:prompt0,stats:ctx)
          if prompt.count > 0 {
            ctx.global_index += 1
            ctx.tag = String(format:"%03d",ctx.global_index) +  "-\(ctx.pumpCount)" + "-\( ctx.badJsonCount)" + "-\(ctx.networkGlitches)"
            if ctx.dontcall {
              dontCallTheAI(ctx:ctx, prompt: prompt)
            } else {
              try callTheAI(ctx: ctx, prompt: prompt,jsonOut:jsonOut)
            }
          }
        } else {
          print("Warning - empty template #\(idx)")
        }
      }// for
    }
    throw PumpingErrors.reachedMaxLimit
  }
  
}
