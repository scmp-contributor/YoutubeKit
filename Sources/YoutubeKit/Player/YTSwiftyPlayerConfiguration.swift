//
//  YTSwiftyPlayerConfiguration.swift
//  Pods-YoutubeKit_Example
//
//  Created by Ho Lun Wan on 19/5/2020.
//

import Foundation

public protocol YTSwiftyPlayerConfiguration {
  var referrer: URL? { get }
  var viewportInitialScale: CGFloat { get }

  func accept<VisitorType: YTSwiftyPlayerConfigurationVisitor>(visitor: VisitorType) -> VisitorType.ResultType
}

public struct GeneralPlayerConfiguration: YTSwiftyPlayerConfiguration {
  public let videoID: String
  public let referrer: URL?
  public let viewportInitialScale: CGFloat

  public init(videoID: String,
              referrer: URL? = nil,
              viewportInitialScale: CGFloat = 1) {
    self.videoID = videoID
    self.referrer = referrer ?? URL(string: "https://www.youtube.com")
    self.viewportInitialScale = viewportInitialScale
  }

  public func accept<VisitorType>(visitor: VisitorType) -> VisitorType.ResultType where VisitorType : YTSwiftyPlayerConfigurationVisitor {
    return visitor.forGeneralPlayer(self)
  }
}

// MARK: - Visitor

public protocol YTSwiftyPlayerConfigurationVisitor {
  associatedtype ResultType

  func forGeneralPlayer(_ configuration: GeneralPlayerConfiguration) -> ResultType
}
