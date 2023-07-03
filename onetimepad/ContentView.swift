//
//  ContentView.swift
//  onetimepad
//
//  Created by Samuel McHale on 23/07/2022.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var model: Model = Model()
    
    @State var plain_in: String = ""
    @State var plain_out: String = ""
    @State var codebookExpanded = false
    @State var ciphersExpanded = false
    
    struct MyDataStructure: Codable {
        var id: String
        var numbers: [Int]
    }
    
    let dataToShare = MyDataStructure(id: "123", numbers: [1, 2, 3]) // Replace with your own data structure

    func shareData() {
        guard let data = try? JSONEncoder().encode(dataToShare) else {
            print("Failed to encode data.")
            return
        }

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent("sharedData.json")

        do {
            try data.write(to: fileURL)

            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
        } catch {
            print("Failed to write data to file: \(error)")
        }
    }
    
    private func handleSharedData(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let receivedData = try JSONDecoder().decode(MyDataStructure.self, from: data)
            print(receivedData)
        } catch {
            print("Failed to handle shared data: \(error)")
        }
    }
    
    var body: some View {
        
        VStack {
            Spacer()
            
            Text("Codebook 📖").bold()
            VStack {
                HStack {
                    Text(String(model.code.count) + " available / " + String(model.enc_p) + " used")
                    Spacer()
                    Button("Generate") { model.generate(n: 100) }
                    Button {
                        withAnimation { codebookExpanded.toggle() }
                    } label: {
                        Image(systemName: "rectangle.expand.vertical")
                    }
                    
                }.padding()
                
                if codebookExpanded {
                    ScrollView {
                        Text(model.code.description).foregroundColor(.gray)
                        
                    }.frame(height: 200)
                }
            }
            .padding()
            .background(Color(red: 240/255, green: 240/255, blue: 250/255))
            .cornerRadius(10)
            
            Spacer()
            Text("One Time Pad Encryption 🕵🏻‍♂️").bold()
            VStack {
                HStack {
                    TextField("Plaintext", text: $plain_in).autocapitalization(.none)
                    Button("Encrypt & Send") {
                        model.enc(plain: plain_in.lowercased())
                    }.disabled(model.code.count < model.enc_p)
                }.padding()
                HStack {
                    Text(model.error ? "🚩 not enough characters available!" : "")
                    Spacer()
                }
                HStack {
                    Text("Ciphertexts")
                    Spacer()
                    Button {
                        withAnimation { ciphersExpanded.toggle() }
                    } label: {
                        Image(systemName: "rectangle.expand.vertical")
                    }
                }.padding()
                
                if ciphersExpanded {
                    ScrollView {
                        Text(Array(model.messages[model.dec_ind...]).compactMap{$0.text}.description)
                    }
                    .frame(height: 150)
                    .foregroundColor(.gray)
                }
                
                HStack {
                    Button("Decrypt ⬇️") {
                        plain_out = model.dec()
                    }.disabled(model.messages.count <= model.dec_ind)
                    Text("Plaintext: ")
                    Text(plain_out)
                    Spacer()
                }.padding()
            }
            .padding()
            .background(Color(red: 240/255, green: 240/255, blue: 250/255))
            .cornerRadius(10)
    
            Spacer()
            
            Button(action: shareData) {
                Text("Share Data")
            }

        }.padding()
        .onOpenURL(perform: { url in
            handleSharedData(url: url)
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
