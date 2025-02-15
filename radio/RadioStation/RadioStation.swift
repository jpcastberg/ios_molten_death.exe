import AVFoundation

public let bumperPrefix = "BUMPER "

public class RadioStation {
    private var timer: Timer?
    private var azuracastToken: String?

    init() {
        if let fileURL = Bundle.main.url(forResource: "azuracast_token", withExtension: "txt") {
            do {
                azuracastToken = try String(contentsOf: fileURL, encoding: .utf8).trimmingCharacters(in: .newlines)
            } catch {}
        } else {
            print("azuracast_token.txt file required to support track skipping")
        }
    }

    func skipTrack() {
        if azuracastToken == nil {
            print("no access token available to use to skip track")
            return
        }
        
        let logUrl = URL(string: "https://scrobbler.castberg.media/log-skip")!
        var logRequest = URLRequest(url: logUrl)
        logRequest.httpMethod = "POST"
        let logTask = URLSession.shared.dataTask(with: logRequest) { (data, response, error) in }
        logTask.resume()

        let url = URL(string: "https://radio.castberg.media/api/station/molten_death.exe/backend/skip")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(azuracastToken!, forHTTPHeaderField: "X-API-Key")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in }
        task.resume()
    }
    
    func fetchNowPlayingApiDataForStreamTitle(with streamTitle: String, completion: @escaping (NowPlayingResponse) -> Void) {
        let url = URL(string: "https://radio.castberg.media/api/nowplaying/molten_death.exe")!
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        timer?.invalidate()
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    do {
                        let nowPlayingResponse = try JSONDecoder().decode(NowPlayingResponse.self, from: data!)
                        let nowPlayingSongText = nowPlayingResponse.nowPlaying.song.text
                        
                        if nowPlayingSongText == streamTitle {
                            completion(nowPlayingResponse)
                            self.timer?.invalidate()
                        }
                    } catch {
                        print("Error decoding API response: \(error)")
                    }
                }
                
                task.resume()
            }
        }
    }
}
