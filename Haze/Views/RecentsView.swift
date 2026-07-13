//
//  RecentsView.swift
//  Haze
//
//  Created by Ben on 13/07/2026.
//

import SwiftUI

struct RecentsView: View {
    @ObservedObject var appDelegate: AppDelegate
    @FocusState private var focused: Bool
    @State private var hoveredItem: UUID?
    
    var body: some View {
        VStack {
//            Text("Recents".uppercased())
//                .font(.headline)
//                .multilineTextAlignment(.leading)
//                .padding(.bottom, 10)
            if !appDelegate.recents.recents.isEmpty {
                ScrollView {
                    ForEach(appDelegate.recents.recents) { item in
                        Button {
                            appDelegate.lookupIP(item.ip)
                        } label: {
                            VStack(spacing: 15) {
                                Cell(leading: "IP", trailing: item.ip)
                                Cell(leading: "Country", trailing: item.country)
                                Cell(leading: "Organisation", trailing: item.organisation)
                                Cell(leading: "Looked up at", trailing: item.timestamp.formatted())
                            }
                            .padding(22)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15))
                            .padding(.bottom, 2)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            hoveredItem = hovering ? item.id : nil
                            
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .contextMenu {
                            Button {
                                appDelegate.lookupIP(item.ip)
                            } label: {
                                Label("Lookup", systemImage: "magnifyingglass")
                            }
                            Button(role: .destructive) {
                                appDelegate.recents.remove(item)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
                .frame(
                    height: min(
                        CGFloat(appDelegate.recents.recents.count) * 115,
                        540
                    )
                )
            } else {
                VStack {
                    Cell(
                        leading: "Your recent IP lookups will appear here.",
                        trailing: ""
                    )
                }
                .padding(22)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15))
            }
        }
        .focused($focused)
        .onAppear {
            focused = true
        }
        .padding()
        .frame(width: 380)
    }
}
