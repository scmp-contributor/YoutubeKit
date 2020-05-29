//
//  YTSwiftyPlayerSmartEmbedsDelegate.swift
//  Pods-YoutubeKit_Example
//
//  Created by Ho Lun Wan on 29/5/2020.
//

import Foundation

public protocol YTSwiftyPlayerSmartEmbedsDelegate: YTSwiftyPlayerDelegate {
  /**
    API calls this function when no recommended videos are found.

   - parameters:
      - player: The current active player instance.
   */
  func playerDidFindNoRecommendedVideos(_ player: YTSwiftyPlayer)
}

extension YTSwiftyPlayerSmartEmbedsDelegate {
  func playerDidFindNoRecommendedVideos(_ player: YTSwiftyPlayer) {}
}
