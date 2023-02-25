//
//  SoundAnalysisMapper.swift
//  SpeechDemo
//
//  Created by Иван Абрамов on 25.02.2023.
//

import Foundation

class SoundAnalysisMapper {
    func mapSoundAnalysisType(_ type: String) -> String? {
        switch type {
        case "speech":
            return "🗣️"
        case "music", "singing":
            return "🎶"
        case "typewriter", "typing computer", "typing":
            return "💬"
        case "laughter":
            return "🤣"
        default:
            return nil
        }
    }
}
