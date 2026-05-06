//
//  ContentView.swift
//  Explorer
//
//  Created by Barba Dz on 5/6/26.
//

import SwiftUI

struct ContentView: View {
  let dependencies: AppDependencies

  @State private var navigation: NavigationState

  init(dependencies: AppDependencies) {
    self.dependencies = dependencies
    self._navigation = State(
      initialValue: NavigationState(initial: dependencies.repository.home)
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      AddressBarView(
        navigation: navigation,
        listSubfolders: dependencies.listSubfolders,
        resolvePath: dependencies.resolvePath
      )
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider()

      ContentPlaceholderView(folder: navigation.current)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(minWidth: 720, minHeight: 480)
  }
}

#Preview {
  ContentView(dependencies: .live())
}
