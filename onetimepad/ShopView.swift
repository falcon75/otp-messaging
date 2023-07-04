//
//  ShopView.swift
//  onetimepad
//
//  Created by Samuel McHale on 03/07/2023.
//

import SwiftUI


struct ShopView: View {
    var body: some View {
        VStack {
            Spacer()
            Button {
                print("Hi")
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(.gray)
                        .frame(width: 300, height: 200)
                        .cornerRadius(30)
                    VStack {
                        Text("🔒 Standard")
                            .foregroundColor(.white)
                            .font(.title)
                        Text("1000 Characters / Day")
                            .foregroundColor(.white)
                            .font(.body)
                    }
                    Text("Free")
                            .foregroundColor(.white)
                            .font(.caption)
                            .offset(x: 100, y: -70)
                }
            }
            Button {
                print("Hi")
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(.green)
                        .frame(width: 300, height: 200)
                        .cornerRadius(30)
                    VStack {
                        Text("💸 Premium")
                            .foregroundColor(.white)
                            .font(.title)
                        Text("Unlimited Messages")
                            .foregroundColor(.white)
                            .font(.body)
                    }
                    Text("£1 / Month")
                        .foregroundColor(.white)
                        .font(.caption)
                        .offset(x: 100, y: -70)
                }
            }
            Spacer()
        }
        .padding()
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
    }
}
