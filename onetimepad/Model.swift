//
//  Model.swift
//  onetimepad
//
//  Created by Samuel McHale on 06/07/2023.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift




class ChatsStore {
    static let shared = ChatsStore()
    struct EncodedChat: Codable, Identifiable, Equatable, Hashable {
        var id: String?
        var latestMessage: String
        var latestSender: String
        var latestTime: Date
        var typing: String
        var members: [String]
        var newMessage: Bool?
    }
    
    func storeChatsDictionary(_ dictionary: [String: Chat]) {
        do {
            let encodedDictionary = dictionary.mapValues { chat -> EncodedChat in
                return EncodedChat(id: chat.id, latestMessage: chat.latestMessage, latestSender: chat.latestSender, latestTime: chat.latestTime, typing: chat.typing, members: chat.members)
            }
            
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(encodedDictionary)
            UserDefaults.standard.set(encodedData, forKey: "LocalChatsDictionary")
        } catch {
            print("Error storing chats dictionary: \(error)")
        }
    }

    func retrieveChatsDictionary() -> [String: Chat]? {
        guard let userData = UserDefaults.standard.data(forKey: "LocalChatsDictionary") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let encodedDictionary = try decoder.decode([String: EncodedChat].self, from: userData)
            
            let decodedDictionary = encodedDictionary.mapValues { encodedChat -> Chat in
                return Chat(id: encodedChat.id, latestMessage: encodedChat.latestMessage, latestSender: encodedChat.latestSender, latestTime: encodedChat.latestTime, typing: encodedChat.typing, members: encodedChat.members)
            }
            
            return decodedDictionary
        } catch {
            print("Error retrieving chats dictionary: \(error)")
            return nil
        }
    }
    
    func updateChatsDictionary(uid: String, chat: Chat) {
        var chatsDictionary = retrieveChatsDictionary() ?? [:]
        chatsDictionary[uid] = chat
    }
}


class Model: ObservableObject {
    private var userManager = UserManager.shared
    private let db = Firestore.firestore()
    private var localChats: [String: Chat] = [:] {
        didSet {
            sortedChats = Array(localChats.values).sorted(by: { $0.latestTime < $1.latestTime })
        }
    }
    private var chats: [Chat] = []
    @Published var sortedChats: [Chat] = []
    
    
    init() {
        localChats = ChatsStore.shared.retrieveChatsDictionary() ?? [:]
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
    
    func generate (n: Int) -> [Int] {
        var codebook: [Int] = []
        for _ in 0..<n {
            codebook.append(Int.random(in: 0...26))
        }
        print(codebook)
        return codebook
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
                let _ = try db.collection("chats").addDocument(from: Chat(latestMessage: "", latestSender: "", latestTime: Date(), typing: "", members: [sc.id, user.uid]))
                let chatData = ChatData(name: sc.id, codebook: sc.codebook, messages: [])
                ChatStore.shared.storeChat(uid: sc.id, chatData: chatData)
            } catch {
                print(error)
            }
        } catch {
            print("Failed to handle recieved codebook: \(error)")
        }
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
                    guard let chatId = chat.id else { return nil}
                    if self.localChats[chatId] == nil {
                        self.localChats[chatId] = chat
                        ChatsStore.shared.storeChatsDictionary(self.localChats)
                    } else {
                        let new = self.localChats[chatId]!.latestTime != chat.latestTime
                        self.localChats[chatId]! = chat
                        self.localChats[chatId]!.newMessage = new
                    }
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
                            let chatData = ChatData(name: sc.id, codebook: sc.codebook, messages: [])
                            ChatStore.shared.storeChat(uid: self.otherUser(chat: chat), chatData: chatData)
                        }
                    }
                }
            }
    }
}
