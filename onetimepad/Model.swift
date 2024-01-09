//
//  Model.swift
//  onetimepad
//
//  Created by Samuel McHale on 06/07/2023.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift


class ChatsStore: ObservableObject {
    static let shared = ChatsStore()
    @Published var localChats: [String: Chat] = [:] {
        didSet {
            sortedChats = Array(localChats.values).sorted(by: { $0.latestTime > $1.latestTime })
        }
    }
    private var chats: [Chat] = []
    @Published var sortedChats: [Chat] = []
    struct EncodedChat: Codable, Identifiable, Equatable, Hashable {
        var id: String?
        var latestSender: String
        var latestTime: Date
        var members: [String]
        var newPad: Bool
        var newMessage: Bool?
        var name: String?
        var padLength: Int?
        var pfpUrl: URL?
        var pfpLocal: String?
        var latestLocalMessage: String?
    }
    
    func storeChatsDictionary() {
        do {
            let encodedDictionary = localChats.mapValues { chat -> EncodedChat in
                return EncodedChat(id: chat.id, latestSender: chat.latestSender, latestTime: chat.latestTime, members: chat.members, newPad: chat.newPad, newMessage: chat.newMessage, name: chat.name, padLength: chat.padLength, pfpUrl: chat.pfpUrl, pfpLocal: chat.pfpLocal, latestLocalMessage: chat.latestLocalMessage)
            }
            
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(encodedDictionary)
            UserDefaults.standard.set(encodedData, forKey: "LocalChatsDictionary")
        } catch {
            print("Error storing chats dictionary: \(error)")
        }
    }

    func retrieveChatsDictionary() {
        guard let userData = UserDefaults.standard.data(forKey: "LocalChatsDictionary") else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let encodedDictionary = try decoder.decode([String: EncodedChat].self, from: userData)
            
            let decodedDictionary = encodedDictionary.mapValues { encodedChat -> Chat in
                return Chat(id: encodedChat.id, latestSender: encodedChat.latestSender, latestTime: encodedChat.latestTime, members: encodedChat.members, newPad: encodedChat.newPad, newMessage: encodedChat.newMessage, name: encodedChat.name, padLength: encodedChat.padLength, pfpUrl: encodedChat.pfpUrl, pfpLocal: encodedChat.pfpLocal, latestLocalMessage: encodedChat.latestLocalMessage)
            }
            localChats = decodedDictionary
        } catch {
            print("Error retrieving chats dictionary: \(error)")
            return
        }
    }
}


class Model: ObservableObject {
    private var chatsStore = ChatsStore.shared
    private var userManager = UserManager.shared
    private let db = Firestore.firestore()
    private var chats: [Chat] = []
    
