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
    private var debug: Bool
    
    init (chatmodel: ChatModel, debug: Bool = false) {
        self.debug = debug
        _chatmodel = StateObject(wrappedValue: chatmodel)
    }
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        
        VStack {
            HStack(spacing: 14) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "arrow.left").font(.title).foregroundColor(colorScheme == .dark ? .white : .black)
                }
                Button {
                    isPopoverPresented = true
                } label: {
                    HStack {
                        Image(systemName: "person")
                            .font(.title)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding()
                        Text("Steve Jobs").fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Spacer()
                        Text(" 📖 " + String(chatmodel.code.count))
                            .fontWeight(.bold)
                            .padding()
                            .foregroundColor(chatmodel.code.count <= 0 ? .red : .black)
                    }
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .popover(isPresented: $isPopoverPresented, arrowEdge: .top) {
                    PopoverContent()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    LazyVStack(spacing: 5) {
                        ForEach(debug ? sampleMessages.indices : chatmodel.messagesDec.indices, id: \.self) { index in
                            let message = debug ? sampleMessages[index] : chatmodel.messagesDec[index]
                            if debug {
                                BubbleView(text: message.text, isFromCurrentUser: message.sender == "steve")
                            } else {
                                BubbleView(text: message.text, isFromCurrentUser: message.sender == UserManager.shared.currentUser!.uid)
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
            }.padding([.bottom, .trailing, .leading])
            
            HStack {
                TextField("Message", text: $plain_in)
                    .autocapitalization(.none)
                    .padding(11)
                    .background(colorScheme == .dark ? .black : .white)
                    .cornerRadius(17)
                Button {
                    chatmodel.enc(plain: plain_in.lowercased())
                } label: {
                    HStack(spacing: -2) {
                        Image(systemName: "lock.fill")
                        Image(systemName: "arrow.up.circle")
                    }
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 17)
                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.title)
                }
                .disabled(chatmodel.code.count <= 0)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
    }
}

struct BubbleView: View {
    var text: String
    var isFromCurrentUser: Bool
    var maxWidthFactor: CGFloat = 0.8
    var cornerRadius: CGFloat = 17
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
                Text(text)
                    .padding(10)
                    .background(.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
//                    .background(
//                        RoundedRectangle(cornerRadius: cornerRadius)
//                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 5)
//                    )
//                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(maxWidth: UIScreen.main.bounds.width * maxWidthFactor, alignment: .trailing)
                    
            } else {
                Text(text)
                    .padding(10)
                    .background(Color.gray.opacity(0.4))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .cornerRadius(cornerRadius)
                    .frame(maxWidth: UIScreen.main.bounds.width * maxWidthFactor, alignment: .leading)
                Spacer()
            }
        }
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

let sampleMessages = [
    MessageDec(id: "123", date: Date(), text: "hi there mate hows it going wondering if you want to go to the park, alright, that automatically looks fine? great stuff", sender: "bob"),
    MessageDec(id: "123", date: Date(), text: "hi there", sender: "bob"),
    MessageDec(id: "123", date: Date(), text: "hi there mate hows it going wondering if you want to go to the park, alright, that automatically looks fine? great stuff", sender: "steve"),
    MessageDec(id: "123", date: Date(), text: "h", sender: "steve")
]

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(chatmodel: ChatModel(chat: Chat(id: "uHzegTVQWDePh8niEjnX", members: ["bob", "alice"]), otherUID: "hi"), debug: true)
    }
}
