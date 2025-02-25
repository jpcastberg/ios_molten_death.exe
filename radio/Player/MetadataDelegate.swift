import AVFoundation
import MediaPlayer
import SwiftUI

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
                let artistMeta = groups[0].items.first(where: { $0.commonKey == AVMetadataKey.commonKeyArtist })

                var streamTitle: String? = nil
                var songTitle: String? = nil
                var artist = "No Artist"

                if let songTitleMeta = songTitleMeta {
                    songTitle = String(describing: try await songTitleMeta.load(.value)!)
                }

                if let artistMeta = artistMeta {
                    artist = String(describing: try await artistMeta.load(.value)!)
                } else if songTitle != nil && songTitle!.hasPrefix("BUMPER ") {
                    artist = ""
                }

                if let songTitle = songTitle {
                    streamTitle = artist + " - " + songTitle

                    if streamTitle == currentStreamTitle {
                        return
                    } else if songTitle.hasPrefix("BUMPER ") {
                        self.metadataUpdateClosure(self.createMetadataForBumper(streamTitle: songTitle), nil, true)
                        return
                    }
                }

                if streamTitle == nil && currentStreamTitle != nil {
                    return
                }

                currentStreamTitle = streamTitle
                self.fetchNowPlayingApiDataForStreamTitle(with: streamTitle)
            } catch {}
        }
    }

    func handleMetadataForSkip() {
        let skipTitle = "BUMPER Skipping to next song..."
        self.metadataUpdateClosure(createMetadataForBumper(streamTitle: skipTitle), nil, true)
    }

    func fetchNowPlayingApiDataForStreamTitle(with streamTitle: String?) {
        self.radioStation.fetchNowPlayingApiDataForStreamTitle(with: streamTitle, completion: {nowPlayingResponse in
            let artist = nowPlayingResponse.nowPlaying.song.artist
            let songTitle = nowPlayingResponse.nowPlaying.song.title
            let shouldStartFromZero = self.currentStreamTitle != nil
            self.currentStreamTitle = artist + " - " + songTitle
            self.convertNowPlayingResponseToMetadata(with: nowPlayingResponse, completion: {nowPlayableStaticMetadata in
                self.metadataUpdateClosure(nowPlayableStaticMetadata, nowPlayingResponse, shouldStartFromZero)
            })
        })
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
        let defaultUrl = URL(string: "https://radio.castberg.media/static/uploads/molten_death.exe/album_art.1739658915.png")!
        let image = UIImage(named: "DefaultImage")!
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
