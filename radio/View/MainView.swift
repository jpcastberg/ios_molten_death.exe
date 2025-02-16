//
//  MainViewController.swift
//  radio
//
//  Created by John Castberg on 1/20/24.
//

import SwiftUI

public var mainViewModel = MainViewModel()

struct MainView: View {
    @ObservedObject var _mainViewModel = mainViewModel
    @ObservedObject var _assetPlayer = assetPlayer!

    var body: some View {
        VStack {
            NowPlayingView(heading: "Now Playing", imageUrl: mainViewModel.nowPlayingImageUrl, title: mainViewModel.nowPlayingTitle, albumName: mainViewModel.nowPlayingAlbum!)
            Divider()
            UpNextView(heading: "Up Next", imageUrl: mainViewModel.upNextImageUrl, title: mainViewModel.upNextTitle, albumName: mainViewModel.upNextAlbum!)
            Divider()
            HStack(spacing: 125) {
                if assetPlayer?.playerState == .playing {
                    Image(systemName: "stop.circle") // Replace with the actual symbol you want.
                        .font(.system(size: 40))
                        .foregroundColor(.red) // Customize the color if needed
                        .onTapGesture {
                            assetPlayer?.togglePlayPause()
                        }
                } else {
                    Image(systemName: "play.circle") // Replace with the actual symbol you want
                        .font(.system(size: 40))
                        .foregroundColor(.green) // Customize the color if needed
                        .onTapGesture {
                            assetPlayer?.togglePlayPause()
                        } // Customize the color if needed
                }
                
                Image(systemName: "forward.end.circle") // Replace with the actual symbol you want
                    .font(.system(size: 40))
                    .foregroundColor(.gray) // Customize the color if needed
                    .onTapGesture {
                        assetPlayer?.nextTrack()
                    }
            }
        }
    }
}

struct NowPlayingView: View {
    let heading: String
    let imageUrl: URL
    let title: String
    let albumName: String
    
    var body: some View {
        VStack {
            VStack {
                Text(heading)
                    .font(.title2)

                AsyncImage(
                    url: imageUrl,
                    content: { image in
                        image.resizable()
                             .aspectRatio(contentMode: .fit)
                    },
                    placeholder: {
                        ProgressView()
                    }
                )
            }
            HStack {
                VStack(alignment: .leading) {
                    SongMetadataView(symbolName: "music.note", text: title)
                    if albumName != "" {
                        SongMetadataView(symbolName: "opticaldisc.fill", text: albumName)
                    }
                }
                Spacer()
            }
        }.padding(10)
    }
}

struct UpNextView: View {
    let heading: String
    let imageUrl: URL
    let title: String
    let albumName: String
    
    var body: some View {
        VStack {
            Text(heading)
                .font(.title2)
            VStack {
                HStack {
                    AsyncImage(
                        url: imageUrl,
                        content: { image in
                            image.resizable()
                                 .aspectRatio(contentMode: .fit)
                                 .frame(width: 100, height: 100)
                        },
                        placeholder: {
                            ProgressView()
                        }
                    )
                    VStack(alignment: .leading) {
                        SongMetadataView(symbolName: "music.note", text: title)
                        if albumName != "" {
                            SongMetadataView(symbolName: "opticaldisc.fill", text: albumName)
                        }
                    }
                    Spacer()
                }
            }
        }.padding(10)
    }
}

struct SongMetadataView: View {
    let symbolName: String
    let text: String

    var body: some View {
        HStack(spacing: 10) { // Adjust spacing as needed
            Image(systemName: symbolName) // Replace with the actual symbol you want
                .foregroundColor(.blue) // Customize the color if needed
            Text(text)
        }
    }
}

public class MainViewModel: ObservableObject {
    @Published var nowPlayingImageUrl = URL(string: "https://radio.castberg.media/static/uploads/molten_death.exe/album_art.1739658915.png")!
    @Published var nowPlayingTitle = "Loading Artist"
    @Published var nowPlayingAlbum: String? = "Loading Album Name"
    @Published var upNextImageUrl = URL(string: "https://radio.castberg.media/static/uploads/molten_death.exe/album_art.1739658915.png")!
    @Published var upNextTitle = "Loading Artist"
    @Published var upNextAlbum: String? = "Loading Album Name"

    public func updateNowPlayingContent(nowPlayingImageUrl: URL, nowPlayingArtist: String, nowPlayingSongTitle: String, nowPlayingAlbum: String) {
        DispatchQueue.main.async {
            self.nowPlayingImageUrl = nowPlayingImageUrl
            self.nowPlayingTitle = self.computeTitle(artistName: nowPlayingArtist, songTitle: nowPlayingSongTitle)
            self.nowPlayingAlbum = nowPlayingAlbum
        }
    }
    
    public func updateUpNextContent(upNextImageUrl: URL, upNextArtist: String, upNextSongTitle: String, upNextAlbum: String) {
        DispatchQueue.main.async {
            self.upNextTitle = self.computeTitle(artistName: upNextArtist, songTitle: upNextSongTitle)
            self.upNextImageUrl = upNextImageUrl
            self.upNextAlbum = upNextAlbum
        }
    }
    
    private func computeTitle(artistName: String, songTitle: String) -> String {
        if songTitle.starts(with: bumperPrefix) {
            return songTitle.replacingOccurrences(of: bumperPrefix, with: "")
        } else if artistName == "" {
            return songTitle
        }
        
        return artistName + " - " + songTitle
    }
}
