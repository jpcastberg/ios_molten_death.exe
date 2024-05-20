/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate that manages the application life cycle.
*/

import SwiftUI
public var assetPlayer: AssetPlayer?

@main
struct radioApp: App {

    init() {
        do {
            assetPlayer = try AssetPlayer()
        } catch {}
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                MainView()
                    .tabItem { Label("Home", systemImage: "play.house.fill") }
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
