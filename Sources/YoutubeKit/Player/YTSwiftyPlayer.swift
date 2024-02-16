//
//  YTSwiftyPlayer.swift
//  YTSwiftyPlayer
//
//  Created by Ryo Ishikawa on 12/30/2017
//  Copyright © 2017 Ryo Ishikawa. All rights reserved.
//
import UIKit
import WebKit

/**
 * `YTSwiftyPlayer` is a subclass of `WKWebView` that support fully Youtube IFrame API.
 * It can be instantiated only programmatically.
 * - note: This class is not support interface builder due to use `WKWebView`.
 * For more information: [https://developer.apple.com/documentation/webkit/wkwebview](https://developer.apple.com/documentation/webkit/wkwebview)
 */
open class YTSwiftyPlayer: WKWebView {
    private class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
      weak var delegate: WKScriptMessageHandler?

      init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
      }

      func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
      }
    }

    /// The property for easily set auto playback.
    open var autoplay = false

    open weak var delegate: YTSwiftyPlayerDelegate?

    open private(set) var isMuted = false

    open private(set) var playbackRate: Double = 1.0

    open private(set) var availablePlaybackRates: [Double] = [1]

    open private(set) var availableQualityLevels: [YTSwiftyVideoQuality] = []

    open private(set) var bufferedVideoRate: Double = 0

    open private(set) var currentPlaylist: [String] = []

    open private(set) var currentPlaylistIndex: Int = 0

    open private(set) var currentVideoURL: String?

    open private(set) var currentVideoID: String?

    open private(set) var currentVideoTitle: String?

    open private(set) var currentVideoAuthor: String?

    open private(set) var currentVideoEmbedCode: String?

    open private(set) var playerState: YTSwiftyPlayerState = .unstarted

    open private(set) var playerQuality: YTSwiftyVideoQuality = .unknown

    open private(set) var duration: Double?

    open private(set) var currentTime: Double = 0.0

    public private(set) var currentPlayerConfiguration: YTSwiftyPlayerConfiguration?

    private var playerVars: [String: AnyObject] = [:]

    open var customTargeting: [String: String] = [:]

    private var adTag: String?

    private let callbackHandlers: [YTSwiftyPlayerEvent] = [
        .onYoutubeIframeAPIReady,
        .onYouTubeIframeAPIFailedToLoad,
        .onReady,
        .onStateChange,
        .onQualityChange,
        .onPlaybackRateChange,
        .onApiChange,
        .onError,
        .onUpdateCurrentTime,
        .onVideosNotFoundForSmartEmbeds
    ]
    static private var defaultConfiguration: WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = false
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = false
        return config
    }

  public init(frame: CGRect = .zero, playerVars: [String: AnyObject], adTag: String?, customTargeting: [String : String]) {
        let config = YTSwiftyPlayer.defaultConfiguration
        if let allowsInlineStr = playerVars[VideoEmbedParameter.playsInline(false).key] as? String, allowsInlineStr == "0" {
          config.allowsInlineMediaPlayback = false
        }

        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        super.init(frame: frame, configuration: config)

        // inject JS to capture console.log output and send to iOS
        let source = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        self.configuration.userContentController.addUserScript(script)
        // register the bridge script that listens for the output
        self.configuration.userContentController.add(self, name: "logHandler")

        callbackHandlers.forEach {
            userContentController.add(ScriptMessageHandler(delegate: self), name: $0.rawValue)
        }

        commonInit()

        self.playerVars = playerVars
        self.adTag = adTag
        self.customTargeting = customTargeting
    }

  public convenience init(frame: CGRect = .zero, playerVars: [VideoEmbedParameter] = [], adTag: String? = nil, customTargeting: [String : String]) {
      self.init(
        frame: frame,
        playerVars: YTSwiftyPlayer.convertPlayerParameters(playerVars),
        adTag: adTag,
        customTargeting: customTargeting)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setPlayerParameters(_ parameters: [String: AnyObject]) {
        self.playerVars = parameters
    }

    public func setPlayerParameters(_ parameters: [VideoEmbedParameter]) {
        self.playerVars = YTSwiftyPlayer.convertPlayerParameters(parameters)
    }

    public func playVideo() {
        evaluatePlayerCommand("playVideo()")
    }

    public func stopVideo() {
        evaluatePlayerCommand("stopVideo()")
    }

    public func seek(to seconds: Int, allowSeekAhead: Bool) {
        evaluatePlayerCommand("seekTo(\(seconds),\(allowSeekAhead ? 1 : 0))")
    }

    public func pauseVideo() {
        evaluatePlayerCommand("pauseVideo()")
        evaluateJavaScript("imaManager.getAdsManager().getRemainingTime() > 0") { [weak self] (result, error) in
            if error == nil {
                self?.evaluateJavaScript("imaManager.getAdsManager().pause()")
            }
        }
    }

    public func clearVideo() {
        evaluatePlayerCommand("clearVideo()")
    }

    public func mute() {
        evaluatePlayerCommand("mute()") { [weak self] result in
            guard result != nil else { return }
            self?.isMuted = true
        }
    }

    public func unMute() {
        evaluatePlayerCommand("unMute()") { [weak self] result in
            guard result != nil else { return }
            self?.isMuted = false
        }
    }

    public func setVolume(_ volume: Int) {
        evaluatePlayerCommand(String(format: "setVolume(%d)", min(100, max(0, volume))))
    }

    public func previousVideo() {
        evaluatePlayerCommand("previousVideo()")
    }

    public func nextVideo() {
        evaluatePlayerCommand("nextVideo()")
    }

    public func playVideo(at index: Int) {
        evaluatePlayerCommand("playVideoAt(\(index))")
    }

    public func setPlayerSize(width: Int, height: Int) {
        evaluatePlayerCommand("setSize(\(width),\(height))")
    }

    public func setPlaybackRate(_ suggestedRate: Double) {
        evaluatePlayerCommand("setPlaybackRate(\(suggestedRate))")
    }

    public func setPlaybackQuality(_ suggestedQuality: YTSwiftyVideoQuality) {
        evaluatePlayerCommand("setPlaybackQuality(\(suggestedQuality.rawValue))")
    }

    public func setLoop(_ loopPlaylists: Bool) {
        evaluatePlayerCommand("setLoop(\(loopPlaylists))")
    }

    public func setShuffle(_ shufflePlaylist: Bool) {
        evaluatePlayerCommand("setShuffle(\(shufflePlaylist))")
    }

    public func cueVideo(videoID: String, startSeconds: Int = 0, suggestedQuality: YTSwiftyVideoQuality = .large) {
        evaluatePlayerCommand("cueVideoById('\(videoID)',\(startSeconds),'\(suggestedQuality.rawValue)')")
    }

    public func loadVideo(videoID: String, startSeconds: Int = 0, suggestedQuality: YTSwiftyVideoQuality = .large) {
        evaluatePlayerCommand("loadVideoById('\(videoID)',\(startSeconds),'\(suggestedQuality.rawValue)')")
    }

    public func cueVideo(contentURL: String, startSeconds: Int = 0, suggestedQuality: YTSwiftyVideoQuality = .large) {
        evaluatePlayerCommand("cueVideoByUrl('\(contentURL)',\(startSeconds),'\(suggestedQuality.rawValue)')")
    }

    public func loadVideo(contentURL: String, startSeconds: Int = 0, suggestedQuality: YTSwiftyVideoQuality = .large) {
        evaluatePlayerCommand("loadVideoByUrl('\(contentURL)',\(startSeconds),'\(suggestedQuality.rawValue)')")
    }

    public func cuePlaylist(playlist: [String], startIndex: Int = 0, startSeconds: Int = 0, suggestedQuality: YTSwiftyVideoQuality = .large) {
        evaluatePlayerCommand("cuePlaylist('\(playlist.joined(separator: ","))',\(startIndex),\(startSeconds),'\(suggestedQuality.rawValue)')")
    }

    public func loadPlaylist(playlist: [String], startIndex: Int = 0, startSeconds: Int = 0, suggestedQuality: YTSwiftyVideoQuality = .large) {
        evaluatePlayerCommand("loadPlaylist('\(playlist.joined(separator: ","))',\(startIndex),\(startSeconds),'\(suggestedQuality.rawValue)')")
    }

    public func loadPlaylist(withVideoIDs ids: [String]) {
        evaluatePlayerCommand("loadPlaylist('\(ids.joined(separator: ","))')")
    }

    public func loadPlayer(with playerConfiguration: YTSwiftyPlayerConfiguration) {
      print("[YTSwiftyPlayer] loadPlayer customTargeting: \(self.customTargeting)")

        let events: [String: AnyObject] = {
            var registerEvents: [String: AnyObject] = [:]
          callbackHandlers.forEach {
            registerEvents[$0.rawValue] = $0.rawValue as AnyObject
          }
          return  registerEvents
        }()

        let embedConfig = playerConfiguration.accept(visitor: YTSwiftyPlayerEmbedConfig(adTagPrefix: adTag))

        var parameters = [
            "width": "100%" as AnyObject,
            "height": "100%" as AnyObject,
            "events": events as AnyObject,
            "playerVars": playerVars as AnyObject,
            "embedConfig": embedConfig as AnyObject,
            ]

        if let videoID = playerConfiguration.accept(visitor: YTSwiftyPlayerVideoIDProvider()) {
            parameters["videoId"] = videoID as AnyObject
        }
      print("[YTSwiftyPlayer] playerVars: \(playerVars)")

        let htmlProvider = YTSwiftyPlayerHTMLProvider(
          playerOptions: parameters,
          playerParameters: playerVars,
          embedConfigParameters: embedConfig ?? [:])
        guard let html = playerConfiguration.accept(visitor: htmlProvider) else { return }
      var htmlString = html.replacingOccurrences(of: YTSwiftyPlayerHTMLProvider.ReplacementKeys.adTag,
                                                 with: self.adTag ?? "")
      htmlString = htmlString.replacingOccurrences(of: YTSwiftyPlayerHTMLProvider.ReplacementKeys.custParams,
                                             with: self.customTargetingString)
        currentPlayerConfiguration = playerConfiguration
        loadHTMLString(htmlString, baseURL: playerConfiguration.referrer)
    }

    // MARK: - Private Methods

  private var customTargetingString: String {

    let articletype = customTargeting["articletype"] ?? ""
    let paid = customTargeting["paid"] ?? ""
    let scnid = customTargeting["scnid"] ?? ""
    let scsid = customTargeting["scsid"] ?? ""
    let sctid = customTargeting["sctid"] ?? ""
    let sentiment_max = customTargeting["sentiment_max"] ?? ""
    let sentiment_min = customTargeting["sentiment_min"] ?? ""
    let avg_first_second = customTargeting["avg_first_second"] ?? ""
    let avg_sent_1_5 = customTargeting["avg_sent_1_5"] ?? ""
    let headline_score = customTargeting["headline_score"] ?? ""
    let sentiment_category = customTargeting["sentiment_category"] ?? ""
    let readability_school_level = customTargeting["readability_school_level"] ?? ""
    let gs_adult = customTargeting["gs_adult"] ?? ""
    let gs_hkprotests = customTargeting["gs_hkprotests"] ?? ""
    let gs_violence = customTargeting["gs_violence"] ?? ""
    let gs_terrorism = customTargeting["gs_terrorism"] ?? ""
    let gs_tobacco = customTargeting["gs_tobacco"] ?? ""
    let gs_tragedy = customTargeting["gs_tragedy"] ?? ""
    let gs_offensive_language = customTargeting["gs_offensive_language"] ?? ""
    let gs_client1 = customTargeting["gs_client1"] ?? ""
    let gs_client2 = customTargeting["gs_client2"] ?? ""
    let gs_client3 = customTargeting["gs_client3"] ?? ""
    let ga_id = customTargeting["ga_id"] ?? ""
    let uuid = customTargeting["uuid"] ?? ""
    let yt_embed_ima = customTargeting["yt_embed_ima"] ?? ""
    let mappedString =  "articletype=\(articletype)&paid=\(paid)&scnid=\(scnid)&scsid=\(scsid)&sctid=\(sctid)&sentiment_max=\(sentiment_max)&sentiment_min=\(sentiment_min)&avg_first_second=\(avg_first_second)&avg_sent_1_5=\(avg_sent_1_5)&headline_score=\(headline_score)&sentiment_category=\(sentiment_category)&readability_school_level=\(readability_school_level)&gs_adult=\(gs_adult)&gs_hkprotests=\(gs_hkprotests)&gs_violence=\(gs_violence)&gs_terrorism=\(gs_terrorism)&gs_tobacco=\(gs_tobacco)&gs_tragedy=\(gs_tragedy)&gs_offensive_language=\(gs_offensive_language)&gs_client1=\(gs_client1)&gs_client2=\(gs_client2)&gs_client3=\(gs_client3)&ga_id=\(ga_id)&uuid=\(uuid)&yt_embed_ima=\(yt_embed_ima)"

    return mappedString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
  }

    private func commonInit() {
        scrollView.bounces = false
        scrollView.isScrollEnabled = false
        isUserInteractionEnabled = true
        translatesAutoresizingMaskIntoConstraints = false
    }

    // Evaluate javascript command and convert to simple error(nil) if an error is occurred.
    private func evaluatePlayerCommand(_ commandName: String, callbackHandler: ((Any?) -> ())? = nil) {
        let command = "player.\(commandName);"
        evaluateJavaScript(command) { (result, error) in
            if error != nil {
                callbackHandler?(nil)
                return
            }
            callbackHandler?(result)
        }
    }

  private static func convertPlayerParameters(_ parameters: [VideoEmbedParameter]) -> [String: AnyObject] {
      var params: [String: AnyObject] = [:]
      parameters.forEach {
          let property = $0.property
          params[property.key] = property.value
      }
      return params
  }
}

