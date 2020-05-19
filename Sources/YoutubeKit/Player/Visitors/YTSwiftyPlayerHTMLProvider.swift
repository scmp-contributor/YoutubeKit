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
    static let playerParameters = "{player-parameters}"
    static let viewportInitialScale = "{viewport-initial-scale}"
  }

  let playerParameters: [String: AnyObject]

  func forGeneralPlayer(_ configuration: GeneralPlayerConfiguration) -> String? {
    guard var htmlString = YTSwiftyPlayerHTMLProvider.getHTMLString(forName: "player") else { return nil }

    do {
      let json = try JSONSerialization.data(withJSONObject: playerParameters, options: [])
      guard let jsonString = String(data: json, encoding: String.Encoding.utf8) else { return nil }

      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.playerParameters, with: jsonString)
      htmlString = htmlString.replacingOccurrences(of: ReplacementKeys.viewportInitialScale, with: String(format: "%.2f", configuration.viewportInitialScale))
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
