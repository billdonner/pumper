//
//  ContentView.swift
//  pumperios
//
//  Created by bill donner on 5/19/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Look at the console")
        }
        .padding()
        .onAppear {
          try! SplitFile().run()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
