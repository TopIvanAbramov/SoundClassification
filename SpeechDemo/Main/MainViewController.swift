//
//  MainViewController.swift
//  SpeechDemo
//
//  Created by Иван Абрамов on 25.02.2023.
//

import UIKit
import AVFAudio
import Speech
import SoundAnalysis


class MainViewController: UIViewController {

//    MARK: -   Properties
    
    let permissionManager = PermissionManager()
    
    var audioEngine: AVAudioEngine?
    var inputBus: AVAudioNodeBus?
    var inputFormat: AVAudioFormat?
    var streamAnalyzer: SNAudioStreamAnalyzer?
    
    let confettiView = ConfettiView()
    
    let analysisQueue = DispatchQueue(label: "com.speechDemo.SoundAnalysisQueue")
    let mapper = SoundAnalysisMapper()
    
//    MARK: -   Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startEmojiAnimations()
    }
    
    fileprivate func setupUI() {
        view.addSubview(confettiView)
        view.backgroundColor = .white
    }
    
    fileprivate func startEmojiAnimations() {
        // check permissions
        
        permissionManager.requestAccess(to: .microphone) { hasAccess in
            guard hasAccess else {
                self.showPermissionAlert(title: "No microphone permission",
                                         subtitle: "Please, grant access to mic to show emojis")
                return
            }
                
            // has access to mic and speech recognition
                
            self.startAudioEngine()
        }
    }
    
//    MARK: -   Start audio engine
    
    fileprivate func startAudioEngine() {
        // Create a new audio engine.
        audioEngine = AVAudioEngine()

        // Get the native audio format of the engine's input bus.
        inputBus = AVAudioNodeBus(0)
        guard let inputBus = inputBus else { return }
        inputFormat = audioEngine?.inputNode.inputFormat(forBus: inputBus)
        
        addSoundClassificationRequest()
        installAudioTap()
        
        do {
            // Start the stream of audio data.
            try audioEngine?.start()
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }

    fileprivate func addSoundClassificationRequest() {
        // Create a new stream analyzer.
        guard let inputFormat = inputFormat else { return }
        streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
        
        // Add a sound classification request that reports to an observer
        
        do {
            let request = try SNClassifySoundRequest(classifierIdentifier: SNClassifierIdentifier.version1)
            try streamAnalyzer?.add(request,
                                    withObserver: self)
        } catch {
            print("Unable to add SNClassifySoundRequest: \(error.localizedDescription)")
        }
    }
    
    fileprivate func installAudioTap() {
        guard let inputBus = inputBus else { return }
        audioEngine?.inputNode.installTap(onBus: inputBus,
                                          bufferSize: 8192,
                                          format: inputFormat,
                                          block: analyzeAudio(buffer:at:))
    }
    
    func analyzeAudio(buffer: AVAudioBuffer, at time: AVAudioTime) {
        analysisQueue.async {
            self.streamAnalyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
        }
    }
}

private extension MainViewController {
    func showPermissionAlert(title: String, subtitle: String) {
        let alert = UIAlertController(title: title,
                                      message: subtitle,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Open settings", style: .default, handler: { (_) in
                self.openSetting()
            }
        ))

        self.present(alert, animated: true, completion: nil)
    }
    
    func openSetting() {
        DispatchQueue.main.async {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    func handleRecognized(type: String) {
        DispatchQueue.main.async {
            guard let emoji = self.mapper.mapSoundAnalysisType(type) else { return }
            self.confettiView.emit(with: [.text(emoji)], for: 5.0)
        }
    }
}

// MARK: - SNResultsObserving
extension MainViewController: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first,
              classification.confidence > 0.5 else {
            return
        }
        
        handleRecognized(type: classification.identifier)
    }
}