extension YTSwiftyPlayer: WKScriptMessageHandler {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      if message.name == "logHandler" {
        print("[YTSwiftyPlayer] console.log: \(message.body)")
        return
      }
        guard let event = YTSwiftyPlayerEvent(rawValue: message.name) else { return }
        print("[YTSwiftyPlayer] didReceive event: \(event)")

        switch event {
        case .onReady:
            // Mute initially if specified
            if currentPlayerConfiguration?.isMuted ?? false {
              mute()
            }

            delegate?.playerReady(self)

            // The HTML5 video element, in certain mobile browsers, only allows playback to take place if it's initiated by a user interaction, due to this restriction, functions and parameters such as autoplay, playVideo(), loadVideoById() won't work in all mobile environments.
            // So it have to call explicit `playVideo()` to work autoplay in mobile environment.
            if autoplay || playerVars.contains(where: { $0.key == "autoplay" && String(describing: $0.value) == "1" }) {
                playVideo()
            }
            updateInfo()
        case .onStateChange:
            updateState(message.body as? Int)
            updateVideoData()
            let isLoop = playerVars["loop"] as? String == "1"
            if playerState == .ended && isLoop {
                playVideo()
            }
            delegate?.player(self, didChangeState: playerState)
            if playerState == .playing {
                NotificationCenter.default.post(name: .ytSwiftyPlayerDidPlaying, object: nil, userInfo: ["player": self])
            }
          print("[YTSwiftyPlayer] didReceive event playerState: \(playerState)")
        case .onQualityChange:
            updateQuality(message.body as? String)
            delegate?.player(self, didChangeQuality: playerQuality)
        case .onError:
            if let message = message.body as? Int,
                let error = YTSwiftyPlayerError(rawValue: message) {
                delegate?.player(self, didReceiveError: error)
            }
        case .onUpdateCurrentTime:
            updateInfo()
            if let currentTime = message.body as? Double {
                self.currentTime = currentTime
                delegate?.player(self, didUpdateCurrentTime: currentTime)
            }
        case .onPlaybackRateChange:
            if let playbackRate = message.body as? Double {
                delegate?.player(self, didChangePlaybackRate: playbackRate)
            }
        case .onApiChange:
            delegate?.apiDidChange(self)
        case .onYoutubeIframeAPIReady:
            delegate?.youtubeIframeAPIReady(self)
        case .onYouTubeIframeAPIFailedToLoad:
            delegate?.youtubeIframeAPIFailedToLoad(self)
        case .onVideosNotFoundForSmartEmbeds:
            (delegate as? YTSwiftyPlayerSmartEmbedsDelegate)?.playerDidFindNoRecommendedVideos(self)
        }
    }

    // MARK: - Private Methods

    private func updateInfo() {
        updateMute()
        updatePlaybackRate()
        updateAvailableQualityLevels()
        updateCurrentPlaylist()
        updateCurrentVideoURL()
        updateCurrentVideoEmbedCode()
        updatePlaylistIndex()
        updateDuration()
        updateVideoLoadedFraction()
        updateVideoData()
    }

    private func updateMute() {
        evaluatePlayerCommand("isMuted()") { [weak self] result in
            guard let me = self,
                let isMuted = result as? Bool else { return }
            me.isMuted = isMuted
        }
    }

    private func updatePlaybackRate() {
        evaluatePlayerCommand("getPlaybackRate()") { [weak self] result in
            guard let me = self,
                let playbackRate = result as? Double else { return }
            me.playbackRate = playbackRate
        }
    }

    private func updateVideoLoadedFraction() {
        evaluatePlayerCommand("getVideoLoadedFraction()") { [weak self] result in
            guard let me = self,
                let bufferedVideoRate = result as? Double else { return }
            me.bufferedVideoRate = bufferedVideoRate
        }
    }

    private func updateAvailableQualityLevels() {
        evaluatePlayerCommand("getAvailableQualityLevels()") { [weak self] result in
            guard let me = self,
                let availableQualityLevels = result as? [String] else { return }
            me.availableQualityLevels = availableQualityLevels
              .compactMap { YTSwiftyVideoQuality(rawValue: $0) }
        }
    }

    private func updateCurrentVideoURL() {
        evaluatePlayerCommand("getVideoUrl()") { [weak self] result in
            guard let me = self,
                let url = result as? String else { return }
            me.currentVideoURL = url
        }
    }

    private func updateCurrentVideoEmbedCode() {
        evaluatePlayerCommand("getVideoEmbedCode()") { [weak self] result in
            guard let me = self,
                let embedCode = result as? String else { return }
            me.currentVideoEmbedCode = embedCode
        }
    }

    private func updateCurrentPlaylist() {
        evaluatePlayerCommand("getPlaylist()") { [weak self] result in
            guard let me = self,
                let playlist = result as? [String] else { return }
            me.currentPlaylist = playlist
        }
    }

    private func updatePlaylistIndex() {
        evaluatePlayerCommand("getPlaylistIndex()") { [weak self] result in
            guard let me = self,
                let index = result as? Int else { return }
            me.currentPlaylistIndex = index
        }
    }

    private func updateDuration() {
        evaluatePlayerCommand("getDuration()") { [weak self] result in
            guard let me = self,
                let duration = result as? Double else { return }
            me.duration = duration
        }
    }

    private func updateState(_ message: Int?) {
        var state: YTSwiftyPlayerState = .unstarted
        if let message = message,
            let newState = YTSwiftyPlayerState(rawValue: message) {
            state = newState
        }
        playerState = state
    }

    private func updateQuality(_ message: String?) {
        var quality: YTSwiftyVideoQuality = .unknown
        if let message = message,
            let newQuality = YTSwiftyVideoQuality(rawValue: message) {
            quality = newQuality
        }
        playerQuality = quality
    }

    private struct VideoDataKeys {
      static let title = "title"
      static let id = "video_id"
      static let author = "author"
    }
    private func updateVideoData() {
      evaluatePlayerCommand("getVideoData()", callbackHandler: { [weak self] result in
        if let val = result as? [String: Any] {
          self?.currentVideoTitle = val[VideoDataKeys.title] as? String
          self?.currentVideoID = val[VideoDataKeys.id] as? String
          self?.currentVideoAuthor = val[VideoDataKeys.author] as? String
        }
      })
    }
}
