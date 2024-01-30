//
//  YTSwiftyPlayerVideoIDProvider.swift
//  Pods-YoutubeKit_Example
//
//  Created by Ho Lun Wan on 19/5/2020.
//

import Foundation

struct YTSwiftyPlayerVideoIDProvider: YTSwiftyPlayerConfigurationVisitor {
  typealias ResultType = String?

  func forGeneralPlayer(_ configuration: GeneralPlayerConfiguration) -> String? {
    return configuration.videoID
  }

//  func forSmartEmbedsPlayer(_ configuration: SmartEmbedsPlayerConfiguration) -> String? {
//    return nil
//  }
}
