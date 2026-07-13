//
//  Extensions.swift
//  IpInfo
//
//  Created by Ben Tettmar on 08/04/2022.
//

import Foundation
import SwiftUI

extension View {
    func insetGroupedStyle(header: String) -> some View {
        #if os(iOS)
        return Section(header: Text(header.uppercased())) {
            self
        }
        #else
        return GroupBox(label: Text(header.uppercased()).font(.headline).padding(.top).padding(.bottom, 6)) {
            VStack {
                self.padding(.vertical, 3)
            }.padding(.horizontal).padding(.vertical)
        }
        #endif
    }
}
