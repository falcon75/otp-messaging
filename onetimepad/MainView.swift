//
//  MainView.swift
//  onetimepad
//
//  Created by Samuel McHale on 03/07/2023.
//

import SwiftUI


struct NavLink<Label, Destination>: View where Label: View, Destination: View {
    @StateObject private var chatsStore = ChatsStore.shared
    let destination: Destination
    let label: () -> Label
    var chatId: String
    @State private var isActive = false
    
    var body: some View {
        Button(action: {
            print("Tapped the custom button")
            withAnimation { chatsStore.localChats[chatId]!.newMessage = false }
            chatsStore.storeChatsDictionary()
            isActive = true
        }) {
            label()
        }
        .background(
            NavigationLink("", destination: destination, isActive: $isActive)
                .opacity(0) // Hide the default NavLink link
        )
    }
}

struct MainView: View {
    @StateObject private var chatsStore = ChatsStore.shared
    @StateObject private var chatStore = ChatStore.shared
    @ObservedObject private var userManager = UserManager.shared
    @StateObject private var model = Model()
    
    @State private var isShopActive = false
    @State private var isSettingsActive = false
    @State private var isNavActive = false
    
    @Environment(\.colorScheme) var colorScheme

    private func shareData() {
        guard let user = userManager.currentUser else {
            print("No user")
            return
        }
        
        let sc = ShareCodebook(id: user.uid, codebook: model.generate(1000))
        
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
            return
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
                        print(chatsStore.localChats)
                    } label: {
                        Image(systemName: "sparkles").font(.title).foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .sheet(isPresented: $isShopActive) {
                        ShopView().presentationDetents([.medium])
                    }
                }.padding()
                if (ChatsStore.shared.sortedChats).count > 0 {
                    ScrollView {
                        VStack {
                            Divider()
                            ForEach(ChatsStore.shared.sortedChats) { chat in
                                NavLink(destination: ChatView(chat: chat, uid: model.otherUser(chat: chat)), label: {
                                    HStack(spacing: 10) {
                                        HStack {
                                            if let url = chatsStore.localChats[chat.id!]!.pfpUrl {
                                                if let uiImage = UIImage(contentsOfFile: url.path) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } else {
                                                    Image("pfp2")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                }
                                            } else {
                                                Image(chatsStore.localChats[chat.id!]!.pfpLocal ?? "pfp1")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            }
                                        }
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 17))
                                        VStack(spacing: 5) {
                                            HStack {
                                                Text(chat.name ?? "")
                                                    .fontWeight(.bold)
                                                    .font(.title3)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                Spacer()
                                            }.padding([.leading], 4)
                                            if (chat.newMessage ?? true) || (chat.latestSender == model.otherUser(chat: chat))  {
                                                HStack(spacing: 3) {
                                                    Image(systemName: "lock")
                                                    Text("New Message")
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
                                                    Image(systemName: "lock.open")
                                                    Text(chat.latestLocalMessage ?? "")
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    Spacer()
                                                }
                                                .padding([.top, .bottom, .leading], 5)
                                                .font(.callout)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Text("🕰️ " + formatDateString(date: chat.latestTime))
                                            }
                                            HStack {
                                                if let padLength = chat.padLength {
                                                    Text("📖 " + formatNumber(padLength))
                                                } else {
                                                    Text("📖 ?")
                                                }
                                            }
                                        }.font(.callout)
                                    }
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .background(colorScheme == .dark ? Color.black : Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }, chatId: chat.id!)
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
                        print(chatsStore.localChats)
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

func formatNumber(_ number: Int) -> String {
    let sign = (number < 0) ? "-" : ""
    let num = abs(number)
    
    switch num {
    case 0..<1_000:
        return "\(sign)\(num)"
    case 1_000..<1_000_000:
        let thousands = Double(num) / 1_000.0
        return "\(sign)\(String(format: "%.3g", thousands))k"
    case 1_000_000..<1_000_000_000:
        let millions = Double(num) / 1_000_000.0
        return "\(sign)\(String(format: "%.3g", millions))M"
    case 1_000_000_000..<1_000_000_000_000:
        let billions = Double(num) / 1_000_000_000.0
        return "\(sign)\(String(format: "%.3g", billions))B"
    default:
        let trillions = Double(num) / 1_000_000_000_000.0
        return "\(sign)\(String(format: "%.3g", trillions))T"
    }
}


//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView()
//    }
//}
