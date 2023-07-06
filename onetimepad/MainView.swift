//
//  MainView.swift
//  onetimepad
//
//  Created by Samuel McHale on 03/07/2023.
//

import SwiftUI


struct MainView: View {
    @ObservedObject private var userManager = UserManager.shared
    @StateObject private var model = Model()
    private var debug: Bool
    @State private var isShowingDetail = false
    @State private var isShopActive = false
    @State private var isSettingsActive = false
    
    @Environment(\.colorScheme) var colorScheme
    
    init(debug: Bool = false) {
        self.debug = debug
    }

    private func shareData() {
        guard let user = userManager.currentUser else {
            print("No user")
            return
        }
        
        let sc = ShareCodebook(id: user.uid, codebook: model.generate(n: 1000))
        
        guard let data = try? JSONEncoder().encode(sc) else {
            print("Failed to encode data.")
            return
        }

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent("Secret Pad 🔒.json")

        do {
            try data.write(to: fileURL)
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        } catch {
            print("Failed to share codebook: \(error)")
        }
        ChatStore.shared.pendingSC = sc
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("One Time Pad 🔒").font(.largeTitle).fontWeight(.bold)
                    Spacer()
                    Button {
                        isShopActive = true
                    } label: {
                        Image(systemName: "sparkles").font(.title).foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .sheet(isPresented: $isShopActive) {
                        ShopView().presentationDetents([.medium])
                    }
                }.padding()
                if (debug ? sampleChats : model.sortedChats).count > 0 {
                    ScrollView {
                        VStack {
                            Divider()
                            ForEach(debug ? sampleChats : model.sortedChats) { chat in
                                Button(action: {
                                    isShowingDetail = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image("samplePfp")
                                            .resizable()
                                            .aspectRatio(1, contentMode: .fit)
                                            .frame(width: 70, height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 17))
                                        VStack(spacing: 5) {
                                            HStack {
                                                Text("Steve Jobs").fontWeight(.bold).font(.title3)
                                                Spacer()
                                            }
                                            if chat.newMessage ?? false {
                                                HStack(spacing: 3) {
                                                    Image(systemName: "lock")
                                                    Text(chat.latestMessage)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    Spacer()
                                                }
                                                .padding(5)
                                                .font(.callout)
                                                .foregroundColor(.white)
                                                .background(.blue)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            } else {
                                                HStack(spacing: 3) {
                                                    Text(chat.latestMessage)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    Spacer()
                                                }
                                                .padding(5)
                                                .font(.callout)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 5) {
                                            HStack {
                                                Text("🕰️ " + formatDateString(date: chat.latestTime))
                                            }
                                            HStack {
                                                Text("📖 1000")
                                            }
                                        }.font(.callout)
                                        
                                    }
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .background(colorScheme == .dark ? Color.black : Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .background(
                                    NavigationLink(destination: ChatView(isShowingDetail: $isShowingDetail, chatmodel: ChatModel(chat: chat, otherUID: model.otherUser(chat: chat))), isActive: $isShowingDetail) {
                                        EmptyView()
                                    }
                                )
                                Spacer()
                                Divider()
                            }
                        }.padding()
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("No Chats").foregroundColor(.gray.opacity(0.8))
                        Spacer()
                    }
                }
                HStack(spacing: 5) {
                    Button {
                        shareData()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "plus").font(.title)
                            Spacer()
                        }
                        .padding()
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .background(colorScheme == .dark ? .white : .black)
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                    }
                    Button {
                        isSettingsActive = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(8)
                    }
                    .sheet(isPresented: $isSettingsActive) {
                        SettingsView().presentationDetents([.medium])
                    }
                }
                .padding()
            }
        }
        .onOpenURL(perform: { url in
            model.handleSharedData(url: url)
        })
        .onChange(of: userManager.currentUser) { newUser in
            model.attach()
        }
    }
}

struct SettingsView: View {
    @State var settingPasscode: Bool = false
    @State var settingShareInfo: Bool = true
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    let defaults = UserDefaults.standard
                    if let bundleIdentifier = Bundle.main.bundleIdentifier {
                        defaults.removePersistentDomain(forName: bundleIdentifier)
                    }
                    defaults.synchronize()
                } label: {
                    Image(systemName: "xmark.bin").font(.title).foregroundColor(colorScheme == .dark ? .white : .black)
                }
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "arrow.down").font(.title).foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            Spacer()
            Divider()
            HStack {
                Toggle("Lock app with passcode / FaceId", isOn: $settingPasscode)
                    .padding(.vertical, 8)
            }
            Divider()
            HStack {
                Toggle("Show guide when sharing pad", isOn: $settingShareInfo)
                    .padding(.vertical, 8)
            }
            Divider()
            Spacer()
        }.padding()
    }
}

func formatDateString(date: Date) -> String {
    let dateFormatter = DateFormatter()
    let currentDate = Date()
    
    if Calendar.current.isDateInToday(date) {
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    } else if Calendar.current.isDate(date, equalTo: currentDate, toGranularity: .month) {
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: date)
    } else if Calendar.current.isDate(date, equalTo: currentDate, toGranularity: .year) {
        dateFormatter.dateFormat = "MMM"
        return dateFormatter.string(from: date)
    } else {
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: date)
    }
}

let sampleChats: [Chat] = [
    Chat(id: "123", latestMessage: "hi", latestSender: "Bob", latestTime: Date(), typing: "Bob", members: ["bob", "alice"]),
    Chat(id: "123", latestMessage: "hi", latestSender: "Bob", latestTime: Date(), typing: "Bob", members: ["bob", "alice"]),
    Chat(id: "123", latestMessage: "hi", latestSender: "Bob", latestTime: Date(), typing: "Bob", members: ["bob", "alice"])
]

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(debug: true)
    }
}
