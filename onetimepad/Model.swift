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
            sortedChats = Array(localChats.values).sorted(by: { $0.latestTime < $1.latestTime })
        }
    }
    private var chats: [Chat] = []
    @Published var sortedChats: [Chat] = []
    struct EncodedChat: Codable, Identifiable, Equatable, Hashable {
        var id: String?
        var latestMessage: String
        var latestSender: String
        var latestTime: Date
        var typing: String
        var members: [String]
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
                return EncodedChat(id: chat.id, latestMessage: chat.latestMessage, latestSender: chat.latestSender, latestTime: chat.latestTime, typing: chat.typing, members: chat.members, name: chat.name, padLength: chat.padLength, pfpUrl: chat.pfpUrl, pfpLocal: chat.pfpLocal, latestLocalMessage: chat.latestLocalMessage)
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
                return Chat(id: encodedChat.id, latestMessage: encodedChat.latestMessage, latestSender: encodedChat.latestSender, latestTime: encodedChat.latestTime, typing: encodedChat.typing, members: encodedChat.members, name: encodedChat.name, padLength: encodedChat.padLength, pfpUrl: encodedChat.pfpUrl, pfpLocal: encodedChat.pfpLocal, latestLocalMessage: encodedChat.latestLocalMessage)
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
        attach()
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
                let _ = try db.collection("chats").addDocument(from: Chat(latestMessage: "", latestSender: "", latestTime: Date(), typing: "", members: [sc.id, user.uid], pfpLocal: pfpList.randomElement()))
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
                        self.chatsStore.storeChatsDictionary()
                    } else { // update chat, excluding local properties
                        let pl = self.chatsStore.localChats[chatId]!.padLength
                        let name = self.chatsStore.localChats[chatId]!.name
                        let new = self.chatsStore.localChats[chatId]!.latestTime != chat.latestTime
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
                        if change.type == .added {
                            let addedDocument = change.document
                            guard var chat = try? addedDocument.data(as: Chat.self) else {
                                print("Error: could not cast to Msg")
                                print(addedDocument.data())
                                return
                            }
                            let uid =  self.otherUser(chat: chat)
                            chat.name = uid
                            let chatData = ChatData(name: sc.id, codebook: sc.codebook, messages: [])
                            ChatStore.shared.storeChat(uid: uid, chatData: chatData)
                        }
                    }
                }
            }
    }
}
