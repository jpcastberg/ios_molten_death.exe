/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`NowPlayableStaticMetadata` contains static properties of a playable item that don't depend on the state of the player for their value.
*/

import Foundation
import MediaPlayer

struct NowPlayableStaticMetadata {
    
    let assetURL: URL
    let mediaType: MPNowPlayingInfoMediaType
    let isLiveStream: Bool
    
    let title: String
    let artist: String?
    let artwork: MPMediaItemArtwork?
    
    let albumArtist: String?
    let albumTitle: String?
    
}

struct NowPlayableDynamicMetadata {
    
    let rate: Float
    let position: Float
    let duration: Float
    
    let currentLanguageOptions: [MPNowPlayingInfoLanguageOption]
    let availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup]
    
}
