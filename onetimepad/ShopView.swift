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
        VStack {
            HStack {
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "arrow.down").font(.title).foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            Spacer()
            Button {
                premium = false
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .foregroundColor(.gray)
                        .frame(height: 150)
                        .shadow(color: Color.darkShadow, radius: 8, x: 8, y: 8)
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(LinearGradient(gradient: Gradient(colors: [Color.borderGradientStart2, Color.borderGradientEnd2]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 5)
                        .frame(height: 150)
                    HStack {
                        Spacer()
                        VStack {
                            Text("🔒 Standard")
                                .foregroundColor(.white)
                                .font(.title)
                            Text("1000 Characters / Day")
                                .foregroundColor(.white)
                                .font(.body)
                        }
                        Spacer()
                    }
                    Text("Free")
                            .foregroundColor(.white)
                            .font(.callout)
                            .offset(x: 140, y: -50)
                    Image(systemName: premium ? "circle" : "checkmark.circle.fill").foregroundColor(colorScheme == .dark ? .black : .white).padding().offset(x: 140).font(.title)
                }
            }
            Button {
                premium = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.green)
                        .frame(height: 150)
                        .shadow(color: Color.darkShadow, radius: 8, x: 8, y: 8)
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(LinearGradient(gradient: Gradient(colors: [Color.darkGreen, Color.lightGreen]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 5)
                        .frame(height: 150)
                    HStack {
                        Spacer()
                        VStack{
                            Text("💸 Premium")
                                .foregroundColor(.white)
                                .font(.title)
                            Text("Unlimited Messages")
                                .foregroundColor(.white)
                                .font(.body)
                            Text("Unlock All Themes")
                                .foregroundColor(.white)
                                .font(.body)
                        }
                        Spacer()
                    }
                    Text("£1 / Month")
                        .foregroundColor(.white)
                        .font(.callout)
                        .offset(x: 125, y: -50)
                    Image(systemName: !premium ? "circle" : "checkmark.circle.fill").foregroundColor(colorScheme == .dark ? .black : .white).padding().offset(x: 140).font(.title)
                }
            }
        }.padding()
    }
}



extension Color {
    static let offWhite = Color(red: 240/255, green: 240/255, blue: 240/255)
    static let darkShadow = Color(red: 220/255, green: 220/255, blue: 220/255)
    static let lightShadow = Color.white
    static let darkGreen = Color(red: 41/255, green: 163/255, blue: 61/255)
    static let lightGreen = Color(red: 56/255, green: 223/255, blue: 83/255)
    static let borderGradientStart = Color(red: 230/255, green: 230/255, blue: 230/255)
    static let borderGradientEnd = Color.white
    
    static let base: Double = 190
    static let borderGradientEnd2 = Color(red: base/255, green: base/255, blue: base/255)
    static let borderGradientStart2 = Color(red: (base + 20)/255, green: (base + 20)/255, blue: (base + 20)/255)
}


struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
    }
}
