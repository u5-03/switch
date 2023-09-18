//
//  TextReaderManager.swift
//  Switch
//
//  Created by Yugo Sugiyama on 2023/09/18.
//

import Foundation
import AVFoundation

final class TextReaderManager: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Error>?

    private override init() {
        super.init()
        setUp()
    }
    static let shared = TextReaderManager()

    private func setUp() {
        #if os(iOS)
        // サイレントモード中でも音を鳴らす
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif
        synthesizer.delegate = self
    }

    func read(text: String) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            if self.continuation != nil {
                continuation.resume(throwing: "not complete previous session")
            }
            let utterance = AVSpeechUtterance(string: text)
            let voice = AVSpeechSynthesisVoice(language: "ja-JP")
            utterance.voice = voice
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            self.continuation = continuation
            synthesizer.speak(utterance)
        }
    }
}

extension TextReaderManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        continuation?.resume(returning: ())
        continuation = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        continuation?.resume(throwing: "Did Cancel")
        continuation = nil
    }
}
