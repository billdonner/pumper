
//  pumper 0.2.1
//
//  Created by bill donner on 5/7/23.
//
//  Step 1: Pumper executes the script, sending each prompt to the ChatBot and generating a single output file of JSON Challenges which is read by Prepper and, in a later step, by Blender

import Darwin
import Foundation
import q20kshare
import ArgumentParser

let ChatGPTModel = "text-davinci-003"
let ChatGPTURLString = "https://api.openai.com/v1/completions"
 


struct Pumper: ParsableCommand {

  
//  Step 1: Pumper executes the script, sending each prompt to the ChatBot and generating a single output file of JSON Challenges which is read by Prepper and, in a later step, by Blender


  static let configuration = CommandConfiguration(
    abstract: " Step 1: Pumper executes the script, sending each prompt to the ChatBot and generating a single output file of JSON Challenges which is read by Prepper and, in a later step, by Blender.",
    version: "0.2.1",
    subcommands: [],
    defaultSubcommand: nil,
    helpNames: [.long, .short]
  )

  @Argument(help: "Input text script file (Between_0_1.txt)")
  var input: String
  
  @Argument( help:"Output json file (Between_1_2.json)")
  var output: String

  @Option(name: .long, help: "How many prompts to execute")
  var max: Int = 65535
  
  @Option(name: .long, help: "Print dots whilst awaiting AI")
  var dots: Bool = false
  
  @Option(name: .long, help: "Print a lot more")
  var verbose: Bool = false
  
  @Option(name: .long , help: "Generate Unique File Names")
  var unique : Bool = true
  
  @Option(name: .long, help: "Don't call AI")
  var dontcall: Bool = false
  
  @Option(name:.long,help: "The pattern to use to split the file")
  var split_pattern: String = "***"
  
  @Option(name:.long,help: "The pattern to use to indicate a comments line")
  var comments_pattern: String = "///"


    func run() throws {
      print(">Pumper Command Line: \(CommandLine.arguments)")
      print(">Pumper is STEP1 running at \(Date())")
      
 
      let apiKey = try getAPIKey()
      print(">Pumper Using apikey: " + apiKey)
      guard let apiurl = URL(string: ChatGPTURLString) else {
        fatalError("Invalid API URL")
      }
      guard let outURL = URL(string:output) else {
        fatalError("Invalid Output URL")
      }
      let ctx = ChatContext(max: max, apiKey: apiKey, apiURL: apiurl, outURL: outURL, model:ChatGPTModel, verbose:verbose, dots:dots,dontcall:dontcall,comments_pattern:comments_pattern,split_pattern:split_pattern, style:.promptor)
 
      guard let url = URL(string:input) else {  print ("bad url"); return  }
      let contents = try String(contentsOf: url)
      let templates = contents.split(separator: split_pattern)
                   .map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}
      if  verbose {
        print(">Prompts url: \(url)  (\(contents.count) bytes, \(templates.count) templates)")
        print(">Contacting: \(ChatGPTURLString)")
      }
      
      let jsonOutHandle = try prepOutputChannels(ctx:ctx)
      do {
        
        if let jsonOutHandle = jsonOutHandle {
          try pumpItUp(ctx:ctx,templates:templates, jsonOut: jsonOutHandle)
        }
      }
      catch {
        if error as? PumpingErrors == PumpingErrors.reachedMaxLimit {
          print("\n>Pumper reached max limit of \(ctx.max) prompts sent to the AI")
        }
        else {
          print ("Unknown error: \(error)")
        }
      }
      
      if ctx.pumpCount < ctx.max  {
        RunLoop.current.run() // suggested by fivestars blog
      }
      print(">Pumper Exiting Normally - Pumped:\(ctx.pumpCount)" + " Bad Json: \( ctx.badJsonCount)" + " Network Issues: \(ctx.networkGlitches)\n")
      
    }// otherwise we should exit
  }
  
  Pumper.main()
