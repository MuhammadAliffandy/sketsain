//
//  SketchinApp.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI
import SwiftData

@main
struct SketchinApp: App {
    
    @AppStorage("isFirstTime") private var isFirstTime: Bool = true
    
    var body: some Scene {
        WindowGroup {
            if isFirstTime {
                SplashView()
            }else{
                HomeView()
            }
        }
        .modelContainer(for: Sketch.self)
    }
}
