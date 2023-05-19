//generate a macOS swift command line program using spm ArgumentParser that accepts a prompt as command line argument and calls the chatGPT API once per minute, print the response from chatGPT forever
//  pumper
//
//  Created by bill donner on 5/7/23.
//

import Foundation
import ArgumentParser

struct ChatGPTResponse: Codable {
  let choices: [ChatGPTChoice]
}

struct ChatGPTChoice: Codable {
  let text: String
}

func callChapGPT(prompt:String,
                 outputting: @escaping (String)->Void ) throws {
  
  let apiKey = "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"
  let apiURL = "xttps://api.openai.com/v1/engines/davinci/completions"
  
  guard let url = URL(string: apiURL) else {
    fatalError("Invalid API URL")
  }
  
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  request.setValue("Bearer " + apiKey, forHTTPHeaderField: "Authorization")
  
  let parameters: [String: Any] = [
    "prompt": prompt,
    "max_tokens": 3500,
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
      let text = response.choices.first?.text ?? "<<nothin>>"
      outputting(text)
    } catch {
      print ("Failed to decode response ",error)
    }
  }
  task.resume()
}



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
  
  private  func stripComments(source: String, commentStart: String) -> String {
    let lines = source.split(separator: "\n")
    var keeplines:[String] = []
    for line in lines  {
      if !line.hasPrefix(commentStart) {
        keeplines += [String(line)]
      }
    }
    return keeplines.joined(separator: "\n")
  }
  
  func run() throws {
    if let url = URL(string:url) {
      // Get the contents of the file.
      let contents = try String(contentsOf: url)
      print("URL: \(contents.count) bytes")
      // Split the contents of the file into chunks using the pattern.
      let chunks = contents.split(separator: split_pattern)
      for chunk in chunks {
        let prompt = stripComments(source: String(chunk), commentStart: comments_pattern)
        try callChapGPT(prompt : prompt) { response in
          print("response:\(response)")
        }
      }
    }
    else {
      print ("bad url")
    }
  }
}

SplitFile.main()
