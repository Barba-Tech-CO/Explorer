//
//  ContentView.swift
//  Explorer
//
//  Created by Barba Dz on 5/6/26.
//

import SwiftUI

struct ContentView: View {
    @State private var navigation = NavigationState()

    var body: some View {
        VStack(spacing: 0) {
            AddressBarView(navigation: navigation)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            ContentPlaceholderView(url: navigation.currentURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 720, minHeight: 480)
    }
}

#Preview {
    ContentView()
}
