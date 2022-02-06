//
//  PlayerManager.swift
//  AVPlayerProject
//
//  Created by Ray Migneco on 2/6/22.
//

import Foundation
import AVFoundation


fileprivate class PlaybackContext {}


protocol PlayerManagerObservable: AnyObject {
    func managerIsReadyToPlay(_ manager: PlayerManager)
    func managerDidFail(_ manager: PlayerManager, with error: Error?)
    func managerStatusUnknown(_ manager: PlayerManager)
    func managerFailedToLoadResource(message: String)
}

// TODO add some functions play/pause

final class PlayerManager: NSObject {
    
    private var playerItemContext = PlaybackContext()
    private var playerContext = PlaybackContext()
    
    static let shared = PlayerManager()
    
    private let player: AVPlayer
    
    weak var delegate: PlayerManagerObservable?
    
    private var playerStatus: AVPlayer.Status = .unknown {
        didSet {
            switch playerStatus {
            case .readyToPlay:
                delegate?.managerIsReadyToPlay(self)
            case .failed:
                delegate?.managerDidFail(self, with: player.error)
            case .unknown:
                fallthrough
            @unknown default:
                delegate?.managerStatusUnknown(self)
            }
        }
    }
    
    private override init() {
        self.player = AVPlayer(playerItem: nil)
        
        super.init()
        
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new], context: &playerContext)
    }
    
    func loadInitialResource() {
        guard let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8") else {
            delegate?.managerFailedToLoadResource(message: "Invalid URL")
            return
        }
        
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: &playerItemContext)
    }
    
    /// MARK: Playback controls
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    /// MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &playerItemContext {
            playerItemObservedValue(forKeyPath: keyPath, of: object, change: change)
        }
        else if context == &playerContext {
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
    }
    
    func playerItemObservedValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            
            if let val = change?[.newKey] as? NSNumber,
             let newStatus = AVPlayerItem.Status(rawValue: val.intValue) {
                status = newStatus
            }
            else {
                status = .unknown
            }
            
            switch status {
            case .readyToPlay:
                print("Item is ready for playback")
            case .failed:
                print("Item No longer plays due to error")
            case .unknown:
                fallthrough
            @unknown default:
                print("Item status is unknown")
            }
        }
    }
}


// MARK: Observers
