/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`IOSNowPlayableBehavior` implements the `NowPlayable` protocol for the iOS platform.
*/

import Foundation
import MediaPlayer

class IOSNowPlayableBehavior: NowPlayable {
    
    var defaultAllowsExternalPlayback: Bool { return true }
    
    var defaultRegisteredCommands: [NowPlayableCommand] {
        return [.play, .pause, .nextTrack]
    }
    
    var defaultDisabledCommands: [NowPlayableCommand] {
        return []
    }
    private var interruptionObserver: NSObjectProtocol!
    private var interruptionHandler: (NowPlayableInterruption) -> Void = { _ in }
    
    func handleNowPlayableConfiguration(commands: [NowPlayableCommand],
                                        disabledCommands: [NowPlayableCommand],
                                        commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus,
                                        interruptionHandler: @escaping (NowPlayableInterruption) -> Void) throws {
        
        self.interruptionHandler = interruptionHandler
        
        try configureRemoteCommands(commands, disabledCommands: disabledCommands, commandHandler: commandHandler)
    }
    
    func handleNowPlayableSessionStart() throws {
        
        let audioSession = AVAudioSession.sharedInstance()
        
        interruptionObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
                                                                      object: audioSession,
                                                                      queue: .main) {
            [unowned self] notification in
            self.handleAudioSessionInterruption(notification: notification)
        }
         
        try audioSession.setCategory(.playback, mode: .default)
        
         try audioSession.setActive(true)
    }
    
    func handleNowPlayableSessionEnd() {
        
        interruptionObserver = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session, error: \(error)")
        }
    }
    
    func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata) {
        
        setNowPlayingMetadata(metadata)
    }
    
    func handleNowPlayablePlaybackChange(playing: Bool, metadata: NowPlayableDynamicMetadata) {
        
        setNowPlayingPlaybackInfo(metadata)
    }
    
    private func handleAudioSessionInterruption(notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let interruptionTypeUInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeUInt) else { return }
        
        switch interruptionType {
            
        case .began:
            
            interruptionHandler(.began)
            
        case .ended:
            
            do {
                
                try AVAudioSession.sharedInstance().setActive(true)
                
                var shouldResume = false
                
                if let optionsUInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                    AVAudioSession.InterruptionOptions(rawValue: optionsUInt).contains(.shouldResume) {
                    shouldResume = true
                }
                
                interruptionHandler(.ended(shouldResume))
            }
                
            catch {
                interruptionHandler(.failed(error))
            }
            
        @unknown default:
            break
        }
    }
    
}
