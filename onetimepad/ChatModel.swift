//
//  ChatModel.swift
//  onetimepad
//
//  Created by Samuel McHale on 23/07/2022.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import CryptoKit


struct Message: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var date: Date
    var cipherBytes: [UInt16]
    var sender: String
}

struct Chat: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
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
    
    private enum CodingKeys: String, CodingKey {
        case id, latestSender, latestTime, members, newPad
    }
}

struct ShareCodebook: Codable {
    var id: String
    var codebook: [UInt16]
}

struct MessageDec: Codable, Equatable, Identifiable {
    var id: String
    var date: Date
    var text: String
    var sender: String
}

struct ChatData: Codable {
    var name: String
    var codebook: [UInt16]
    var messages: [MessageDec]
}

class ChatStore: ObservableObject {
    static let shared = ChatStore()
    var pendingSC: ShareCodebook? = nil
    @Published var changes: Bool = false
    
    func storeChat(uid: String, chatData: ChatData) {
        print("Stored: \(chatData.codebook.count)")
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

class ChatModel: ObservableObject {
    private var chatsStore = ChatsStore.shared
    private let db = Firestore.firestore()
    var listener: ListenerRegistration?
    @Published var chat: Chat
    @Published var isViewDisplayed = false
    var otherUID: String
    
    @Published var code: [UInt16] { // codebook for the conversation
        didSet {
            chatsStore.localChats[chat.id!]!.padLength = code.count
            chatsStore.storeChatsDictionary()
        }
    }
    @Published var messages: [Message] = []
    @Published var messagesDec: [MessageDec] = []
    private var timer: Timer?
    @Published var name: String = "" {
        didSet {
            print("name change, storing")
            ChatStore.shared.storeChat(uid: otherUID, chatData: ChatData(name: name, codebook: code, messages: messagesDec))
        }
    }
    @Published var messageText: String = ""
    
    init(chat: Chat, otherUID: String) {
        self.chat = chat
        self.otherUID = otherUID
        let c = ChatStore.shared.getChat(for: otherUID)!
        self.code = c.codebook
        self.messagesDec = c.messages
        self.name = c.name
    }
    
    func fetchLocal () {
        let c = ChatStore.shared.getChat(for: self.otherUID)!
        self.code = c.codebook
    }
    
    var justProcessed: [String] =  []
    
    func attach() {
        listener = db.collection("chats")
            .document(chat.id!)
            .collection("messages")
            .order(by: "date", descending: false)
            .addSnapshotListener { (snapshot, err) in
                
                if let err = err {
                    print("Error: \(err)")
                }
                    
                guard let snapshot = snapshot else {
                    print("Snapshot nil")
                    return
                }
                
                print("listener fire in: \(Unmanaged.passUnretained(self).toOpaque())")
                    
                for document in snapshot.documents {
                    guard let msg = try? document.data(as: Message.self) else {
                        print("Error: could not cast to Msg")
                        print(document.data())
                        return
                    }
                    
                    if self.justProcessed.contains(msg.id!) {
                        continue
                    }
                    self.justProcessed.append(msg.id!)
                    
                    guard let user = UserManager.shared.currentUser else {
                        print("No User")
                        return
                    }
                    
                    if msg.sender == user.uid {
                        return
                    }
                    
                    var plain = ""
                    if self.code.count < msg.cipherBytes.count {
                        plain = self.bytesToString(msg.cipherBytes) ?? ""
                    } else {
                        let minCount = min(msg.cipherBytes.count, self.code.count)
                        
                        var resultBytes = [UInt16]()
                        for i in 0..<minCount {
                            resultBytes.append(msg.cipherBytes[i] ^ self.code[i])
                        }
                        
                        // delete chat
                        self.db.collection("chats").document(self.chat.id!).collection("messages").document(msg.id!).delete() { err in
                            if let err = err {
                                print("Error removing document: \(err)")
                                return
                            } else {
                                print("Document successfully removed!")
                            }
                        }
                        
                        // empty sender field
                        let update: [String: Any] = ["latestSender": ""]
                        self.db.collection("chats").document(self.chat.id!).updateData(update) { error in
                            if let error = error {
                                print("Error updating document: \(error)")
                            } else {
                                print("New message status updated successfully")
                            }
                        }
                        plain = self.bytesToString(resultBytes) ?? ""
                        self.code = Array(self.code[msg.cipherBytes.count...])
                    }
                    
                    let newMsg = MessageDec(id: UUID().uuidString, date: msg.date, text: plain, sender: msg.sender)
                    self.messagesDec.append(newMsg)
                    self.chatsStore.localChats[self.chat.id!]!.latestLocalMessage = plain
                    self.chatsStore.localChats[self.chat.id!]!.newMessage = !self.isViewDisplayed
                    self.chatsStore.storeChatsDictionary()
                    print("saving the new codebook state: \(self.code.count) and messages: \(newMsg.text)")
                    ChatStore.shared.storeChat(uid: self.otherUID, chatData: ChatData(name: self.name, codebook: self.code, messages: self.messagesDec))
                }
            }
    }
    
    func stringToBytes(_ input: String) -> [UInt16] {
        return Array(input.utf16)
    }
    
    func bytesToString(_ bytes: [UInt16]) -> String? {
        return String(decoding: bytes, as: UTF16.self)
    }
    
    func send(plain: String){
        print("Sending")
        
        if plain.count > code.count {
            print("Not enough characters")
            return
        }
        
        let plainBytes = stringToBytes(plain)
        let minCount = min(plainBytes.count, code.count)
        
        var cipherBytes = [UInt16]()
        for i in 0..<minCount {
            cipherBytes.append(plainBytes[i] ^ code[i])
        }
        
        guard let user = UserManager.shared.currentUser else {
            print("No User")
            return
        }
        
        let date = Date()
        let msg = Message(date: date, cipherBytes: cipherBytes, sender: user.uid)
        let msgDec = MessageDec(id: UUID().uuidString, date: date, text: plain, sender: user.uid)
        
        do {
            let _ = try db.collection("chats").document(chat.id!).collection("messages").addDocument(from: msg) // add message
            let update: [String: Any] = ["latestSender": user.uid, "latestTime": Date()] // set sender field
            db.collection("chats").document(chat.id!).updateData(update) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("New message status updated successfully")
                }
            }
            code = Array(code[msg.cipherBytes.count...])
            messageText = ""
            messagesDec.append(msgDec)
            chatsStore.localChats[chat.id!]!.latestLocalMessage = plain
            chatsStore.storeChatsDictionary()
            ChatStore.shared.storeChat(uid: otherUID, chatData: ChatData(name: name, codebook: code, messages: messagesDec)) // add message local
        } catch {
            print(error)
        }
    }
}
