//
//  YTSwiftyPlayerIUValue.swift
//  YoutubeKit
//
//  Created by Eric Leung on 4/3/2021.
//

import Foundation

struct YTSwiftyPlayerEmbedConfig: YTSwiftyPlayerConfigurationVisitor {
  typealias ResultType = [String: AnyObject]?
  let adTagPrefix: String?

  func forGeneralPlayer(_ configuration: GeneralPlayerConfiguration) -> [String: AnyObject]? {
    let iu: String
    if let prefix = adTagPrefix {
      iu = "\(prefix)/instream1"
    } else {
      iu = ""
    }

    let adTagParams: [String: String] = [
      "iu": iu
    ]
    let adConfig = [
      "adTagParameters": adTagParams,
      "nonPersonalizedAd": true
    ] as AnyObject
    return ["adsConfig": adConfig]
  }

  func forSmartEmbedsPlayer(_ configuration: SmartEmbedsPlayerConfiguration) -> [String: AnyObject]? {
    let iu: String
    if let prefix = adTagPrefix {
      iu = "\(prefix)/instream2"
    } else {
      iu = ""
    }

    let adTagParams: [String: String] = [
      "iu": iu
    ]
    let adConfig = [
      "adTagParameters": adTagParams,
      "nonPersonalizedAd": true
    ] as AnyObject
    return ["adsConfig": adConfig]
  }
}
