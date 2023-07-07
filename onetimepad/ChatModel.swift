//
//  ChatModel.swift
//  onetimepad
//
//  Created by Samuel McHale on 23/07/2022.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift


struct Message: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var date: Date
    var text: String
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
    
    private enum CodingKeys: String, CodingKey {
        case id, latestMessage, latestSender, latestTime, typing, members
    }
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
    var name: String
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

class ChatModel: ObservableObject {
    private var chatsStore = ChatsStore.shared
    private let db = Firestore.firestore()
    @Published var chat: Chat
    var otherUID: String
    
    let a_to_n = ["a": 0, "b": 1, "c": 2, "d": 3, "e": 4, "f": 5, "g": 6, "h": 7, "i": 8, "j": 9, "k": 10, "l": 11, "m": 12, "n": 13, "o": 14, "p": 15, "q": 16, "r": 17, "s": 18, "t": 19, "u": 20, "v": 21, "w": 22, "x": 23, "y": 24, "z": 25, " ": 26]
    let n_to_a = [0: "a", 1: "b", 2: "c", 3: "d", 4: "e", 5: "f", 6: "g", 7: "h", 8: "i", 9: "j", 10: "k", 11: "l", 12: "m", 13: "n", 14: "o", 15: "p", 16: "q", 17: "r", 18: "s", 19: "t", 20: "u", 21: "v", 22: "w", 23: "x", 24: "y", 25: "z", 26: " "]
    
    @Published var code: [Int] { // codebook for the conversation
        didSet {
            chatsStore.localChats[chat.id!]!.padLength = code.count
            chatsStore.storeChatsDictionary()
        }
    }
    @Published var error = false // error indicator
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
                writeTyping(typing: true)
                timer?.invalidate()
                timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(timerExpired), userInfo: nil, repeats: false)
            }
        }
    }
    
    init(chat: Chat, otherUID: String) {
        self.chat = chat
        self.otherUID = otherUID
        if let c = ChatStore.shared.getChat(for: otherUID) {
            self.code = c.codebook
            self.messagesDec = c.messages
            self.name = c.name
        } else {
            self.code = []
        }
        attach()
    }
    
    @objc private func timerExpired() {
        writeTyping(typing: false)
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
                print("New message status updated successfully")
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
                    
                    var pointer = 0
                    var plaintext = ""
                    let cipher = msg.text
                    
                    for i in cipher {
                        let c = String(i)
                        let n = ((self.a_to_n[c] ?? 26) - self.code[pointer] + 27) % 27
                        plaintext += self.n_to_a[n] ?? " "
                        pointer += 1
                    }
                    
                    self.db.collection("chats").document(self.chat.id!).collection("messages").document(msg.id!).delete() { err in
                        if let err = err {
                            print("Error removing document: \(err)")
                            return
                        } else {
                            print("Document successfully removed!")
                        }
                    }
                    
                    self.code = Array(self.code[cipher.count...])
                    self.messagesDec.append(MessageDec(id: UUID().uuidString, date: msg.date, text: plaintext, sender: msg.sender))
                    ChatStore.shared.storeChat(uid: self.otherUID, chatData: ChatData(name: self.name, codebook: self.code, messages: self.messagesDec))
                }
            }
    }
    
    func send(plain: String){
        var pointer = 0
        var cipher = ""
        
        if plain.count > code.count - pointer {
            error = true
            return
        } else {
            error = false
        }
        
        for i in plain {
            let c = String(i)
            let n = ((a_to_n[c] ?? 26) + code[pointer]) % 27
            cipher += n_to_a[n] ?? " "
            pointer += 1
        }
        
        guard let user = UserManager.shared.currentUser else {
            print("No User")
            return
        }
        
        let date = Date()
        let msg = Message(date: date, text: cipher, sender: user.uid)
        let msgDec = MessageDec(id: UUID().uuidString, date: date, text: plain, sender: user.uid)
        
        do {
            let _ = try db.collection("chats").document(chat.id!).collection("messages").addDocument(from: msg) // add message
            let update: [String: Any] = ["latestSender": user.uid, "latestMessage": cipher, "latestTime": Date()] // update chat
            db.collection("chats").document(chat.id!).updateData(update) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("New message status updated successfully")
                }
            }
            code = Array(code[plain.count...])
            messagesDec.append(msgDec)
            ChatStore.shared.storeChat(uid: otherUID, chatData: ChatData(name: name, codebook: code, messages: messagesDec)) // add message local
        } catch {
            print(error)
        }
    }
}
