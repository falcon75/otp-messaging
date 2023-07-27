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
    
    private enum CodingKeys: String, CodingKey {
        case id, latestMessage, latestSender, latestTime, typing, members
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

class ChatModel: ObservableObject {
    private var chatsStore = ChatsStore.shared
    private let db = Firestore.firestore()
    @Published var chat: Chat
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
            ChatStore.shared.storeChat(uid: otherUID, chatData: ChatData(name: name, codebook: code, messages: messagesDec))
        }
    }
    @Published var messageText: String = "" {
        didSet {
            if !messageText.isEmpty {
//                writeTyping(typing: true)
                print("typing set true")
                timer?.invalidate()
                timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(timerExpired), userInfo: nil, repeats: false)
            }
        }
    }
    
    init(chat: Chat, otherUID: String) {
//        print("chat model initialised for: \(otherUID)")
        self.chat = chat
        self.otherUID = otherUID
        let c = ChatStore.shared.getChat(for: otherUID)!
        self.code = c.codebook
        self.messagesDec = c.messages
        self.name = c.name
        attach()
    }
    
    @objc private func timerExpired() {
//        writeTyping(typing: false)
        print("typing set false")
        timer = nil
    }
    
    func writeTyping(typing: Bool) {
        guard let user = UserManager.shared.currentUser else {
            print("No User")
            return
        }
        let update: [String: Any] = ["typing": typing ? user.uid : ""]
        db.collection("chats").document(chat.id!).updateData(update) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("")
            }
        }
    }
    
    var justProcessed: [String] =  []
    
    func attach() {
        db.collection("chats")
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
                    
                    let minCount = min(msg.cipherBytes.count, self.code.count)
                    
                    var resultBytes = [UInt16]()
                    for i in 0..<minCount {
                        resultBytes.append(msg.cipherBytes[i] ^ self.code[i])
                    }
                    
                    self.db.collection("chats").document(self.chat.id!).collection("messages").document(msg.id!).delete() { err in
                        if let err = err {
                            print("Error removing document: \(err)")
                            return
                        } else {
                            print("Document successfully removed!")
                        }
                    }
                    
                    self.code = Array(self.code[msg.cipherBytes.count...])
                    self.messagesDec.append(MessageDec(id: UUID().uuidString, date: msg.date, text: self.bytesToString(resultBytes) ?? "Err:12", sender: msg.sender))
                    self.chatsStore.localChats[self.chat.id!]!.latestLocalMessage = "hi"
                    self.chatsStore.storeChatsDictionary()
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
    
    func generateRandomBytes(count: Int) -> [UInt16] {
        var randomBytes = [UInt16](repeating: 0, count: count)
        let result = SecRandomCopyBytes(kSecRandomDefault, 2*count, &randomBytes)
        if result == errSecSuccess {
            return randomBytes
        } else {
            fatalError("Failed to generate random bytes.")
        }
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
            let update: [String: Any] = ["latestSender": user.uid, "latestMessage": "hi", "latestTime": Date()] // update chat
            db.collection("chats").document(chat.id!).updateData(update) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("New message status updated successfully")
                }
            }
            code = Array(code[msg.cipherBytes.count...])
            messagesDec.append(msgDec)
            chatsStore.localChats[chat.id!]!.latestLocalMessage = plain
            chatsStore.storeChatsDictionary()
            ChatStore.shared.storeChat(uid: otherUID, chatData: ChatData(name: name, codebook: code, messages: messagesDec)) // add message local
        } catch {
            print(error)
        }
    }
}
