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
    
    var body: some View {
        
        VStack {
            
            Text("Codebook 📖").bold()
            
            VStack {
                
                
                HStack {
        
                    Text(String(model.code.count) + " available / " + String(model.enc_p) + " used")
                    Spacer()
                    Button("Generate") { model.generate(n: 100) }
                    
                }.padding()
                
                ScrollView {
                    
                    Text(model.code.description).foregroundColor(.gray)
                    
                }.frame(height: 200)
                
            }
            .padding()
            .background(Color(red: 240/255, green: 240/255, blue: 250/255))
            .cornerRadius(10)
            
            Spacer()
            
            Text("One Time Pad Encryption 🕵🏻‍♂️").bold()
            
            VStack {
                
                HStack {
                    
                    TextField("Plaintext", text: $plain_in).autocapitalization(.none)
                    
                    Button("Encrypt") {
                        model.enc(plain: plain_in.lowercased())
                    }.disabled(model.code.count < model.enc_p)
                    
                }
                
                HStack {
                    Text(model.error ? "🚩 not enough characters available!" : "")
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    
                    Text("Ciphertexts")
                    Spacer()
                    
                }
                
                ScrollView {
                    Text(model.ciphertexts.description)
                }
                .frame(height: 150)
                .foregroundColor(.gray)
                
                HStack {
                    
                    Button("Decrypt ⬇️") {
                        plain_out = model.dec()
                    }.disabled(model.ciphertexts.count <=  0)
                }
                
                Spacer()
                
                HStack {
                    
                    Text("Plaintext: ")
                    Text(plain_out)
                    Spacer()
                    
                }
                
                Spacer()
                
            }
            .padding()
            .background(Color(red: 240/255, green: 240/255, blue: 250/255))
            .cornerRadius(10)
            
        }.padding()
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
