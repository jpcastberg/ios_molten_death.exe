/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`NowPlayable` protocol defines customization points for the behavior an app
 must provide in order to be eligible to become the "Now Playing" app system-wide,
 and to maintain the Now Playing Info panel (and controls) correctly.
*/

import Foundation
import MediaPlayer

enum NowPlayableInterruption {
    case began, ended(Bool), failed(Error)
}

protocol NowPlayable: AnyObject {
    
    var defaultAllowsExternalPlayback: Bool { get }
    
    var defaultRegisteredCommands: [NowPlayableCommand] { get }
    
    var defaultDisabledCommands: [NowPlayableCommand] { get }
    
    func handleNowPlayableConfiguration(commands: [NowPlayableCommand],
                                        disabledCommands: [NowPlayableCommand],
                                        commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus,
                                        interruptionHandler: @escaping (NowPlayableInterruption) -> Void) throws
    
    func handleNowPlayableSessionStart() throws
    
    func handleNowPlayableSessionEnd()
    
    func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata)
    
    func handleNowPlayablePlaybackChange(playing: Bool, metadata: NowPlayableDynamicMetadata)
}

extension NowPlayable {
    
    func configureRemoteCommands(_ commands: [NowPlayableCommand],
                                 disabledCommands: [NowPlayableCommand],
                                 commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) throws {
        
        for command in NowPlayableCommand.allCases {
            
            command.removeHandler()
            
            if commands.contains(command) {
                command.addHandler(commandHandler)
            }
            
            command.setDisabled(disabledCommands.contains(command))
        }
    }
    
    func setNowPlayingMetadata(_ metadata: NowPlayableStaticMetadata) {
       
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] = metadata.assetURL
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = metadata.mediaType.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = metadata.isLiveStream
        nowPlayingInfo[MPMediaItemPropertyTitle] = metadata.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = metadata.artist
        nowPlayingInfo[MPMediaItemPropertyArtwork] = metadata.artwork
        nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = metadata.albumArtist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = metadata.albumTitle
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    func setNowPlayingPlaybackInfo(_ metadata: NowPlayableDynamicMetadata) {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = metadata.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = metadata.position
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = metadata.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyCurrentLanguageOptions] = metadata.currentLanguageOptions
        nowPlayingInfo[MPNowPlayingInfoPropertyAvailableLanguageOptions] = metadata.availableLanguageOptionGroups
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
}
