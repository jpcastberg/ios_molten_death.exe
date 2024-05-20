import AVFoundation
import MediaPlayer

class MetadataDelegate: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    public var currentStreamTitle: String?
    private var radioStation: RadioStation
    private var metadataUpdateClosure: ((NowPlayableStaticMetadata, NowPlayingResponse?, Bool) -> Void)
    private var songDidChange = false
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    init(radioStation: RadioStation, metadataUpdateClosure: @escaping (NowPlayableStaticMetadata, NowPlayingResponse?, Bool) -> Void) {
        self.radioStation = radioStation
        self.metadataUpdateClosure = metadataUpdateClosure
    }

    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
        Task {
            do {
                let songTitleMeta = groups[0].items.first(where: { $0.commonKey == AVMetadataKey.commonKeyTitle })
                let albumNameMeta = groups[0].items.first(where: { $0.commonKey == AVMetadataKey.commonKeyAlbumName })
                let artistMeta = groups[0].items.first(where: { $0.commonKey == AVMetadataKey.commonKeyArtist })

                let songTitle = String(describing: try await songTitleMeta!.load(.value)!)
                var artist = "No Artist"
                
                if artistMeta != nil {
                    artist = String(describing: try await artistMeta!.load(.value)!)
                }
                
                let streamTitle = artist + " - " + songTitle
                
                if streamTitle == currentStreamTitle {
                    return
                }
                
                let shouldStartFromZero = currentStreamTitle != nil
                currentStreamTitle = streamTitle
                
                self.radioStation.fetchNowPlayingApiDataForStreamTitle(with: streamTitle, completion: {nowPlayingResponse in
                    if songTitle.hasPrefix(bumperPrefix) {
                        self.metadataUpdateClosure(self.createMetadataForBumper(streamTitle: streamTitle), nowPlayingResponse, shouldStartFromZero)
                    } else {
                        self.convertNowPlayingResponseToMetadata(with: nowPlayingResponse, completion: {nowPlayableStaticMetadata in
                            self.metadataUpdateClosure(nowPlayableStaticMetadata, nowPlayingResponse, shouldStartFromZero)
                        })
                    }
                })
            } catch {}
        }
    }

    func handleMetadataForSkip() {
        let skipTitle = "BUMPER Skipping to next song..."
        self.metadataUpdateClosure(createMetadataForBumper(streamTitle: skipTitle), nil, true)
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
        let defaultUrl = URL(string: "https://radio.castberg.media/static/img/generic_song.jpg")!
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
