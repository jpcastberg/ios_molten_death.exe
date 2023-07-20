/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate that manages the application life cycle.
*/

import SwiftUI

@main
struct radioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
    }
}

struct ContentView: View {
    @State private var isPlaying = false
    @State private var currentSong = ""
    @State private var albumArtURL: URL?
    @State private var assetPlayer: AssetPlayer?

    init() {
        do {
            assetPlayer = try AssetPlayer()
        } catch {}
    }

    var body: some View {
        VStack {
            Image("DefaultImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text("molten_death.exe")
        }
    }
}
