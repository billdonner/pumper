//generate a macOS swift command line program using spm ArgumentParser that accepts a prompt as command line argument and calls the chatGPT API once per minute, print the response from chatGPT forever
//  pumper
//
//  Created by bill donner on 5/7/23.
//

import Foundation


struct ChatGPTResponse: Codable {
  let choices: [ChatGPTChoice]
}

struct ChatGPTChoice: Codable {
  let text: String
}

func callChapGPT(prompt:String,
                 outputting: @escaping (String)->Void ,wait:Bool = false ) throws {
  
  let apiKey = "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"
  let apiURL = "https://api.openai.com/v1/completions"
  
  guard let url = URL(string: apiURL) else {
    fatalError("Invalid API URL")
  }
  
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  request.setValue("Bearer " + apiKey, forHTTPHeaderField: "Authorization")
  
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
  print("Prompt: \(prompt) \n\nawaiting response...\n\n")
  let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
    guard let data = data, error == nil else {
      print(error?.localizedDescription ?? "Unknown error")
      return
    }
    do {
       let response = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
       respo  = response.choices.first?.text ?? "<<nothin>>"
      
      //let respo = String(decoding:data,as:UTF8.self)
       outputting(respo)
    }  catch {
       print ("Failed to decode response ",error,respo)
    }
  }
  task.resume()
  // linger here if asked to wait
  if wait {
    while true   {
      sleep(1)
      if respo != "" { break }
    }
  }
}
#if os(iOS)

struct SplitFile {
  
  var url: String = "https://billdonner.com/fs/gd/pumper-data.txt"
  
  var split_pattern = "***"
  
  var comments_pattern = "///"
  
}
#else

import ArgumentParser

struct SplitFile: ParsableCommand {
  
  static let configuration = CommandConfiguration(
    abstract: "Split up a file of ChatGPT prompts and send them to ChatGPT.",
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
  
}
  
#endif
extension SplitFile {
  func run() throws {
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
      // Get the contents of the file.
      let contents = try String(contentsOf: url)
      print("URL: \(contents.count) bytes")
      // Split the contents of the file into chunks using the pattern.
      let chunks = contents.split(separator: split_pattern)
      for chunk in chunks {
        let prompt = stripComments(source: String(chunk), commentStart: comments_pattern)
        if prompt.count > 0 {
          try callChapGPT(prompt : prompt,outputting:  { response in
            print("response:\(response)")
          }, wait:true)
        }
      }
    }
    else {
      print ("bad url")
    }
    sleep(120)
  }
}
#if os(iOS)
try SplitFile().run()
#else
SplitFile.main()
#endif
