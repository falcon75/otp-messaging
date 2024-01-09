//
//  GuideView.swift
//  onetimepad
//
//  Created by Samuel McHale on 22/08/2023.
//

import SwiftUI

struct GuideView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var showing: Bool
    var body: some View {
        if showing {
            ZStack() {
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color.black : Color.white)

                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(LinearGradient(gradient:
                        Gradient(colors: [
                            colorScheme == .dark ? .gray.opacity(0.6) : .gray.opacity(0.4), colorScheme == .dark ? .gray.opacity(0.2) : .gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 5)
                VStack(alignment: .leading, spacing: 10) {
                    HStack() {
                        if showing {
                            Text("Guide")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        Button {
                            withAnimation { showing.toggle() }
                        } label: {
                            Text("Hide")
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        }
                    }.padding(5)
                    if showing {
                        Divider()
                            .frame(height: 2)
                            .overlay(colorScheme == .dark ? Color.offWhiteDark : Color.offWhite)
                            .cornerRadius(9999)
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("🕵🏻‍♂️")
                                    .font(.title)
                                Text("Secret Messaging")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Text("One time pad encryption is information theoretically secure, unlike modern internet encryption standards which can be broken by SNDL or Shor's Algorithm.")
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("💬")
                                    .font(.title)
                                Text("Starting a Chat")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            HStack() {
                                Divider()
                                    .frame(width: 3)
                                    .overlay(colorScheme == .dark ? Color.offWhiteDark : Color.offWhite)
                                    .cornerRadius(9999)
                                    .padding(5)
                                VStack(alignment: .leading, spacing: 20) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Text("📖")
                                                .font(.title)
                                            Text("Sharing a Pad")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                        }
                                        Text("One time pad requires sharing a 'pad' of single use keys securely with your friend. Hit the ➕ button to open the share menu with your keys, then AirDrop them to your friend.")
                                    }
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Text("📬")
                                                .font(.title)
                                            Text("Recieving the Pad")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                        }
                                        Text("When your friend recieves the pad, ask them to select 'One Time Pad' from the list of apps. If you are connected to the internet, you should both see a new chat on the main screen.")
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("🔋")
                                    .font(.title)
                                Text("Adding More Chars")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Text("When the keys are used up, repeat the steps in 'starting a chat', the new keys will be added to the existing chat with your friend.")
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("🐛")
                                    .font(.title)
                                Text("Bugs")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Text("If decryption gets out of sync, both members can empty the chat's pad of keys by long pressing on it. New keys can then be shared as described above.")
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("⚠️")
                                    .font(.title)
                                Text("Disclaimer")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Text("Please do not rely on storing important things in your messages. Local storage is not encrypted. This app is new, if you want improvements, let us know in a review.")
                        }
                    }
                }.padding([.leading, .trailing, .top], 18)
                    .padding([.bottom], 20)
            }
        } else {
            HStack {
                Spacer()
                Button {
                    withAnimation { showing.toggle() }
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .padding(5)
        }
    }
}

extension Color {
    static let offWhite1 = Color(red: 240/255, green: 240/255, blue: 240/255)
    static let darkShadow1 = Color(red: 220/255, green: 220/255, blue: 220/255)
    static let lightShadow1 = Color.white
    static let darkGreen1 = Color(red: 41/255, green: 163/255, blue: 61/255)
    static let lightGreen1 = Color(red: 56/255, green: 223/255, blue: 83/255)
    static let borderGradientStart1 = Color(red: 230/255, green: 230/255, blue: 230/255)
    static let borderGradientEnd1 = Color.white
    
    static let base1: Double = 190
    static let borderGradientEnd21 = Color(red: base/255, green: base/255, blue: base/255)
    static let borderGradientStart21 = Color(red: (base + 20)/255, green: (base + 20)/255, blue: (base + 20)/255)
}

struct GuideView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GuideView(showing: true).padding()
            Spacer()
        }
        
    }
}
