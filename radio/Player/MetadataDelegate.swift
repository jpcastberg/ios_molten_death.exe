import AVFoundation
import MediaPlayer

class MetadataDelegate: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    private var radioStation: RadioStation
    private var metadataUpdateClosure: ((NowPlayableStaticMetadata, NowPlayingResponse?) -> Void)
    private var songDidChange = false
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private var timer: Timer?
    
    init(radioStation: RadioStation, metadataUpdateClosure: @escaping (NowPlayableStaticMetadata, NowPlayingResponse?) -> Void) {
        self.radioStation = radioStation
        self.metadataUpdateClosure = metadataUpdateClosure
    }

    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        for metadataGroup in groups {
            for item in metadataGroup.items {
                if item.identifier == AVMetadataIdentifier.icyMetadataStreamTitle {
                    Task {
                        do {
                            let loadingStreamTitle = try await item.load(.value)
                            let streamTitle = String(describing: loadingStreamTitle!)
                            if streamTitle.hasPrefix("BUMPER ") {
                                self.metadataUpdateClosure(createMetadataForBumper(streamTitle: streamTitle), nil)
                            }

                            self.radioStation.fetchNowPlayingApiDataForStreamTitle(with: streamTitle, completion: {nowPlayingResponse in
                                self.convertNowPlayingResponseToMetadata(with: nowPlayingResponse, completion: {nowPlayableStaticMetadata in
                                    self.metadataUpdateClosure(nowPlayableStaticMetadata, nowPlayingResponse)
                                })
                            })
                        } catch {}
                    }
                }
            }
        }
    }

    func handleMetadataForSkip() {
        let skipTitle = "BUMPER Skipping to next song..."
        self.metadataUpdateClosure(createMetadataForBumper(streamTitle: skipTitle), nil)
    }

    private func convertNowPlayingResponseToMetadata(with nowPlayingResponse: NowPlayingResponse, completion: @escaping (NowPlayableStaticMetadata) -> Void) {
        let song = nowPlayingResponse.nowPlaying.song
        getData(from: song.art, completion: {downloadedImage in
            
            let artworkMetadata = MPMediaItemArtwork(boundsSize: downloadedImage!.size, requestHandler: {_ in
                return downloadedImage!
            })
            
            let metadata = NowPlayableStaticMetadata(assetURL: song.art, mediaType: .audio, isLiveStream: false, title: song.title, artist: song.artist, artwork: artworkMetadata, albumArtist: song.artist, albumTitle: song.album)
            
            completion(metadata)
        })
    }

    private func createMetadataForBumper(streamTitle: String) -> NowPlayableStaticMetadata {
        let defaultUrl = URL(string: "https://radio.castberg.media")!
        let image = UIImage(named: "DefaultImage.png")!
        let prefix = "BUMPER "

        let artworkMetadata = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {_ in
            return image
        })


        return NowPlayableStaticMetadata(assetURL: defaultUrl, mediaType: .audio, isLiveStream: false, title: String(streamTitle.dropFirst(prefix.count)), artist: "molten_death.exe", artwork: artworkMetadata, albumArtist: "molten_death.exe", albumTitle: "bumpers")
    }
    
    private func getData(from url: URL, completion: @escaping (UIImage?) -> Void) {
         URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
             if let data = data {
                 completion(UIImage(data:data))
             }
         })
             .resume()
     }
}
