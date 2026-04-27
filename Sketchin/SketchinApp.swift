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
    

    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(for: Sketch.self)
    }
}