    init() {
        chatsStore.retrieveChatsDictionary()
        print(chatsStore.localChats)
        attach()
        
        if let token = UserDefaults.standard.string(forKey: "token") {
            db.collection("users").document(userManager.currentUser!.uid).setData(["token": token]) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Token updated successfully")
                }
            }
        }
    }
    
    func deleteChat(uid: String, chatId: String) {
        let chatData = ChatStore.shared.getChat(for: uid)!
        let chatData1 = ChatData(name: chatData.name, codebook: [], messages: chatData.messages) // empty codebook
        ChatStore.shared.storeChat(uid: uid, chatData: chatData1)
        chatsStore.localChats[chatId]!.padLength = 0
        self.chatsStore.storeChatsDictionary()
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
        }
        print("this pront shoudl never happen")
        return ""
    }
    
    func generate(_ numberOfInts: Int) -> [UInt16] {
        var randomBytes = [UInt16](repeating: 0, count: numberOfInts)
        let result = SecRandomCopyBytes(kSecRandomDefault, 2*numberOfInts, &randomBytes)
        if result == errSecSuccess {
            return randomBytes
        } else {
            fatalError("Failed to generate random bytes.")
        }
    }
    
    func handleSharedData(url: URL) {
        guard let user = userManager.currentUser else {
            print("No user")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let sc = try JSONDecoder().decode(ShareCodebook.self, from: data)
            
            do {
                if let chatData = ChatStore.shared.getChat(for: sc.id) {
                    let codebook = chatData.codebook + sc.codebook
                    let chatData1 = ChatData(name: sc.id, codebook: codebook, messages: chatData.messages)
                    let filtered = chatsStore.localChats.values.filter { otherUser(chat: $0) == sc.id }
                    guard let chat = filtered.first else {
                        print("g14")
                        return
                    }
                    if filtered.count != 1 {
                        print("g15")
                        return
                    }
                    ChatStore.shared.storeChat(uid: sc.id, chatData: chatData1)
                    ChatStore.shared.changes.toggle()
                    chatsStore.localChats[chat.id!]!.padLength = codebook.count
                    self.chatsStore.storeChatsDictionary()
                    print("updating newPad")
                    let update = ["newPad": true]
                    self.db.collection("chats").document(chat.id!).updateData(update) { error in
                        if let error = error {
                            print("Error updating document: \(error)")
                        } else {
                            print("set new pad to true")
                        }
                    }
                } else {
                    let _ = try db.collection("chats").addDocument(from: Chat(latestSender: "", latestTime: Date(), members: [sc.id, user.uid], newPad: true))
                    let chatData = ChatData(name: sc.id, codebook: sc.codebook, messages: [])
                    ChatStore.shared.storeChat(uid: sc.id, chatData: chatData)
                    ChatStore.shared.changes.toggle()
                }
            } catch {
                print(error)
                return
            }
        } catch {
            print("Failed to handle recieved codebook: \(error)")
            return
        }
    }

    func attach () {
        guard let user = userManager.currentUser else {
            print("No user")
            return
        }
        
        db.collection("chats")
            .whereField("members", arrayContains: user.uid)
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
                    guard let chatId = chat.id else { return nil}
                    if self.chatsStore.localChats[chatId] == nil { // new chat not in chatsStore, add
                        self.chatsStore.localChats[chatId] = chat
                        self.chatsStore.localChats[chatId]!.name = chatId
                        self.chatsStore.localChats[chatId]!.pfpLocal = pfpList.randomElement()
                        self.chatsStore.storeChatsDictionary()
                    } else { // update chat, excluding local properties
                        let pl = self.chatsStore.localChats[chatId]!.padLength
                        let name = self.chatsStore.localChats[chatId]!.name
                        let new = self.chatsStore.localChats[chatId]!.newMessage
                        let url = self.chatsStore.localChats[chatId]!.pfpUrl
                        let pfpLocal = self.chatsStore.localChats[chatId]!.pfpLocal
                        let llm = self.chatsStore.localChats[chatId]!.latestLocalMessage
                        self.chatsStore.localChats[chatId]! = chat
                        self.chatsStore.localChats[chatId]!.newMessage = new
                        self.chatsStore.localChats[chatId]!.name = name
                        self.chatsStore.localChats[chatId]!.padLength = pl
                        self.chatsStore.localChats[chatId]!.pfpUrl = url
                        self.chatsStore.localChats[chatId]!.pfpLocal = pfpLocal
                        self.chatsStore.localChats[chatId]!.latestLocalMessage = llm
                    }
                    return chat
                }
                
                if let sc = ChatStore.shared.pendingSC {
                    for change in snapshot.documentChanges {
                        guard var chat = try? change.document.data(as: Chat.self) else {
                            print("Error: could not cast to Msg")
                            print(change.document.data())
                            return
                        }
                        if !chat.newPad {
                            return
                        }
                        let uid =  self.otherUser(chat: chat)
                        if change.type == .added {
                            chat.name = uid
                            let chatData = ChatData(name: sc.id, codebook: sc.codebook, messages: [])
                            ChatStore.shared.storeChat(uid: uid, chatData: chatData)
                            ChatStore.shared.changes.toggle()
                            self.chatsStore.localChats[chat.id!]!.padLength = sc.codebook.count
                            self.chatsStore.storeChatsDictionary()
                        } else if change.type == .modified {
                            guard let chatData = ChatStore.shared.getChat(for: uid) else {
                                print("f1")
                                return
                            }
                            let codebook = chatData.codebook + sc.codebook
                            let chatData1 = ChatData(name: chatData.name, codebook: codebook, messages: chatData.messages)
                            ChatStore.shared.storeChat(uid: uid, chatData: chatData1)
                            ChatStore.shared.changes.toggle()
                            self.chatsStore.localChats[chat.id!]!.padLength = codebook.count
                            self.chatsStore.storeChatsDictionary()
                        }
                        let update = ["newPad": false]
                        self.db.collection("chats").document(chat.id!).updateData(update) { error in
                            if let error = error {
                                print("Error updating document: \(error)")
                            } else {
                                print("set new pad to false")
                            }
                        }
                    }
                }
            }
    }
}
