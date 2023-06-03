//generate a macOS swift command line program using spm ArgumentParser that accepts a prompt as command line argument and calls the chatGPT API once per minute, print the response from chatGPT forever
//  pumper
//
//  Created by bill donner on 5/7/23.
//

// this runs on ios for experimentation only, its a mac program really
import Darwin
import Foundation
import q20kshare


var pumpCount = 0
var badJsonCount = 0
var networkGlitches = 0
var first = true
var tagval:Int = 0
var global_index = 0
var fileHandle:FileHandle? = nil


struct ChatGPTResponse: Codable {
  let choices: [ChatGPTChoice]
}

struct ChatGPTChoice: Codable {
  let text: String
}

let apiURL = "https://api.openai.com/v1/completions"

func generateFileName(prefixPath:String) -> String {
  let date = Date()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMdd_HHmmss"
  let dateString = formatter.string(from: date)
  let fileName = prefixPath + "_" + dateString //+ ".txt"
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
func callChapGPT(tag:String,
                 nodots:Bool,
                 verbose:Bool,
                 prompt:String,
                 outputting: @escaping (String)->Void ,wait:Bool = false ) throws
{
    
  let  looky = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
  guard let apiKey = looky  else { fatalError("OPENAI_API_KEY not found in environment") }
  print(">Pumper Using apikey: " + apiKey)
  guard let url = URL(string: apiURL) else {
    fatalError("Invalid API URL")
  }
  
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  request.setValue("Bearer " + apiKey, forHTTPHeaderField: "Authorization")
  request.timeoutInterval = 240//yikes
  
  var respo:String = ""
  
  let parameters: [String: Any] = [
    "prompt": prompt,
    "model": "text-davinci-003",
    "max_tokens": 2000,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0,
    "temperature": 1.0
  ]
  request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
  if verbose {
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
      print ("*** Failed to decode response from AI ***",respo,error)
      networkGlitches += 1
      print("*** continuing ***\n")
      return
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
      if !nodots {print("\(cycle)",terminator: "")}
      cycle = (cycle+1) % 10
    }
  }
}
#if os(iOS)
/// the ios variant exists only for testing
struct Pumper {
  var url: String = "https://billdonner.com/fs/gd/pumper-data.txt"
  var split_pattern = "***"
  var comments_pattern = "///"
  var max =  65535
  var nodots = true
  var verbose = false
  var dontcall = false
  var jsonvalid = false
}
#else

import ArgumentParser

struct Pumper: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Split up a file of Prompts and pump them in to the AI Assistant",
    version: "0.1.2",
    subcommands: [],
    defaultSubcommand: nil,
    helpNames: [.long, .short]
  )
  
  @Argument(help: "The url of the Sparky file to split")
  var url: String
  
  @Argument(help: "The pattern to use to split the file")
  var split_pattern: String
  
  @Argument(help: "The pattern to use to indicate a comments line")
  var comments_pattern: String
  
  @Option(name:.long, help:"Output file for AI JSON utterances")
  var output: String
  
  @Option(name: .shortAndLong, help: "How many prompts to create")
  var max: Int = 65535
  
  @Option(name: .shortAndLong, help: "Don't print dots whilst waiting")
  var nodots: Bool = true
  
  @Option(name: .shortAndLong, help: "Print a lot more")
  var verbose: Bool = true
  
  @Option(name: .shortAndLong, help: "Don't call AI")
  var dontcall: Bool = false
  
  @Option(name: .shortAndLong, help: "Generate valid JSON for Prepper")
  var jsonValid: Bool = true
  
}

#endif

extension Pumper {
  fileprivate func dontCallTheAI(_ tag: String, _ prompt: String, _ index:Int) {
    print("\n>Deliberately not calling AI for prompt #\(tag):\n")
    print(prompt)
    //sleep(3)
  }
  
  fileprivate func handleAIResponse(_ cleaned: [String] ) {
    // check to make sure it's valid and write to output file
    for idx in 0..<cleaned.count {
      do {
        let _ = try JSONDecoder().decode(Challenge.self,from:cleaned[idx].data(using:.utf8)!)
        if let fileHandle = fileHandle  {
          // append response with prepended comma if we need one
          if !first {
            fileHandle.write(",".data(using: .utf8)!)
          } else {
            first = false
          }
          fileHandle.write(cleaned[idx].data(using: .utf8)!)
          pumpCount += 1
          if pumpCount >= max {
            break
          }
        }
      } catch {
        print(">Could not decode \(error), \n>*** BAD JSON FOLLOWS ***\n\(cleaned[idx])\n>*** END BAD JSON ***\n")
        badJsonCount += 1
        print("*** continuing ***\n")
      }
    }
  }
  
