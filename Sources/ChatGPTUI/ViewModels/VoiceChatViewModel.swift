import AVFoundation
import Foundation
import Observation
import ChatGPTSwift
import SwiftUI

public typealias ChatResponse = MessageRowType

@Observable
open class VoiceChatViewModel<CustomContent: View>: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
        
    let api: ChatGPTAPI
    public var model: ChatGPTModel
    public var systemText: String
    public var temperature: Double
    
    public var state: VoiceChatState<CustomContent> = .idle(nil) {
        didSet {
            #if DEBUG
            print(state)
            #endif
        }
    }
    
    public var response: ChatResponse<CustomContent>? {
        state.idleResponse ?? state.playingSpeechResponse
    }
    
    var selectedVoice = VoiceType.alloy
    var audioPlayer: AVAudioPlayer!
    var audioRecorder: AVAudioRecorder!
    #if !os(macOS)
    var recordingSession = AVAudioSession.sharedInstance()
    #endif
    var animationTimer: Timer?
    var recordingTimer: Timer?
    var audioPower = 0.0
    var prevAudioPower: Double?
    public var processingSpeechTask: Task<Void, Never>?
    
    var captureURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("recording.m4a")
    }
    
    public init(voiceType: VoiceType = .alloy, model: ChatGPTModel = .gpt_hyphen_4o, systemText: String = "You're a helpful assistant", temperature: Double = 0.6, apiKey: String) {
        self.selectedVoice = voiceType
        self.model = model
        self.systemText = systemText
        self.temperature = temperature
        self.api = ChatGPTAPI(apiKey: apiKey)
        super.init()
        #if !os(macOS)
        do {
            #if os(iOS)
            try recordingSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            #else
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            #endif
            try recordingSession.setActive(true)
            
            AVAudioApplication.requestRecordPermission { [unowned self] allowed in
                if !allowed {
                    self.state = .error("Recording not allowed by the user")
                }
            }
        } catch {
            state = .error(error)
        }
        #endif
    }
    
    open func startCaptureAudio() {
        resetValues()
        state = .recordingSpeech
        do {
            audioRecorder = try AVAudioRecorder(url: captureURL,
                                                settings: [
                                                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                                    AVSampleRateKey: 12000,
                                                    AVNumberOfChannelsKey: 1,
                                                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                                                ])
            audioRecorder.isMeteringEnabled = true
            audioRecorder.delegate = self
            audioRecorder.record()
            
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [unowned self]_ in
                guard self.audioRecorder != nil else { return }
                self.audioRecorder.updateMeters()
                let power = min(1, max(0, 1 - abs(Double(self.audioRecorder.averagePower(forChannel: 0)) / 50) ))
                self.audioPower = power
            })
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true, block: { [unowned self]_ in
                guard self.audioRecorder != nil else { return }
                self.audioRecorder.updateMeters()
                let power = min(1, max(0, 1 - abs(Double(self.audioRecorder.averagePower(forChannel: 0)) / 50) ))
                if self.prevAudioPower == nil {
                    self.prevAudioPower = power
                    return
                }
                if let prevAudioPower = self.prevAudioPower, prevAudioPower < 0.25 && power < 0.175 {
                    self.finishCaptureAudio()
                    return
                }
                self.prevAudioPower = power
            })
            
        } catch {
            resetValues()
            state = .error(error)
        }
    }
    
    open func finishCaptureAudio() {
        resetValues()
        do {
            let data = try Data(contentsOf: captureURL)
            processingSpeechTask = processSpeechTask(audioData: data)
        } catch {
            state = .error(error)
            resetValues()
        }
    }
    
    open func processSpeechTask(audioData: Data) -> Task<Void, Never> {
        Task { @MainActor [unowned self] in
            do {
                self.state = .processingSpeech
                let prompt = try await api.generateAudioTransciptions(audioData: audioData)
                try Task.checkCancellation()
                
                let response = try await api.sendMessage(text: prompt, model: model, systemText: systemText, temperature: temperature)
                try Task.checkCancellation()
                
                let parsingTask = ResponseParsingTask()
                let output = await parsingTask.parse(text: response)
                try Task.checkCancellation()
                
                let data = try await api.generateSpeechFrom(input: response, voice:
                        .init(rawValue: selectedVoice.rawValue) ?? .alloy)
                try Task.checkCancellation()
                
                try self.playAudio(data: data, response: .attributed(output))
            } catch {
                if Task.isCancelled { return }
                state = .error(error)
                resetValues()
            }
        }
    }
    
    open func playAudio(data: Data, response: ChatResponse<CustomContent>) throws {
        self.state = .playingSpeech(response)
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer.isMeteringEnabled = true
        audioPlayer.delegate = self
        audioPlayer.play()
        
        // Scheduled timer interval cause wave view to not updated when scrolling as audio plays
        // Use GCD after with recursion until further cleaner solution can be found
        self.scheduleAudioPlayerPowerUpdate()
    }
    
    open func cancelRecording() {
        resetValues()
        state = .idle(nil)
    }
    
    open func cancelProcessingTask() {
        processingSpeechTask?.cancel()
        processingSpeechTask = nil
        resetValues()
        if case .playingSpeech(let response) = self.state {
            state = .idle(response)
        } else {
            state = .idle(nil)
        }
    }
    
    open func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            resetValues()
            state = .idle(nil)
        }
    }
    
    open func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        resetValues()
        if let response = self.state.playingSpeechResponse {
            self.state = .idle(response)
        }
    }
    
    func scheduleAudioPlayerPowerUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let audioPlayer = self.audioPlayer else { return }
            audioPlayer.updateMeters()
            let power = min(1, max(0, 1 - abs(Double(audioPlayer.averagePower(forChannel: 0)) / 160) ))
            self.audioPower = power
            self.scheduleAudioPlayerPowerUpdate()
        }
    }
    
    open func resetValues() {
        audioPower = 0
        prevAudioPower = nil
        audioRecorder?.stop()
        audioRecorder = nil
        audioPlayer?.stop()
        audioPlayer = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        animationTimer?.invalidate()
        animationTimer = nil
    }
}
