//
//  YTSwiftyPlayerHTMLProvider.swift
//  Pods-YoutubeKit_Example
//
//  Created by Ho Lun Wan on 19/5/2020.
//

import Foundation

struct YTSwiftyPlayerHTMLProvider: YTSwiftyPlayerConfigurationVisitor {
  typealias ResultType = String?

  private struct ReplacementKeys {
    static let videoId = "{video-id}"
    static let playerOptions = "{player-options}"
    static let viewportInitialScale = "{viewport-initial-scale}"
    static let iframeSrcQueryString = "{iframe-src-query-string}"
    static let getCurrentTimeInterval = "'{get-current-time-interval}'"
  }

  let playerOptions: [String: AnyObject]
  let playerParameters: [String: AnyObject]

  func forGeneralPlayer(_ configuration: GeneralPlayerConfiguration) -> String? {
    guard var htmlString = YTSwiftyPlayerHTMLProvider.getHTMLString(forName: "player") else { return nil }

    do {
      let json = try JSONSerialization.data(withJSONObject: playerOptions, options: [])
      guard let jsonString = String(data: json, encoding: String.Encoding.utf8) else { return nil }

		htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.videoId, with: configuration.videoID)
      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.playerOptions, with: jsonString)
      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.viewportInitialScale, with: String(format: "%.2f", configuration.viewportInitialScale))
      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.getCurrentTimeInterval, with: String(format: "%.1f", configuration.getCurrentTimeSchedulerInterval * 1000))
		
      // Create query strings for the iframe src url
      var paramsForQueryStrings = playerParameters.filter({ key, val in
        return key == VideoEmbedParameter.playsInline(true).key || key == VideoEmbedParameter.autoplay(true).key
      })

      // Set enable js api
      paramsForQueryStrings["enablejsapi"] = true as AnyObject

      var urlComponents = URLComponents()
      var queryItems: [URLQueryItem] = paramsForQueryStrings.map({ URLQueryItem(name: $0.0, anyObjectValue: $0.1) })
      queryItems.append(contentsOf: configuration.extraQueries.map({ key, val in
        URLQueryItem(name: key, value: val)
      }))      
      urlComponents.queryItems = queryItems
      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.iframeSrcQueryString, with: urlComponents.query ?? "")

		return htmlString
    } catch {
      return nil
    }
  }

  func forSmartEmbedsPlayer(_ configuration: SmartEmbedsPlayerConfiguration) -> String? {
    guard var htmlString = YTSwiftyPlayerHTMLProvider.getHTMLString(forName: "smart-embeds-player") else { return nil }

    do {
      let json = try JSONSerialization.data(withJSONObject: playerOptions, options: [])
      guard let jsonString = String(data: json, encoding: String.Encoding.utf8) else { return nil }

      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.playerOptions, with: jsonString)
      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.viewportInitialScale, with: String(format: "%.2f", configuration.viewportInitialScale))
      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.getCurrentTimeInterval, with: String(format: "%.1f", configuration.getCurrentTimeSchedulerInterval * 1000))

      // Create query strings for the iframe src url
      var paramsForQueryStrings = playerParameters.filter({ key, val in
        return key == VideoEmbedParameter.playsInline(true).key || key == VideoEmbedParameter.autoplay(true).key
      })

      // Set enable js api
      paramsForQueryStrings["enablejsapi"] = true as AnyObject

      // Set channel IDs
      paramsForQueryStrings["channels"] = configuration.channelIDs.joined(separator: ",") as AnyObject

      // Set blocked video IDs
      if !configuration.blockedVideoIDs.isEmpty {
        paramsForQueryStrings["block_videos"] = configuration.blockedVideoIDs.joined(separator: ",") as AnyObject
      }

      var urlComponents = URLComponents()
      urlComponents.queryItems = paramsForQueryStrings.map({ URLQueryItem(name: $0.0, anyObjectValue: $0.1) })
      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.iframeSrcQueryString, with: urlComponents.query ?? "")

      return htmlString
    } catch {
      return nil
    }
  }

  private static func getHTMLString(forName name: String) -> String? {
    let currentBundle = Bundle(for: YTSwiftyPlayer.self)
    let path = currentBundle.path(forResource: name, ofType: "html")!

    do {
      let htmlString = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
      return htmlString
    } catch {
      return nil
    }
  }
}

private extension URLQueryItem {
  init(name: String, anyObjectValue: AnyObject) {
    let value: String?
    if let val = anyObjectValue as? String {
      value = val
    } else if let val = anyObjectValue as? Bool {
      value = val ? "1" : "0"
    } else if let val = anyObjectValue as? Int {
      value = String(format: "%d", val)
    } else if let val = anyObjectValue as? Double {
      value = String(format: "%.2f", val)
    } else {
      value = nil
    }

    self.init(name: name, value: value)
  }
}
