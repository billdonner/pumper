//generate a macOS swift command line program using spm ArgumentParser that accepts a prompt as command line argument and calls the chatGPT API once per minute, print the response from chatGPT forever
//  pumper
//
//  Created by bill donner on 5/7/23.
//

// this runs on ios for experimentation only, its a mac program really

import Foundation


struct ChatGPTResponse: Codable {
  let choices: [ChatGPTChoice]
}

struct ChatGPTChoice: Codable {
  let text: String
}

let apiURL = "https://api.openai.com/v1/completions"

func callChapGPT(tag:String,
                 nodots:Bool,
                 verbose:Bool,
                 prompt:String,
                 outputting: @escaping (String)->Void ,wait:Bool = false ) throws {
  
  let apiKey = "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"
  
  guard let url = URL(string: apiURL) else {
    fatalError("Invalid API URL")
  }
  
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  request.setValue("Bearer " + apiKey, forHTTPHeaderField: "Authorization")
  request.timeoutInterval = 120
  
  var respo:String = ""
  
  let parameters: [String: Any] = [
    "prompt": prompt,
    "model": "text-davinci-003",
    "max_tokens": 1800,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0,
    "temperature": 1.0
  ]
  request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
  if verbose {
    print("\n>Prompt #\(tag): \n\(prompt) \n\n>Awaiting response #\(tag) from chatGPT.",terminator:"")
  }
  let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
    guard let data = data, error == nil else {
      print(error?.localizedDescription ?? "Unknown error")
      return
    }
    do {
      let response = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
      respo  = response.choices.first?.text ?? "<<nothin>>"
      outputting(respo)
    }  catch {
      print ("Failed to decode response ",error,respo)
      return
    }
  }
  task.resume()
  // linger here if asked to wait
  if wait {
    while true   {
      if !nodots {print(".",terminator: "")}
      if respo != "" { break }
      sleep(1)
    }
  }
}
#if os(iOS)

struct Pumper {
  
  var url: String = "https://billdonner.com/fs/gd/pumper-data.txt"
  
  var split_pattern = "***"
  
  var comments_pattern = "///"
  
  var `repeat` =  1
  
  var nodots = true
  
  var verbose = false
  
  var dontcall = false
  
}
#else

import ArgumentParser

struct Pumper: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Split up a file of Prompts and pump them in to the AI Assistant",
    version: "0.1.1",
    subcommands: [],
    defaultSubcommand: nil,
    helpNames: [.long, .short]
  )
  
  @Argument(help: "The url of the file to split")
  var url: String
  
  @Argument(help: "The pattern to use to split the file")
  var split_pattern: String
  
  @Argument(help: "The pattern to use to indicate a comments line")
  var comments_pattern: String
  
  @Option(name:.long, help:"Output file for AI JSON utterances")
  var output: String
  
  @Option(name: .shortAndLong, help: "Read input N times, creating more prompts")
  var `repeat`: Int = 1
  
  @Option(name: .shortAndLong, help: "Don't print dots whilst waiting")
  var nodots: Bool = false
  
  @Option(name: .shortAndLong, help: "Print a lot more")
  var verbose: Bool = true
  
  @Option(name: .shortAndLong, help: "Don't call AI")
  var dontcall: Bool = false
  
}

#endif
extension Pumper {
  func run() throws {
    var tagval:Int = 0
    var fileHandle:FileHandle? = nil
    defer {
      if let fileHandle = fileHandle {
       try! fileHandle.close()
      }
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
    func cleanup(string:String) -> String {
      let jsons = extractSubstringsInBrackets(input: string)
      return jsons.joined(separator: ",") + ","
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
    if let url = URL(string:url) {
      if output != "" {
        guard let outurl = URL(string:output) else {
          print("Bad output url") ; return
        }
       fileHandle = try FileHandle(forWritingTo: outurl)
      }
      for idx in 1...`repeat` {
        // Get the contents of the file.
        let contents = try String(contentsOf: url)
        if idx == 1 && verbose {
          print(">Prompts url: \(url)  (\(contents.count) bytes)")
          print(">Contacting: \(apiURL)\n\n")
        }
        // Split the contents of the file into chunks using the pattern.
        let chunks = contents.split(separator: split_pattern)
        for chunk in chunks {
          let prompt = stripComments(source: String(chunk), commentStart: comments_pattern)
          if prompt.count > 0 {
            tagval += 1
            let tag = String(format:"%03d",tagval) +  " \(Date())"
            if dontcall {
              print("\n>Deliberately not calling AI for prompt #\(tag):")
              print(prompt)
              sleep(3)
            } else {
              try callChapGPT(tag:tag, nodots: nodots,
                              verbose:verbose ,prompt : prompt,
                              outputting:  { response in
                let pref = "{ \"id:\""
                let cleaned = cleanup(string:   ((idx==1) ? pref : "") + response)
                if verbose {
                  print("\n>AI Response #\(tag):")
                }
                print("\n\(cleaned)")
                if let fileHandle = fileHandle  {
                  // append response
                  fileHandle.write(cleaned.data(using: .utf8)!)
                }
              }, wait:true)
            }
          }
        }
      }
    }
    else {
      print ("bad url")
    }
    RunLoop.current.run() // suggested by fivestars blog
    //sleep(120)
  }
}
#if os(iOS)
try Pumper().run()
#else
Pumper.main()
#endif
