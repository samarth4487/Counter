//
//  CounterApp.swift
//  Counter
//
//  Created by Samarth Paboowal on 22/09/23.
//

import SwiftUI
import ComposableArchitecture

@main
struct CounterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: CounterFeature.State()) {
                CounterFeature()
            })
        }
    }
}
