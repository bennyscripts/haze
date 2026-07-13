//
//  WelcomeView.swift
//  IpInfo
//
//  Created by Ben on 12/07/2026.
//


import SwiftUI

struct WelcomeView: View {
    let appDelegate: AppDelegate
    
    var body: some View {
        VStack(spacing: 30) {
            Image("WelcomeImage")
                .resizable()
                .frame(width: 150, height: 150)

            Text("IPInfo")
                .font(.system(size: 34).weight(.bold))

            Text("""
Lookup IP addresses locally
using the GeoLite2 database.
""")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                

            Button {
                NSApp.keyWindow?.close()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NSApp.activate(ignoringOtherApps: true)
                    appDelegate.openMenu()
                }
            } label: {
                Text("Get Started")
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
//                    .glassEffect()
            }
            .buttonStyle(.glassProminent)
            .cornerRadius(30)
            .padding(.top, 20)
            .tint(.blue)
        }
        .padding(40)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
//        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    WelcomeView(appDelegate: AppDelegate())
}
