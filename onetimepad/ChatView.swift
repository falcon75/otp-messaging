//
//  ChatView.swift
//  onetimepad
//
//  Created by Samuel McHale on 23/07/2022.
//

import SwiftUI
import UIKit
import Photos


struct ChatView: View {
    @ObservedObject private var chatsStore = ChatsStore.shared
    @StateObject var chatmodel: ChatModel
    @State private var isPopoverPresented = false
    private var debug: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    init (chatmodel: ChatModel, debug: Bool = false) {
        self.debug = debug
        _chatmodel = StateObject(wrappedValue: chatmodel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "arrow.left").font(.title).foregroundColor(colorScheme == .dark ? .white : .black).padding()
                }
                Button {
                    isPopoverPresented = true
                } label: {
                    HStack {
                        HStack {
                            if let url = chatsStore.localChats[chatmodel.chat.id!]!.pfpUrl {
                                if let uiImage = UIImage(contentsOfFile: url.path) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Image("samplePfp")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                }
                            } else {
                                Image("samplePfp")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(5)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(chatsStore.localChats[chatmodel.chat.id!]!.name ?? "").fontWeight(.bold).lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Text("📖 " + formatNumber(chatmodel.code.count))
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
                    .padding([.top, .bottom, .trailing])
                }
                .sheet(isPresented: $isPopoverPresented) {
                    ChatOptionsView(chatModel: chatmodel, name: chatsStore.localChats[chatmodel.chat.id!]!.name ?? "").presentationDetents([.medium])
                }
            }
            .background(Color.gray.opacity(0.1))
            ScrollView(showsIndicators: false) {
                ScrollViewReader { scrollViewProxy in
                    LazyVStack(spacing: 1) {
                        Spacer()
                        ForEach(debug ? sampleMessages.indices : chatmodel.messagesDec.indices, id: \.self) { index in
                            let message = debug ? sampleMessages[index] : chatmodel.messagesDec[index]
                            if debug {
                                BubbleView(text: message.text, time: message.date, isFromCurrentUser: message.sender == "steve")
                            } else {
                                BubbleView(text: message.text, time: message.date, isFromCurrentUser: message.sender == UserManager.shared.currentUser!.uid)
                            }
                        }
                        Spacer()
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
                    chatmodel.send(plain: chatmodel.messageText.lowercased())
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
    var time: Date
    var isFromCurrentUser: Bool
    var maxWidthFactor: CGFloat = 0.75
    var cornerRadius: CGFloat = 17
    @State var showTime = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                if showTime {
                    Text(formatDateString(date: time))
                        .foregroundColor(.gray)
                        .font(.callout)
                        .padding(10)
                }
                Spacer()
                Text(text)
                    .padding(10)
                    .background(.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .frame(maxWidth: UIScreen.main.bounds.width * maxWidthFactor, alignment: .trailing)
                    
            } else {
                Text(text)
                    .padding(10)
                    .background(Color.gray.opacity(0.4))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .cornerRadius(cornerRadius)
                    .frame(maxWidth: UIScreen.main.bounds.width * maxWidthFactor, alignment: .leading)
                Spacer()
                if showTime {
                    Text(formatDateString(date: time))
                        .foregroundColor(.gray)
                        .font(.callout)
                        .padding(10)
                }
            }
        }
        .onTapGesture {
            withAnimation { showTime.toggle() }
        }
    }
}

struct ChatOptionsView: View {
    @ObservedObject private var chatsStore = ChatsStore.shared
    @State private var selectedImageURL: URL?
    @State var chatModel: ChatModel
    @State var name: String
    @State var showImagePicker: Bool = false
    
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
            Button {
                showImagePicker = true
            } label: {
                HStack {
                    if let url = chatsStore.localChats[chatModel.chat.id!]!.pfpUrl {
                        if let uiImage = UIImage(contentsOfFile: url.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image("samplePfp")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    } else {
                        Image("samplePfp")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 17))
            }
            HStack {
                TextField("Name", text: $name)
                    .truncationMode(.tail)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
//                clearButton
//                    .frame(width: 20)
                    
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 17))
            Spacer()
        }
        .padding()
        .onChange(of: name) { newValue in
            chatsStore.localChats[chatModel.chat.id!]!.name = name
            chatsStore.storeChatsDictionary()
        }
        .sheet(isPresented: $showImagePicker) {
            ImageSelectionView(selectedImageURL: $selectedImageURL)
        }
        .onChange(of: selectedImageURL) { newValue in
            chatsStore.localChats[chatModel.chat.id!]!.pfpUrl = selectedImageURL
            chatsStore.storeChatsDictionary()
        }
    }
    
//    private var clearButton: some View {
//        Button(action: {
//            self.name = ""
//        }) {
//            HStack {
//                Spacer()
//                Image(systemName: "xmark.circle.fill")
//                    .foregroundColor(.secondary)
//                    .padding(.trailing, 8)
//            }
//        }
//    }
}

let sampleMessages = [
    MessageDec(id: "123", date: Date(), text: "hi there mate hows it going wondering if you want to go to the park, alright, that automatically looks fine? great stuff", sender: "bob"),
    MessageDec(id: "123", date: Date(), text: "hi there", sender: "bob"),
    MessageDec(id: "123", date: Date(), text: "hi there mate hows it going wondering if you want to go to the park, alright, that automatically looks fine? great stuff", sender: "steve"),
    MessageDec(id: "123", date: Date(), text: "h", sender: "steve")
]

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(chatmodel: ChatModel(chat: Chat(id: "uHzegTVQWDePh8niEjnX", latestMessage: "hi", latestSender: "alice", latestTime: Date(), typing: "alice", members: ["bob", "alice"], name: "Steve Jobs"), otherUID: "bob"), debug: true)
    }
}

struct ImageSelectionView: UIViewControllerRepresentable {
    @Binding var selectedImageURL: URL?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = context.coordinator
        return imagePickerController
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No need for update implementation
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImageSelectionView

        init(parent: ImageSelectionView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                if let imageURL = saveImageToDocumentDirectory(image: image) {
                    parent.selectedImageURL = imageURL
                }
            }

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func saveImageToDocumentDirectory(image: UIImage) -> URL? {
            guard let data = image.jpegData(compressionQuality: 1.0) else {
                return nil
            }

            let uniqueIdentifier = UUID().uuidString
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fileURL = documentsDirectory?.appendingPathComponent("\(uniqueIdentifier).jpg")
            do {
                try data.write(to: fileURL!)
                return fileURL
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
    }
}
