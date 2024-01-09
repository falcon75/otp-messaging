//
//  ShopView.swift
//  onetimepad
//
//  Created by Samuel McHale on 03/07/2023.
//

import SwiftUI


struct ShopView: View {
    @State var premium: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Secret Agent Mode 🕵🏻‍♂️")
                    .font(.title)
                    .fontWeight(.bold)
//                Spacer()
//                Button {
//                    presentationMode.wrappedValue.dismiss()
//                } label: {
//                    Image(systemName: "arrow.down").font(.title).foregroundColor(colorScheme == .dark ? .white : .black)
//                        .padding()
//                }
            }
            Text("Hostile powers trying to trace your every move? Scramble as many messages as you need with secret agent mode.")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .padding(0)
            Text("Share unlimited characters for your chats, for as long as this app exists, hopefully forever.")
                .padding(0)
            Button {
                premium.toggle()
            } label : {
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.green)
                            .frame(width: 200, height: 60)
                            .shadow(color: Color.darkShadow, radius: 8, x: 8, y: 8)
                        RoundedRectangle(cornerRadius: 30)
                            .strokeBorder(LinearGradient(gradient: Gradient(colors: [Color.darkGreen, Color.lightGreen]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 5)
                            .frame(width: 200, height: 60)
                        Text(premium ? "Upgraded" : "Upgrade  •  £2")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
            }
            
        }.padding()
        
    }
}



extension Color {
    static let offWhite = Color(red: 240/255, green: 240/255, blue: 240/255)
    static let offWhiteDark = Color(red: 30/255, green: 30/255, blue: 30/255)
    static let darkShadow = Color(red: 220/255, green: 220/255, blue: 220/255)
    static let lightShadow = Color.white
    static let darkGreen = Color(red: 41/255, green: 163/255, blue: 61/255)
    static let lightGreen = Color(red: 56/255, green: 223/255, blue: 83/255)
    static let borderGradientStart = Color(red: 230/255, green: 230/255, blue: 230/255)
    static let borderGradientEnd = Color.white
    static let borderGradientStartDark = Color(red: 50/255, green: 50/255, blue: 50/255)
    static let fadeOutShadowDark = Color(red: 30/255, green: 30/255, blue: 30/255)
    static let borderGradientEndDark = Color.black
    static let base: Double = 190
    static let borderGradientEnd2 = Color(red: base/255, green: base/255, blue: base/255)
    static let borderGradientStart2 = Color(red: (base + 20)/255, green: (base + 20)/255, blue: (base + 20)/255)
}


struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
    }
}
