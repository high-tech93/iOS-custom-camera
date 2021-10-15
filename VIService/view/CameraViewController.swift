//
//  CameraViewController.swift
//  VIService
//
//  Created by HONGYUN on 16/06/17.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SwiftyCam
import MBProgressHUD
import MediaPlayer

class CameraViewController: SwiftyCamViewController {

    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var datetimeButton: UIButton!
    @IBOutlet weak var datetimeLabel: UILabel!
    @IBOutlet weak var recordButton: KYShutterButton!
    
    var isStarted: Bool = false
    var startedTime: Date = Date()
    var totalTime: Int = 0
    var seconds: Int = 180
    var countdownTimer: Timer = Timer()
    var isShowingDatetime: Bool = true
    var datetimeTimer: Timer = Timer()
    var splittedUrls: [URL] = []
    
    var flashSound =  AVAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datetimeButton.layer.borderWidth = 1
        datetimeButton.layer.borderColor = UIColor.white.cgColor
        datetimeButton.isHidden = true
        datetimeLabel.isHidden = true
        UIApplication.shared.isIdleTimerDisabled = true
        
        setSystemVolume(volume: 1.0)
        
        doubleTapCameraSwitch = false
        shouldPrompToAppSettings = true
        cameraDelegate = self
        allowAutoRotate = true
        audioEnabled = true
        flashMode = .on
        flashButton.setImage(UIImage(named: "flash"), for: .normal)
        recordButton.isEnabled = false
        
        self.session.sessionPreset = AVCaptureSession.Preset.hd1280x720;
        videoQuality = .resolution1280x720
        
        if isShowingDatetime {
            runDatetimeTimer()
        }
        
        try! AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .defaultToSpeaker)
        
        let path = Bundle.main.path(forResource: "tone2", ofType:"wav")!
        let url = URL(fileURLWithPath: path)

        do {
            flashSound = try AVAudioPlayer(contentsOf: url)
            flashSound.volume = 1.0
            flashSound.play()
        } catch {
            print("can't load mp3 file");
        }

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func setSystemVolume(volume: Float) {
        let volumeView = MPVolumeView()

        for view in volumeView.subviews {
            if (NSStringFromClass(view.classForCoder) == "MPVolumeSlider") {
                let slider = view as! UISlider
                slider.setValue(volume, animated: false)
            }
        }
    }
    
    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }
    
    func runCountdownTimer() {
        isStarted = true
        startedTime = Date()
        seconds = 180
        countdownLabel.text = timeString(time: TimeInterval(seconds))
        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateCountdown)), userInfo: nil, repeats: true)
    }
    
    @objc func updateCountdown() {
        seconds -= 1
        countdownLabel.text = timeString(time: TimeInterval(seconds))
        
        if seconds == 0 {
            stopCountdownTimer()
            stopVideoRecording()
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%01i:%02i", minutes, seconds)
    }
    
    func stopCountdownTimer() {
        if isStarted {
            isStarted = false
            totalTime = Int(Date().timeIntervalSince(startedTime))
            countdownTimer.invalidate()
        }
    }
    
    func runDatetimeTimer() {
        datetimeLabel.text = dateString(date: Date())
        datetimeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateDatetime)), userInfo: nil, repeats: true)
    }
    
    @objc func updateDatetime() {
        datetimeLabel.text = dateString(date: Date())
    }
    
    func dateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss dd.MM.yyyy"
        return dateFormatter.string(from: date)
    }
    
    func stopDatetimeTimer() {
        datetimeTimer.invalidate()
    }
    
    func hideButtons() {
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 0.0
            self.datetimeButton.alpha = 0.0
        }
    }
    
    func showButtons() {
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 1.0
            self.datetimeButton.alpha = 1.0
        }
    }
    
    @IBAction func RecordButtonPressed(_ sender: Any) {
            if isStarted {
                stopVideoRecording()
            } else {
                startVideoRecording()
            }
    }
    

    
    @IBAction func FlashButtonPressed(_ sender: Any) {
        if flashMode == .on {
            flashMode = .off
            flashButton.setImage(UIImage(named: "flashOutline"), for: .normal)
            
        } else if flashMode == .off {

            setSystemVolume(volume: 1.0)
            flashMode = .on
            flashButton.setImage(UIImage(named: "flash"), for: .normal)
            flashSound.volume = 1.0
            flashSound.play()
        }
        toggleFlash()
    }
    
    @IBAction func DateButtonPressed(_ sender: Any) {
        if isShowingDatetime {
            isShowingDatetime = false
            datetimeButton.setTitle("Show Datetime", for: .normal)
            datetimeLabel.isHidden = true
            stopDatetimeTimer()
        } else {
            isShowingDatetime = true
            datetimeButton.setTitle("Hide Datetime", for: .normal)
            datetimeLabel.isHidden = false
            runDatetimeTimer()
        }
    }
    
    fileprivate func focusAnimationAt(_ point: CGPoint) {
        let focusView = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
}

extension CameraViewController: SwiftyCamViewControllerDelegate {
    
    func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did start running")
        recordButton.isEnabled = true
    }
    
    func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did stop running")
        recordButton.isEnabled = false
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did Begin Recording")
        runCountdownTimer()
        recordButton.buttonState = .recording
        hideButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did finish Recording")
        stopCountdownTimer()
        recordButton.buttonState = .normal
        showButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        UserDefaults.standard.set(url, forKey: "VIDEO_URL")
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
        performSegue(withIdentifier: "upload", sender: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        print("Did focus at point: \(point)")
        focusAnimationAt(point)
    }
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
        print(error)
    }
}