  fileprivate func callTheAI(_ tag: String, _ prompt: String, _ idx: Int) {
    // going to call the ai
    let start_time = Date()
    do {
      let start_count = pumpCount
      try callChapGPT(tag:tag, nodots: nodots,
                      verbose:verbose ,prompt : prompt,
                      outputting:  { response in
        
        let cleaned = extractSubstringsInBrackets(input:   //((idx==1) ? "{ " : "")
                                                  "{ "
                                                  + response)
       
        handleAIResponse(cleaned )// if not good then pumpCount not
        if cleaned.count == 0 {
          print("\n>AI Response #\(tag): no challenges  \n")
          return
        }
        let elapsed = Date().timeIntervalSince(start_time)
        print("\n>AI Response #\(tag): \(pumpCount-start_count)/\(cleaned.count) challenges returned in \(elapsed) secs\n")
        if pumpCount >= max {
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
  
  func prepOutputChannels() {
    if output != "" {
      guard let outurl = URL(string:output) else {
        print("Bad output url") ; return
      }
      guard  output.hasPrefix("file://") else
      {
        print("Only local files supported"); return
      }
      
      let s = outurl.deletingPathExtension().absoluteString.dropFirst(7)
      let x = generateFileName(prefixPath: String(s)) + "." + outurl.pathExtension
      if (FileManager.default.createFile(atPath: String(x), contents: nil, attributes: nil)) {
        print("\(x) created successfully.")
      } else {
        print("\(x) not created."); return
      }
      guard let  newurl = URL(string:x)  else {
        print("\(x) is a bad url"); return
      }
      do {
        fileHandle = try FileHandle(forWritingTo: newurl)
        if let fileHandle = fileHandle , jsonValid {
          // only generate full valid json if requested
          fileHandle.write("[".data(using: .utf8)!)
        }
      } catch {
        print("Cant write to \(newurl), \(error)"); return
      }
    }
  }
  
  func run() throws {
    
    defer {
      if let fileHandle = fileHandle {
        if jsonValid {
          // only generate full valid json if requested
          fileHandle.write("]".data(using: .utf8)!)
        }
        try! fileHandle.close()
      }
        print(">Pumper Exiting Normally - Pumped:\(pumpCount)" + " Bad Json: \( badJsonCount)" + " Network Issues: \(networkGlitches)\n")
      
    }
    print(">Pumper Command Line: \(CommandLine.arguments)")
    print(">Pumper running at \(Date())\n")
    guard let url = URL(string:url) else {  print ("bad url"); return  }
    let contents = try String(contentsOf: url)
    let templates = contents.split(separator: split_pattern)
    if  verbose {
      print(">Prompts url: \(url)  (\(contents.count) bytes, \(templates.count) chunks")
      print(">Contacting: \(apiURL)\n\n")
    }
    
    prepOutputChannels()
    while pumpCount<=max {
      // keep doing until we hit user defined limit
      do {
        for t in templates {
          guard pumpCount < max else { break }
          let prompt0 = stripComments(source: String(t), commentStart: comments_pattern)
          let prompt = standardSubstitutions(source:prompt0)
          global_index += 1
          
          if prompt.count > 0 {
            tagval += 1
            
            let tag = String(format:"%03d",tagval) +  "-\(pumpCount)" + "-\( badJsonCount)" + "-\(networkGlitches)"
            
            if dontcall {
              dontCallTheAI(tag, prompt, global_index)
            } else {
              callTheAI(tag, prompt, global_index)
            }
          }
        }// for
      }
    } // end pumpcount<=max
    if pumpCount < max  {
      RunLoop.current.run() // suggested by fivestars blog
    }
    print(">Pumper Exiting Normally - Pumped:\(pumpCount)" + " Bad Json: \( badJsonCount)" + " Network Issues: \(networkGlitches)\n")
  }// otherwise we should exit
}
#if os(iOS)
try Pumper().run()
#else
Pumper.main()
#endif

print(">Pumper Exiting Normally - Pumped:\(pumpCount)" + " Bad Json: \( badJsonCount)" + " Network Issues: \(networkGlitches)\n")
