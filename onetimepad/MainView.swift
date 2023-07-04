//
//  MainView.swift
//  onetimepad
//
//  Created by Samuel McHale on 03/07/2023.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift


struct Chat: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var members: [String]
}

struct ShareCodebook: Codable {
    var id: String
    var codebook: [Int]
}

struct MessageDec: Codable, Equatable, Identifiable {
    var id: String
    var date: Date
    var text: String
    var sender: String
}

struct ChatData: Codable {
    var codebook: [Int]
    var messages: [MessageDec]
}

class ChatStore {
    static let shared = ChatStore()
    var pendingSC: ShareCodebook? = nil
    
    func storeChat(uid: String, chatData: ChatData) {
        let jsonEncoder = JSONEncoder()
        if let encoded = try? jsonEncoder.encode(chatData) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: uid)
        }
    }
    
    func getChat(for uid: String) -> ChatData? {
        let defaults = UserDefaults.standard
        if let encoded = defaults.data(forKey: uid) {
            let jsonDecoder = JSONDecoder()
            if let decoded = try? jsonDecoder.decode(ChatData.self, from: encoded) {
                return decoded
            }
        }
        return nil
    }
}

struct MainView: View {
    @ObservedObject private var userManager = UserManager.shared
    private let db = Firestore.firestore()
    @State var chats: [Chat] = []
    private var debug: Bool
    
    init(debug: Bool = false) {
        self.debug = debug
    }
    
    func otherUser(chat: Chat) -> String {
        guard let user = UserManager.shared.currentUser else {
            print("No User")
            return ""
        }
        
        for mem in chat.members {
            if mem != user.uid {
                return mem
            }
            print("this shouldnt be possible, ensure")
        }
        return ""
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
                    guard let chat = try? document.data(as: Chat.self) else {
                        print("Error: could not cast to Msg")
                        print(document.data())
                        return nil
                    }
                    print(chat)
                    return chat
                }
                
                if let sc = ChatStore.shared.pendingSC {
                    for change in snapshot.documentChanges {
                        if change.type == .added {
                            let addedDocument = change.document
                            guard let chat = try? addedDocument.data(as: Chat.self) else {
                                print("Error: could not cast to Msg")
                                print(addedDocument.data())
                                return
                            }
                            let chatData = ChatData(codebook: sc.codebook, messages: [])
                            ChatStore.shared.storeChat(uid: otherUser(chat: chat), chatData: chatData)
                        }
                    }
                }
            }
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
        let fileURL = temporaryDirectory.appendingPathComponent("Codebook 🔒.json")

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
        ChatStore.shared.pendingSC = sc
    }
    
    private func handleSharedData(url: URL) {
        guard let user = userManager.currentUser else {
            print("No user")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let sc = try JSONDecoder().decode(ShareCodebook.self, from: data)
            
            do {
                let _ = try db.collection("chats").addDocument(from: Chat(members: [sc.id, user.uid]))
                let chatData = ChatData(codebook: sc.codebook, messages: [])
                ChatStore.shared.storeChat(uid: sc.id, chatData: chatData)
            } catch {
                print(error)
            }
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
                        Button {
                            let defaults = UserDefaults.standard
                            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                                defaults.removePersistentDomain(forName: bundleIdentifier)
                            }
                            defaults.synchronize()
                        } label: {
                            Image(systemName: "xmark.bin")
                        }
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
                ForEach(debug ? sampleChats : chats) { chat in
                    if let chatId = chat.id {
                        NavigationLink(chatId, destination: ChatView(chatmodel: ChatModel(chat: chat, otherUID: otherUser(chat: chat))))
                            .frame(width: 350, height: 90)
                            .background(.gray)
                            .foregroundColor(.white)
                            .cornerRadius(20)
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

let sampleChats = [
    Chat(id: "123", members: ["bob", "alice"]),
    Chat(id: "123", members: ["bob", "alice"]),
    Chat(id: "123", members: ["bob", "alice"])
]

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(debug: true)
    }
}
