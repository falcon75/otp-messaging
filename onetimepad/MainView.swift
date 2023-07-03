//
//  MainView.swift
//  onetimepad
//
//  Created by Samuel McHale on 03/07/2023.
//

import SwiftUI

struct MainView: View {
    
    struct ShareCodebook: Codable {
        var id: String
        var codebook: [Int]
    }
    
    private func generate (n: Int) -> [Int] {
        var codebook: [Int] = []
        for _ in 0..<n {
            codebook.append(Int.random(in: 0...26))
        }
        return codebook
    }

    private func shareData() {
        
        let sc = ShareCodebook(id: "123", codebook: self.generate(n: 1000))
        
        guard let data = try? JSONEncoder().encode(sc) else {
            print("Failed to encode data.")
            return
        }

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent("Codebook.json")

        do {
            try data.write(to: fileURL)
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        } catch {
            print("Failed to share codebook: \(error)")
        }
    }
    
    private func handleSharedData(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let receivedData = try JSONDecoder().decode(ShareCodebook.self, from: data)
            print(receivedData.codebook)
        } catch {
            print("Failed to handle recieved codebook: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    HStack {
                        Spacer()
                        Text("One Time 🔒").fontWeight(.bold)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        NavigationLink {
                            ShopView()
                        } label: {
                            Image(systemName: "star.circle")
                        }
                        Button(action: shareData) {
                            Image(systemName: "plus")
                        }
                    }
                }
                Spacer()
                NavigationLink("Chat", destination: ChatView())
                Spacer()
            }.padding()
            
        }
        .onOpenURL(perform: { url in
            handleSharedData(url: url)
        })
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
