//
//  callAI.swift
//  pumper
//
//  Created by bill donner on 6/9/23.
//

import Foundation
import q20kshare
let ChatGPTModel = "text-davinci-003"
fileprivate func callChapGPT(pumper:Pumper, outputURL:URL,
                 tag:String,
                 prompt:String,
                 outputting: @escaping (String)->Void ,wait:Bool = false ) throws
{
  var request = URLRequest(url: outputURL)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  request.setValue("Bearer " + apiKey, forHTTPHeaderField: "Authorization")
  request.timeoutInterval = 240//yikes
  
  var respo:String = ""
  
  let parameters: [String: Any] = [
    "prompt": prompt,
    "model": ChatGPTModel,
    "max_tokens": 2000,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0,
    "temperature": 1.0
  ]
  request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
  if pumper.verbose {
    print("\n>Prompt #\(tag): \n\(prompt) \n\n>Awaiting response #\(tag) from AI.\n")
  }
  else {
    print("\n>Prompt #\(tag): Awaiting response from AI.\n")
  }
  
  let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
    guard let data = data, error == nil else {
      print("*** Network error communicating with AI ***")
      print(error?.localizedDescription ?? "Unknown error")
      networkGlitches += 1
      print("*** continuing ***\n")
      respo = " " // a hack to bust out of wait loop below
      return
    }
    do {
      let response = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
      respo  = response.choices.first?.text ?? "<<nothin>>"
      outputting(respo)
    }  catch {
      print ("*** Failed to decode response from AI ***\n",error)
      let str = String(decoding: data, as: UTF8.self)
      print (str)
      networkGlitches += 1
      print("*** NOT continuing ***\n")
      respo = " " // a hack to bust out of wait loop below
      //return
      exit(0)
    }
  }
  task.resume()
  // linger here if asked to wait
  if wait {
    var cycle = 0
    while true && respo == ""  {
      for _ in 0..<10 {
        if respo != "" { break }
        sleep(1)
      }
      if pumper.dots {print("\(cycle)",terminator: "")}
      cycle = (cycle+1) % 10
    }
  }
}

func callTheAI(pumper:Pumper, _ outputURL:URL,_ tag: String, _ prompt: String, _ idx: Int, _ veracityMode:Bool) {
  // going to call the ai
  let start_time = Date()
  do {
    let start_count = pumpCount
    try callChapGPT(pumper:pumper, outputURL:outputURL, tag:tag ,prompt : prompt,
                    outputting:  { response in
      
      let cleaned = veracityMode ? [response.trimmingCharacters(in: .whitespacesAndNewlines)]
      : extractSubstringsInBrackets(input: "{ "  + response)
      handleAIResponse(cleaned, veracityMode )// if not good then pumpCount not
      if cleaned.count == 0 {
        print("\n>AI Response #\(tag): no challenges  \n")
        return
      }
      pumpCount += 1
      let elapsed = Date().timeIntervalSince(start_time)
      print("\n>AI Response #\(tag): \(pumpCount-start_count)/\(cleaned.count) challenges returned in \(elapsed) secs\n")
      if pumpCount >= pumper.max {
        Pumper.exit()
      }
    }, wait:true)
    // did not throw
  } catch {
    // if callChapGPT throws we end up here and just print a message and continu3
    let elapsed = Date().timeIntervalSince(start_time)
    print("\n>AI Response #\(tag): ***ERROR \(error) no challenges returned in \(elapsed) secs\n")
  }
}
//write swift function to return substring of a string between a start delimeter and end delimeter.
//include comments

/*
 This function takes a string and two delimiters as arguments.
 It will return the substring which begins after the first delimiter and ends before the second one.
   -Parameter str: The original string which is to be searched
   -Parameter startDelim: The substring that is beginning of the substring to be extracted
   -Parameter endDelim: The substring that is the end of the substring to be extracted
   -Returns: A substring beginning after startDelim and ending before endDelim
*/
func extractSubstring(str: String, startDelim: String, endDelim: String) -> String {
    if !str.contains(startDelim) || !str.contains(endDelim) { return "" }
    
    let start = str.firstIndex(of: startDelim.first!)!
    let end = str.firstIndex(of: endDelim.first!)!

    return String(str[start...end])
}
fileprivate func getOpinion(_ xitem:String) throws -> Opinion? {
  let item = extractSubstring(str: xitem, startDelim: "{", endDelim: "}")
  guard item != "" else { print("** nothing found in getOpinion from \(xitem)"); return nil }
  var opinion:Opinion? = nil
  do {
    opinion = try JSONDecoder().decode(AIOpinion .self,from:item.data(using:.utf8)!).toOpinion(source: ChatGPTModel)
  }
  catch {
    do {
      opinion = try JSONDecoder().decode(AIAltOpinion .self,from:item.data(using:.utf8)!).toOpinion(source: ChatGPTModel)
    }
    catch {
      print("*** No opinion found \(error)\n item: '\(item)'")
    }
  }
  return opinion
}
 
fileprivate func handleVeracityMode(_ item:String) throws {
  let opinion = try getOpinion(item)
  if let opinion = opinion {
    // 3. write JSON to file
    if let fileHandle = jsonOutHandle  {
      // append response with prepended comma if we need one
      if !first {
        fileHandle.write(",".data(using: .utf8)!)
      } else {
        first = false
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
    // 5. separately
    if let fileHandle = promptLogHandle {
      fileHandle.write("***Opinion from \(opinion.source) \(opinion.id) \(opinion.generated)".data(using:.utf8)!)
      fileHandle.write (item.data(using:.utf8)!)
    }
  }
}

fileprivate func handleNormalMode(_ item:String ) throws {
  // 1. verify we got a proper AIReturns json
  let aireturns = try JSONDecoder().decode(AIReturns.self,from:item.data(using:.utf8)!)
  // 2. make a Challenge from the stuff from AI
  let challenge:Challenge = aireturns.toChallenge()
  // 3. write JSON to file
  if let fileHandle = jsonOutHandle  {
    // append response with prepended comma if we need one
    if !first {
      fileHandle.write(",".data(using: .utf8)!)
    } else {
      first = false
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
  // 5. separately
  if let fileHandle = promptLogHandle {
    fileHandle.write("*** Response \(challenge.id) ".data(using:.utf8)!)
    fileHandle.write (item.data(using:.utf8)!)
  }
}

fileprivate func handleAIResponse(_ cleaned: [String], _ veracityMode:Bool) {
  // check to make sure it's valid and write to output file
  for idx in 0..<cleaned.count {
    do {
      let item = cleaned [idx]
      if veracityMode {
        try handleVeracityMode(item)
      } else {
        try handleNormalMode(item)
      }
    }// do
    catch {
        print(">Could not decode \(error), \n>*** BAD JSON FOLLOWS ***\n\(cleaned[idx])\n>*** END BAD JSON ***\n")
        badJsonCount += 1
        print("*** continuing ***\n")
      }
    }
}

