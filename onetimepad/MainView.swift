//
//  MainView.swift
//  onetimepad
//
//  Created by Samuel McHale on 03/07/2023.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift


struct MainView: View {
    @ObservedObject private var userManager = UserManager.shared
    private let db = Firestore.firestore()
    @State var chats: [Chat] = []
    
    struct Chat: Codable, Identifiable, Equatable, Hashable {
        @DocumentID var id: String?
        var members: [String]
    }
    
    func attach () {
        guard let user = userManager.currentUser else {
            print("No user")
            return
        }
        
        db.collection("chats")
            .whereField("members", arrayContains: user.uid)
//            .order(by: "date", descending: false)
            .addSnapshotListener { (snapshot, err) in
                
                if let err = err {
                    print("Error: \(err)")
                }
                    
                guard let snapshot = snapshot else {
                    print("Snapshot nil")
                    return
                }
                    
                self.chats = snapshot.documents.compactMap { document in
                    guard let msg = try? document.data(as: Chat.self) else {
                        print("Error: could not cast to Msg")
                        print(document.data())
                        return nil
                    }
                    return msg
                }
            }
    }
    
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
        guard let user = userManager.currentUser else {
            print("No user")
            return
        }
        
        let sc = ShareCodebook(id: user.uid, codebook: self.generate(n: 1000))
        
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
                        Button {
                            shareData()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                Spacer()
                ForEach(chats) { chat in
                    if let chatId = chat.id {
                        NavigationLink(chatId, destination: ChatView(chatmodel: ChatModel(chatId: chatId)))
                        Spacer()
                    }
                }
            }.padding()
            
        }
        .onOpenURL(perform: { url in
            handleSharedData(url: url)
        })
        .onChange(of: userManager.currentUser) { newUser in
            attach()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
