//
//  ViewController.swift
//  SpeechToText
//
//  Created by Dejan Tomic on 27/09/2019.
//  Copyright © 2019 Dejan Tomic. All rights reserved.
// tutorial on https://www.appcoda.com/siri-speech-framework/

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isUserInteractionEnabled = false

        speechRecognizer!.delegate = self

        SFSpeechRecognizer.requestAuthorization { (authStatus) in

            var isButtonEnabled = false

            switch authStatus {
            case .authorized: isButtonEnabled = true

            case .denied: isButtonEnabled = false
                print("User denied access to speech recognition")

            case .restricted: isButtonEnabled = false
                print("Speech recognition restricted on this device")

            case .notDetermined: isButtonEnabled = false
            print("Speech recognition not yet authorized")
           
            @unknown default:
                print("unknown 'fatal error'")
            }

            OperationQueue.main.addOperation() {
                self.microphoneButton.isUserInteractionEnabled = isButtonEnabled
            }
        }
    }

    @IBAction func microphoneTapped(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isUserInteractionEnabled = false
            //microphoneButton.setTitle("Start Recording", for: .normal)
            microphoneButton.setBackgroundImage(UIImage(named: "record"), for: .normal)
        } else {
            startRecording()
            //microphoneButton.setTitle("Stop Recording", for: .normal)
            microphoneButton.setBackgroundImage(UIImage(named: "stop"), for: .normal)

        }
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
//        guard let inputNode = audioEngine.inputNode else {
//            fatalError("Audio engine has no input node")
//        }

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask =  speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false

            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
        }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.microphoneButton.isUserInteractionEnabled = true
            }
        })

    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
        self.recognitionRequest?.append(buffer)
    }

    audioEngine.prepare()

    do {
        try audioEngine.start()
    } catch {
        print("audioEngine couldn't start because of an error.")
    }

    textView.text = "Say something, I'm listening!"

    }

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isUserInteractionEnabled = true
        } else {
            microphoneButton.isUserInteractionEnabled = false
        }
    }
    
    
    
    @IBAction func clearTextButtonPressed(_ sender: Any) {
        textView.text = "Say something, I'm listening!"
    }
    
    
    
    
}
