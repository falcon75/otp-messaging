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
                    Rectangle()
                        .foregroundColor(.gray)
                        .frame(height: 150)
                        .cornerRadius(30)
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
                    Rectangle()
                        .foregroundColor(.green)
                        .frame(height: 150)
                        .cornerRadius(30)
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
                        .offset(x: 140, y: -50)
                    Image(systemName: !premium ? "circle" : "checkmark.circle.fill").foregroundColor(colorScheme == .dark ? .black : .white).padding().offset(x: 140).font(.title)
                }
            }
        }.padding()
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
    }
}
