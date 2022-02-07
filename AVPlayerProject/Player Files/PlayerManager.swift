//
//  PlayerManager.swift
//  AVPlayerProject
//
//  Created by Ray Migneco on 2/6/22.
//

import Foundation
import AVFoundation



enum PlayerState {
    case ready
    case unknown
    case failed(Error?)
}


protocol PlayerManagerObservable: AnyObject {
    
    func manager(_ manager: PlayerManager, stateChangedTo state: PlayerState)
    
    func manager(_ manager: PlayerManager, failedToLoadResource message: String)
    
    func manager(_ manager: PlayerManager, playbackStateChangedTo isPlaying: Bool)
    
    func manager(_ manager: PlayerManager, didUpdatePlaybackPosition time: Float64)
}

final class PlayerManager: NSObject {
    
    static let shared = PlayerManager()
    
    private var playerContext: Int = 0
    private var timeObserverToken: Any?
    
    private let player: AVPlayer
    
    weak var delegate: PlayerManagerObservable?
    
    private(set) var playerStatus: AVPlayer.Status = .unknown {
        didSet {
            switch playerStatus {
            case .readyToPlay:
                delegate?.manager(self, stateChangedTo: .ready)
            case .failed:
                delegate?.manager(self, stateChangedTo: .failed(player.error))
            case .unknown:
                fallthrough
            @unknown default:
                delegate?.manager(self, stateChangedTo: .unknown)
            }
        }
    }
    
    private(set) var isPlaying: Bool = false {
        didSet {
            delegate?.manager(self, playbackStateChangedTo: isPlaying)
        }
    }
    
    private override init() {
        self.player = AVPlayer(playerItem: nil)
        
        super.init()
        
        configureObservers()
    }
    
    func loadInitialResource() {
        let urlString = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        guard let url = URL(string: urlString) else {
            delegate?.manager(self, failedToLoadResource: "Invalid URL: " + urlString)
            
            return
        }
        
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
    }
    
    // MARK: Playback controls
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    private func configureObservers() {
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new], context: &playerContext)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.new], context: &playerContext)
        
        // set up periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let token = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] cmTime in
            guard let self = self else { return }
            
            self.delegate?.manager(self, didUpdatePlaybackPosition: CMTimeGetSeconds(cmTime))
        }
        
        timeObserverToken = token
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &playerContext {
            playerObservedValue(forKeyPath: keyPath, of: object, change: change)
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}


fileprivate extension PlayerManager {
    
    func playerObservedValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        if keyPath == #keyPath(AVPlayer.status) {
            if let val = change?[.newKey] as? NSNumber,
                let newStatus = AVPlayer.Status(rawValue: val.intValue) {
                playerStatus = newStatus
            }
            else {
                playerStatus = .unknown
            }
        }
        if keyPath == #keyPath(AVPlayer.rate) {
            if let val = change?[.newKey] as? NSNumber {
                let rate = val.floatValue
                isPlaying = rate != 0.0
            }
        }
    }
}

/*
 Note: I wanted to implement this with closure-based KVO but there seems to be a bug with enum's using this approach
 https://bugs.swift.org/browse/SR-5872
 There are some work-arounds but it seemed best to stick with the typical approach to observing with functions
 */
