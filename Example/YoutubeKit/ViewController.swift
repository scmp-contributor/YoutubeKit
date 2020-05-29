//
//  ViewController.swift
//  YoutubeKit
//
//  Created by Ryo Ishikawa on 12/30/2017.
//  Copyright (c) 2017 Ryo Ishikawa. All rights reserved.
//

import UIKit
import YoutubeKit

final class ViewController: UIViewController {

    private var player: YTSwiftyPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Note: Run this example, You might be face on following message.
        // `[Process] kill() returned unexpected error 1`
        // This is a bug of WKWebView in iOS13 and that will be fixed in 13.4 release.

        // Create a new player
        player = YTSwiftyPlayer(
          frame: CGRect(x: 0, y: 0, width: 640, height: 480),
          playerVars: [
            .playsInline(true),
            .showRelatedVideo(false)
          ])

        // Enable auto playback when video is loaded
        player.autoplay = false
        
        // Set player view
        view.addSubview(player)
        NSLayoutConstraint.activate([
          NSLayoutConstraint(item: player!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0),
          NSLayoutConstraint(item: player!, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0),
          NSLayoutConstraint(item: player!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 640),
          NSLayoutConstraint(item: player!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 480)
        ])

        // Set delegate for detect callback information from the player
        player.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36"
        player.delegate = self
        
        // Load video player
        //        let config = GeneralPlayerConfiguration(videoID: "_6u6UrtXUEI",
        //                                                referrer: URL(string: "https://www.youtube.com"),
        //                                                viewportInitialScale: 1)
        let config = SmartEmbedsPlayerConfiguration(channelIDs: ["UC4SUWizzKc1tptprBkWjX2Q", "UCtYYXR3QV_1mKdJNksfCRtQ", "UCivB3CVSWoD5GEz6kTv2bGQ"],
                                                    referrer: URL(string: "https://www.scmp.com/news/china/politics/article/3084573/china-legislature-meets-set-tone-global-role-post-pandemic"),
                                                    viewportInitialScale: 1)
        player.loadPlayer(with: config)

        // (Optional) Create a new request for video list
        // Please make sure to set your API configuration in `AppDelegate`.
        let request = VideoListRequest(part: [.id, .snippet, .contentDetails], filter: .chart)
        
        // Send a request
        YoutubeAPI.shared.send(request) { result in
            switch result {
            case .success(let response):
                print(response)
            case .failed(let error):
                print(error)
            }
        }

    }
}

extension ViewController: YTSwiftyPlayerSmartEmbedsDelegate {
    
    func playerReady(_ player: YTSwiftyPlayer) {
        print(#function)
        // After loading a video, player's API is available.
        // e.g. player.mute()
    }
    
    func player(_ player: YTSwiftyPlayer, didUpdateCurrentTime currentTime: Double) {
        print("\(#function): \(currentTime)")
    }
    
    func player(_ player: YTSwiftyPlayer, didChangeState state: YTSwiftyPlayerState) {
        print("\(#function): \(state)")
    }
    
    func player(_ player: YTSwiftyPlayer, didChangePlaybackRate playbackRate: Double) {
        print("\(#function): \(playbackRate)")
    }
    
    func player(_ player: YTSwiftyPlayer, didReceiveError error: YTSwiftyPlayerError) {
        print("\(#function): \(error)")
    }
    
    func player(_ player: YTSwiftyPlayer, didChangeQuality quality: YTSwiftyVideoQuality) {
        print("\(#function): \(quality)")
    }
    
    func apiDidChange(_ player: YTSwiftyPlayer) {
        print(#function)
    }
    
    func youtubeIframeAPIReady(_ player: YTSwiftyPlayer) {
        print(#function)
    }
    
    func youtubeIframeAPIFailedToLoad(_ player: YTSwiftyPlayer) {
        print(#function)
    }

    func playerDidFindNoRecommendedVideos(_ player: YTSwiftyPlayer) {
        print(#function)
    }
}
