//generate a macOS swift command line program using spm ArgumentParser that accepts a prompt as command line argument and calls the chatGPT API once per minute, print the response from chatGPT forever
//  pumper
//
//  Created by bill donner on 5/7/23.
//

// this runs on ios for experimentation only, its a mac program really
import Darwin
import Foundation
import q20kshare



//var tagval:Int = 0
var jsonOutHandle:FileHandle? = nil




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
  var input: String
  
  @Argument( help:"Output file for AI JSON utterances")
  var output: String
  
  @Option(name:.long,help: "The pattern to use to split the file")
  var split_pattern: String = "***"
  
  @Option(name:.long,help: "The pattern to use to indicate a comments line")
  var comments_pattern: String = "///"
  
  @Option(name: .long, help: "How many prompts to execute")
  var max: Int = 65535
  
  @Option(name: .long, help: "Print dots whilst awaiting AI")
  var dots: Bool = false
  
  @Option(name: .long, help: "Print a lot more")
  var verbose: Bool = false
  
  @Option(name: .long , help: "Unique File Names")
  var unique : Bool = true
  
  @Option(name: .long, help: "Don't call AI")
  var dontcall: Bool = false
  
  
  
  
  fileprivate func dontCallTheAI(ctx:ChatContext, prompt: String) {
    print("\n>Deliberately not calling AI for prompt #\(ctx.tag):\n")
    print(prompt)
    //sleep(3)
  }

  fileprivate func closeFile(fh:FileHandle?,suffix:String? = nil) {
    if let fileHandle = fh , let suf = suffix {
      fileHandle.write(suf.data(using: .utf8)!)
      try! fileHandle.close()
    }
  }
  
  public func pumpItUp(ctx:ChatContext, templates: [String],veracity:Bool) throws {
    
   func prepOutputChannels(veracity:Bool) throws {
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
      jsonOutHandle = try prep(x,initial:"[")
    }
    
    
    try prepOutputChannels(veracity:veracity)
    while ctx.pumpCount<=ctx.max {
      // keep doing until we hit user defined limit
        for (idx,t) in templates.enumerated() {
          guard ctx.pumpCount < ctx.max else { break }
          let prompt0 = stripComments(source: String(t), commentStart: comments_pattern)
          if t.count > 0 {
            let prompt = standardSubstitutions(source:prompt0,stats:ctx)
       
            if prompt.count > 0 {
              ctx.global_index += 1
              ctx.tag = String(format:"%03d",ctx.global_index) +  "-\(ctx.pumpCount)" + "-\( ctx.badJsonCount)" + "-\(ctx.networkGlitches)"
              if ctx.dontcall {
                dontCallTheAI(ctx:ctx, prompt: prompt)
              } else {
                callTheAI(ctx:ctx,   prompt, veracity)
              }
            }
          } else {
            print("Warning - empty template #\(idx)")
          }
        }// for
      }
    }
    
    func run() throws {
      print(">Pumper Command Line: \(CommandLine.arguments)")
      print(">Pumper running at \(Date())")
      
      let  looky = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
      guard let looky=looky  else { throw PumperError.noAPIKey }
    
      print(">Pumper Using apikey: " + looky)
      guard let url = URL(string: aiURLString) else {
        fatalError("Invalid API URL")
      }
      let ctx = ChatContext(apiKey: looky, apiURL: url, model:ChatGPTModel, verbose:verbose, dots:dots,dontcall:dontcall)
      
      defer {
        closeFile(fh:jsonOutHandle,suffix:"]")
        print(">Pumper Exiting Normally - Pumped:\(ctx.pumpCount)" + " Bad Json:\(ctx.badJsonCount)" + " Network Issues:\(ctx.networkGlitches)\n")
      }
      
      
   
      guard let url = URL(string:input) else {  print ("bad url"); return  }
      let contents = try String(contentsOf: url)
      let templates = contents.split(separator: split_pattern)
                   .map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}
      if  verbose {
        print(">Prompts url: \(url)  (\(contents.count) bytes, \(templates.count) templates)")
        print(">Contacting: \(aiURLString)")
      }
    
      ctx.apiURL = url
      try pumpItUp(ctx:ctx,templates:templates,veracity:true ) // end pumpcount<=max
      if ctx.pumpCount < ctx.max  {
        RunLoop.current.run() // suggested by fivestars blog
      }
      print(">Pumper Exiting Normally - Pumped:\(ctx.pumpCount)" + " Bad Json: \( ctx.badJsonCount)" + " Network Issues: \(ctx.networkGlitches)\n")
    }// otherwise we should exit
  }
  
  Pumper.main()
