//
//  ChatView.swift
//  onetimepad
//
//  Created by Samuel McHale on 23/07/2022.
//

import SwiftUI


struct ChatView: View {
    @StateObject var chatmodel: ChatModel
    @State private var isPopoverPresented = false
    @Binding var isShowingDetail: Bool
    private var debug: Bool
    static var previewBinding: Binding<Bool> = .constant(false)
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    init (isShowingDetail: Binding<Bool>, chatmodel: ChatModel, debug: Bool = false) {
        _isShowingDetail = isShowingDetail
        self.debug = debug
        _chatmodel = StateObject(wrappedValue: chatmodel)
    }
    
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
                        Image("samplePfp")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(5)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(debug ? "Steve Jobs" : chatmodel.name).fontWeight(.bold).lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Text("📖 " + String(chatmodel.code.count))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        Spacer()
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                            .padding()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                }
                .sheet(isPresented: $isPopoverPresented) {
                    ChatOptionsView(chatModel: chatmodel).presentationDetents([.medium])
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            ScrollView(showsIndicators: false) {
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
                        withAnimation { scrollViewProxy.scrollTo(chatmodel.messagesDec.count - 1) }
                    }
                    .onAppear {
                        scrollViewProxy.scrollTo(chatmodel.messagesDec.count - 1)
                    }
                }
            }.padding([.trailing, .leading], 5)
            HStack(spacing: 12) {
                TextField("Message", text: $chatmodel.messageText)
                    .autocapitalization(.none)
                    .padding(12)
                    .background(colorScheme == .dark ? .black : .white)
                    .cornerRadius(17)
                Button {
                    chatmodel.enc(plain: chatmodel.messageText.lowercased())
                    chatmodel.messageText = ""
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
                    .opacity(chatmodel.messageText == "" ? 0.5 : 1.0)
                    .font(.title)
                }
                .disabled(chatmodel.messageText == "")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }.navigationBarHidden(true)
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

struct ChatOptionsView: View {
    @State var chatModel: ChatModel
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "arrow.down").font(.title).foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }.padding()
            Image("samplePfp")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 17))
            HStack {
                TextField("Name", text: $chatModel.name)
                    .truncationMode(.tail)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 17))
            }
        }.padding()
        Spacer()
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
        ChatView(isShowingDetail: ChatView.previewBinding, chatmodel: ChatModel(chat: Chat(id: "uHzegTVQWDePh8niEjnX", latestMessage: "hi", latestTime: Date(), newMessage: true, typing: true, members: ["bob", "alice"]), otherUID: "hi"), debug: true)
    }
}
