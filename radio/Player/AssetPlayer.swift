/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`AssetPlayer` uses an AVQueuePlayer for playback of `ConfigAsset` items,
 with a `NowPlayable` delegate for handling platform-specific behavior.
*/

import AVFoundation
import MediaPlayer

class AssetPlayer {
    enum PlayerState {
        case stopped
        case playing
        case paused
    }
    
    let nowPlayableBehavior: NowPlayable
    
    let player: AVPlayer
    
    var playerState: PlayerState = .stopped
    
    private var isInterrupted: Bool = false
    
    private var itemObserver: NSKeyValueObservation!
    private var rateObserver: NSKeyValueObservation!
    private var statusObserver: NSObjectProtocol!
    
    private static let mediaSelectionKey = "availableMediaCharacteristicsWithMediaSelectionOptions"
    
    private let radioStation = RadioStation()
    private let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
    private var metadataDelegate: MetadataDelegate?
    
    init() throws {
        self.nowPlayableBehavior = IOSNowPlayableBehavior()

        let streamURL = URL(string: "https://radio.castberg.media/listen/molten_death.exe/radio.mp3")!
        self.player = AVPlayer(url: streamURL)
        player.allowsExternalPlayback = true

        if metadataDelegate == nil {
            metadataDelegate = MetadataDelegate(radioStation: radioStation, metadataUpdateClosure: { metadata, nowPlayingResponse in
                self.handlePlayerItemChange(metadata: metadata)
                if let passedNowPlayingResponse = nowPlayingResponse { // check if nowPlayingResponse was passed
                    let position = passedNowPlayingResponse.nowPlaying.elapsed
                    let duration = passedNowPlayingResponse.nowPlaying.duration
                    self.handlePlaybackChange(position: position, duration: duration)
                }
            })
        }
        
        let playerItem = player.currentItem!
        metadataOutput.setDelegate(metadataDelegate, queue: DispatchQueue.main)
        playerItem.add(metadataOutput)
        player.replaceCurrentItem(with: playerItem)
        try nowPlayableBehavior.handleNowPlayableConfiguration(commands: [.play, .pause, .nextTrack],
                                                               disabledCommands: [],
                                                               commandHandler: handleCommand(command:event:),
                                                               interruptionHandler: handleInterrupt(with:))
        try nowPlayableBehavior.handleNowPlayableSessionStart()
        startPlayback()
    }
    
    func stopPlayback() {
        itemObserver = nil
        rateObserver = nil
        statusObserver = nil
        
        player.pause()
        playerState = .stopped
        
        nowPlayableBehavior.handleNowPlayableSessionEnd()
    }
    
    private func handlePlayerItemChange(metadata: NowPlayableStaticMetadata) {

        guard playerState != .stopped else { return }
        
        nowPlayableBehavior.handleNowPlayableItemChange(metadata: metadata)
    }
    
    private func handlePlaybackChange(position: Int, duration: Int) {
        
        guard playerState != .stopped else { return }
        
        let isPlaying = playerState == .playing
        let adjustedPosition = max(0, position - 5) // api position tends to run about 5 seconds ahead of stream
        let metadata = NowPlayableDynamicMetadata(rate: player.rate,
                                                  position: Float(adjustedPosition),
                                                  duration: Float(duration),
                                                  currentLanguageOptions: [],
                                                  availableLanguageOptionGroups: [])
        
        nowPlayableBehavior.handleNowPlayablePlaybackChange(playing: isPlaying, metadata: metadata)
    }
    
    private func startPlayback() {
        
        switch playerState {
            
        case .stopped:
            playerState = .playing
            player.play()

        case .playing:
            break
            
        case .paused where isInterrupted:
            playerState = .playing
            
        case .paused:
            playerState = .playing
            player.play()
        }
    }
    
    private func pausePlayback() {
        
        switch playerState {
            
        case .stopped:
            break
            
        case .playing where isInterrupted:
            playerState = .paused
            
        case .playing:
            playerState = .paused
            player.pause()
            
        case .paused:
            break
        }
    }
    
    func togglePlayPause() {

        switch playerState {
            
        case .stopped:
            startPlayback()
            
        case .playing:
            pausePlayback()
            
        case .paused:
            startPlayback()
        }
    }
    
    private func nextTrack() {
        if case .stopped = playerState { return }
        radioStation.skipTrack()
        metadataDelegate?.handleMetadataForSkip()
    }
    
    private func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        switch command {
            
        case .pause:
            pausePlayback()
            
        case .play:
            startPlayback()
            
        case .stop:
            stopPlayback()
            
        case .togglePausePlay:
            togglePlayPause()
            
        case .nextTrack:
            nextTrack()

        default:
            break
        }
        
        return .success
    }
    
    private func handleInterrupt(with interruption: NowPlayableInterruption) {
        
        switch interruption {
            
        case .began:
            isInterrupted = true
            
        case .ended(let shouldPlay):
            isInterrupted = false
            
            switch playerState {
                
            case .stopped:
                break
                
            case .playing where shouldPlay:
                player.play()
                
            case .playing:
                playerState = .paused
                
            case .paused:
                break
            }
            
        case .failed(let error):
            print(error.localizedDescription)
            stopPlayback()
        }
    }
    
}
