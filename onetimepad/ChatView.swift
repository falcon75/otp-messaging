//
//  ChatView.swift
//  onetimepad
//
//  Created by Samuel McHale on 23/07/2022.
//

import SwiftUI


struct ChatView: View {
    
    @StateObject var chatmodel: ChatModel
    @State var plain_in: String = ""
    @State var plain_out: String = ""
    @State var codebookExpanded = false
    @State var ciphersExpanded = false
    @State private var isPopoverPresented = false
    @State private var scrollToEnd = false
    
    init (chatmodel: ChatModel) {
        _chatmodel = StateObject(wrappedValue: chatmodel)
    }

    var body: some View {
        
        VStack {
            HStack {
                Button {
                    isPopoverPresented = true
                } label: {
                    Image(systemName: "rectangle.expand.vertical")
                }
                .popover(isPresented: $isPopoverPresented, arrowEdge: .top) {
                    PopoverContent()
                }.padding()

                Spacer()
                
                Button {
//                    chatmodel.generate(n: 100)
                    print("generate")
                } label: {
                    Image(systemName: "plus.circle")
                    Text(" 📖 " + String(chatmodel.code.count))
                        .padding()
                        .foregroundColor(chatmodel.code.count <= 0 ? .red : .black)
                }
            }
            
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    LazyVStack(spacing: 10) {
                        ForEach(chatmodel.messagesDec.indices, id: \.self) { index in
                            let message = chatmodel.messagesDec[index]
                            if message.sender == UserManager.shared.currentUser!.uid {
                                HStack {
                                    Spacer()
                                    Text(message.text)
                                        .padding(10)
                                        .foregroundColor(.black)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            } else {
                                HStack {
                                    Text(message.text)
                                        .padding(10)
                                        .foregroundColor(.black)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .onChange(of: chatmodel.messagesDec) { _ in
                        scrollToEnd = true
                    }
                    .onAppear {
                        scrollToEnd = true
                    }
                    .onReceive(chatmodel.objectWillChange) { _ in
                        if scrollToEnd {
                            DispatchQueue.main.async {
                                withAnimation {
                                    scrollViewProxy.scrollTo(chatmodel.messagesDec.last?.id, anchor: .bottom)
                                }
                                scrollToEnd = false
                            }
                        }
                    }
                }
            }
            
            HStack {
                TextField("Plaintext", text: $plain_in).autocapitalization(.none)
                Button("Encrypt & Send") {
                    chatmodel.enc(plain: plain_in.lowercased())
                }.disabled(chatmodel.code.count <= 0)
            }
        }.padding()
    }
}

struct PopoverContent: View {
    var body: some View {
        VStack {
            HStack {
                Text("📖")
                    .font(.system(size: 53))
                    .padding()
                Text("Codebook")
                    .font(.title)
            }
            
            Spacer()
            Text("Description of how to generate codebook")
            Spacer()
        }
        .padding()
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(chatmodel: ChatModel(chat: Chat(id: "uHzegTVQWDePh8niEjnX", members: ["bob", "alice"]), otherUID: "hi"))
    }
}
