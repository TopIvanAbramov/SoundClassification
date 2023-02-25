//
//  PermissionManager.swift
//  SpeechDemo
//
//  Created by Иван Абрамов on 25.02.2023.
//

import Foundation
import AVFAudio
import Speech

enum PermissionType {
    case microphone
    case speechRecognition
}

final class PermissionManager {
    func requestAccess(to type: PermissionType, completion: @escaping (Bool) -> Void) {
        switch type {
        case .microphone:
            self.requestAccessToMicrophonePermission(completion: completion)
        case .speechRecognition:
            self.requestAccessToSpeechRecognitionPermission(completion: completion)
        }
    }
    
    fileprivate func requestAccessToMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            completion(granted)
        }
    }
    
    fileprivate func requestAccessToSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
               switch authStatus {
                 case .authorized:
                     completion(true)
                  case .denied, .restricted:
                      completion(false)
                  case .notDetermined:
                     completion(false)
                  @unknown default:
                      completion(false)
                  }
            }
        }
    }
}
