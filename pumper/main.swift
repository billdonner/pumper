//generate a macOS swift command line program using spm ArgumentParser that accepts a prompt as command line argument and calls the chatGPT API once per minute, print the response from chatGPT forever
//  pumper
//
//  Created by bill donner on 5/7/23.
//

// this runs on ios for experimentation only, its a mac program really
import Darwin
import Foundation
import q20kshare

var apiKey = ""
var aiURL: URL?

var first = true
var tagval:Int = 0
var global_index = 0
var jsonOutHandle:FileHandle? = nil
var promptLogHandle:FileHandle? = nil


var pumpCount = 0
var badJsonCount = 0
var networkGlitches = 0

enum PumperError: Error {
  case badInputURL
  case badOutputURL
  case cantWrite
  case noAPIKey
  case onlyLocalFilesSupported
}

import ArgumentParser

struct Pumper: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Split up a script file of Prompts and pump them in to the AI\n\n version 0.1.3",
    version: "0.1.3",
    subcommands: [],
    defaultSubcommand: nil,
    helpNames: [.long, .short]
  )
  
  @Argument(help: "The url of input script")
  var url: String
  
  @Argument( help:"Output file for AI JSON utterances")
  var output: String
  
  @Option(name:.long,help: "The pattern to use to split the file")
  var split_pattern: String = "***"
  
  @Option(name:.long,help: "The pattern to use to indicate a comments line")
  var comments_pattern: String = "///"
  
  @Option(name: .long, help: "How many prompts to create")
  var max: Int = 65535
  
  @Option(name: .long, help: "Print dots whilst awaiting AI")
  var dots: Bool = false
  
  @Option(name: .long, help: "Print a lot more")
  var verbose: Bool = false
  
  @Option(name: .long , help: "Unique File Names")
  var unique : Bool = true
  
  @Option(name: .shortAndLong, help: "Don't call AI")
  var dontcall: Bool = false
  
  @Option(name: .long, help: "Run in Veracity Mode")
  var veracity: Bool = false
  
  
  fileprivate func dontCallTheAI(_ tag: String, _ prompt: String, _ index:Int) {
    print("\n>Deliberately not calling AI for prompt #\(tag):\n")
    print(prompt)
    //sleep(3)
  }
  
  fileprivate func prepOutputChannels() throws {
    func prep(_ x:String, initial:String) throws  -> FileHandle? {
      if (FileManager.default.createFile(atPath: x, contents: nil, attributes: nil)) {
        print(">Pumper created \(x)")
      } else {
        print("\(x) not created."); throw PumperError.badOutputURL
      }
      guard let  newurl = URL(string:x)  else {
        print("\(x) is a bad url"); throw PumperError.badOutputURL
      }
      do {
        let  fh = try FileHandle(forWritingTo: newurl)
        fh.write(initial.data(using: .utf8)!)
        return fh
      } catch {
        print("Cant write to \(newurl), \(error)"); throw PumperError.cantWrite
      }
    }
    
    guard let outurl = URL(string:output) else {
      print("Bad output url") ; return
    }
    guard  output.hasPrefix("file://") else
    {
      throw PumperError.onlyLocalFilesSupported
    }
    let s = String(outurl.deletingPathExtension().absoluteString.dropFirst(7))
    let x = unique ? generateFileNameForJSON(prefixPath:s,veracity: veracity) : s + ".json"
    let y = unique ? generateFileNameForPromptsLog(prefixPath:s,veracity:veracity) : s + ".txt"
    jsonOutHandle = try prep(x,initial:"[")
    promptLogHandle = try prep(y,initial:"*** Prompts file produced by Pumper /(Date())")
  }
  
  
  fileprivate func closeFile(fh:FileHandle?,suffix:String? = nil) {
    if let fileHandle = fh , let suf = suffix {
      fileHandle.write(suf.data(using: .utf8)!)
      try! fileHandle.close()
    }
  }
  
  fileprivate func pumpItUp(_ templates: [String]) {
    while pumpCount<=max {
      // keep doing until we hit user defined limit
        for (idx,t) in templates.enumerated() {
          guard pumpCount < max else { break }
          let prompt0 = stripComments(source: String(t), commentStart: comments_pattern)
          if t.count > 0 {
            let prompt = standardSubstitutions(source:prompt0)
       
            if prompt.count > 0 {
              global_index += 1
              tagval += 1
              let tag = String(format:"%03d",tagval) +  "-\(pumpCount)" + "-\( badJsonCount)" + "-\(networkGlitches)"
              if dontcall {
                dontCallTheAI(tag, prompt, global_index)
              } else {
                callTheAI(pumper: self, aiURL!,tag, prompt, global_index,veracity)
              }
            }
          } else {
            print("Warning - empty template #\(idx)")
          }
        }// for
      }
    }
    
    func run() throws {
      defer {
        closeFile(fh:jsonOutHandle,suffix:"]")
        closeFile(fh:promptLogHandle,suffix: "**** end of prompt ****\n")
        print(">Pumper Exiting Normally - Pumped:\(pumpCount)" + " Bad Json:\(badJsonCount)" + " Network Issues:\(networkGlitches)\n")
      }
      print(">Pumper Command Line: \(CommandLine.arguments)")
      print(">Pumper running at \(Date())")
      if veracity { print(">Pumper running in <<<Veracity Mode>>>")}
      guard let url = URL(string:url) else {  print ("bad url"); return  }
      let contents = try String(contentsOf: url)
      let templates = contents.split(separator: split_pattern).map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}
      if  verbose {
        print(">Prompts url: \(url)  (\(contents.count) bytes, \(templates.count) templates)")
        print(">Contacting: \(aiURLString)")
      }
      let  looky = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
      guard looky != nil   else { throw PumperError.noAPIKey }
      apiKey = looky!
      print(">Pumper Using apikey: " + apiKey)
      guard let url = URL(string: aiURLString) else {
        fatalError("Invalid API URL")
      }
      aiURL = url
      try prepOutputChannels()
      pumpItUp(templates) // end pumpcount<=max
      if pumpCount < max  {
        RunLoop.current.run() // suggested by fivestars blog
      }
      print(">Pumper Exiting Normally - Pumped:\(pumpCount)" + " Bad Json: \( badJsonCount)" + " Network Issues: \(networkGlitches)\n")
    }// otherwise we should exit
  }
  
  Pumper.main()
