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
  var getCurrentTimeSchedulerInterval: TimeInterval { get }
  var isMuted: Bool { get }

  func accept<VisitorType: YTSwiftyPlayerConfigurationVisitor>(visitor: VisitorType) -> VisitorType.ResultType
}

// MARK: -

public struct GeneralPlayerConfiguration: YTSwiftyPlayerConfiguration {
  public let videoID: String
  public let referrer: URL?
  public let viewportInitialScale: CGFloat
  public let getCurrentTimeSchedulerInterval: TimeInterval
  public let isMuted: Bool

  public init(videoID: String,
              referrer: URL? = nil,
              viewportInitialScale: CGFloat = 1,
              getCurrentTimeSchedulerInterval: TimeInterval = 0.5,
              isMuted: Bool = false) {
    self.videoID = videoID
    self.referrer = referrer ?? URL(string: "https://www.youtube.com")
    self.viewportInitialScale = viewportInitialScale
    self.getCurrentTimeSchedulerInterval = getCurrentTimeSchedulerInterval
    self.isMuted = isMuted
  }

  public func accept<VisitorType>(visitor: VisitorType) -> VisitorType.ResultType where VisitorType : YTSwiftyPlayerConfigurationVisitor {
    return visitor.forGeneralPlayer(self)
  }
}

// MARK: -

public struct SmartEmbedsPlayerConfiguration: YTSwiftyPlayerConfiguration {
  public let channelIDs: [String]
  public let blockedVideoIDs: [String]
  public let referrer: URL?
  public let viewportInitialScale: CGFloat
  public let getCurrentTimeSchedulerInterval: TimeInterval
  public let isMuted: Bool

  public init(channelIDs: [String],
              blockedVideoIDs: [String] = [],
              referrer: URL? = nil,
              viewportInitialScale: CGFloat = 1,
              getCurrentTimeSchedulerInterval: TimeInterval = 0.5,
              isMuted: Bool = false) {
    self.channelIDs = channelIDs
    self.blockedVideoIDs = blockedVideoIDs
    self.referrer = referrer ?? URL(string: "https://www.youtube.com")
    self.viewportInitialScale = viewportInitialScale
    self.getCurrentTimeSchedulerInterval = getCurrentTimeSchedulerInterval
    self.isMuted = isMuted
  }

  public func accept<VisitorType>(visitor: VisitorType) -> VisitorType.ResultType where VisitorType : YTSwiftyPlayerConfigurationVisitor {
    return visitor.forSmartEmbedsPlayer(self)
  }
}

// MARK: - Visitor

public protocol YTSwiftyPlayerConfigurationVisitor {
  associatedtype ResultType

  func forGeneralPlayer(_ configuration: GeneralPlayerConfiguration) -> ResultType
  func forSmartEmbedsPlayer(_ configuration: SmartEmbedsPlayerConfiguration) -> ResultType
}
