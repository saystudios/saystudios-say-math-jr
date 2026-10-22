import AVFoundation

/// Reads questions and praise out loud so pre-readers can play on their own.
@MainActor
final class Speaker {
    static let shared = Speaker()

    private let synth = AVSpeechSynthesizer()

    private init() {
        // Play speech even when the ringer switch is on silent.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    func say(_ text: String) {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.43
        utterance.pitchMultiplier = 1.15
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }

    static let praise = [
        "Great job!", "You got it!", "Awesome!", "Super star!", "Way to go!", "Nice thinking!", "Yes! That's right!",
    ]
    static let encourage = [
        "Almost! Try again.", "Good try! Let's look again.", "Not quite. You can do it!", "Oops! Try another one.",
    ]
}
