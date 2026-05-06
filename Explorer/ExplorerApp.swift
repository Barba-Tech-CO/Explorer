//
//  ExplorerApp.swift
//  Explorer
//
//  Created by Barba Dz on 5/6/26.
//

import SwiftUI

@main
struct ExplorerApp: App {
  private let dependencies = AppDependencies.live()

  var body: some Scene {
    WindowGroup {
      ContentView(dependencies: dependencies)
    }
  }
}
