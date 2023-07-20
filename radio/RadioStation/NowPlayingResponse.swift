import AVFoundation

public struct NowPlayingResponse: Codable {
    let station: Station
    let listeners: Listeners
    let live: Live
    let nowPlaying: NowPlaying
    let playingNext: PlayingNext
    let songHistory: [SongHistory]
    let isOnline: Bool
    
    enum CodingKeys: String, CodingKey {
        case station
        case listeners
        case live
        case nowPlaying = "now_playing"
        case playingNext = "playing_next"
        case songHistory = "song_history"
        case isOnline = "is_online"
    }
}

struct Station: Codable {
    let id: Int
    let name: String
    let listenURL: URL
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case listenURL = "listen_url"
    }
}

struct Listeners: Codable {
    let total: Int
    let unique: Int
    let current: Int
    
    enum CodingKeys: String, CodingKey {
        case total
        case unique
        case current
    }
}

struct Live: Codable {
    let isLive: Bool
    let streamerName: String
    let broadcastStart: Date?
    let art: URL?
    
    enum CodingKeys: String, CodingKey {
        case isLive = "is_live"
        case streamerName = "streamer_name"
        case broadcastStart = "broadcast_start"
        case art
    }
}

struct Song: Codable {
    let id: String
    let text: String
    let artist: String
    let title: String
    let album: String
    let genre: String
    let isrc: String
    let lyrics: String
    let art: URL
    let customFields: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case artist
        case title
        case album
        case genre
        case isrc
        case lyrics
        case art
        case customFields = "custom_fields"
    }
}

struct NowPlaying: Codable {
    let shID: Int
    let playedAt: TimeInterval
    let duration: Int
    let playlist: String
    let streamer: String
    let isRequest: Bool
    let song: Song
    let elapsed: Int
    let remaining: Int
    
    enum CodingKeys: String, CodingKey {
        case shID = "sh_id"
        case playedAt = "played_at"
        case duration
        case playlist
        case streamer
        case isRequest = "is_request"
        case song
        case elapsed
        case remaining
    }
}

struct PlayingNext: Codable {
    let cuedAt: TimeInterval
    let playedAt: TimeInterval
    let duration: Int
    let playlist: String
    let isRequest: Bool
    let song: Song
    
    enum CodingKeys: String, CodingKey {
        case cuedAt = "cued_at"
        case playedAt = "played_at"
        case duration
        case playlist
        case isRequest = "is_request"
        case song
    }
}

struct SongHistory: Codable {
    let shID: Int
    let playedAt: TimeInterval
    let duration: Int
    let playlist: String
    let streamer: String
    let isRequest: Bool
    let song: Song
    
    enum CodingKeys: String, CodingKey {
        case shID = "sh_id"
        case playedAt = "played_at"
        case duration
        case playlist
        case streamer
        case isRequest = "is_request"
        case song
    }
}
