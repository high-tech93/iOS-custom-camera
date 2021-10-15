//
//  UploadingViewController.swift
//  VIService
//
//  Created by HONGYUN on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import AVFoundation
import UIKit
import SkyFloatingLabelTextField
import MBProgressHUD

class UploadingViewController: UIViewController {
    
    @IBOutlet weak var carNumberTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var technicianTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var uploadButton: UIButton!
        
    @IBOutlet weak var deleteButton: UIButton!
    
    var deviceId : String = ""
    var carNumber : String = ""
    var technician : String = ""
    var videoUrl = UserDefaults.standard.url(forKey: "VIDEO_URL")!
    var uploadVideoURL: URL!
    
    var assetWriter: AVAssetWriter!
    var assetWriterVideoInput: AVAssetWriterInput!
    var audioMicInput: AVAssetWriterInput!
    var audioAppInput: AVAssetWriterInput!
    var channelLayout = AudioChannelLayout()
    var assetReader: AVAssetReader?
    var bitrate: NSNumber = NSNumber(value: 1250000) // *** you can change this number to increase/decrease the quality. The more you increase, the better the video quality but the the compressed file size will also increase
    
    override func viewDidLoad() {
        super.viewDidLoad()
        carNumberTextField.text = UserDefaults.standard.string(forKey: "CAR_NUMBER") ?? ""
        technicianTextField.text = UserDefaults.standard.string(forKey: "TECHNICIAN") ?? ""
        uploadButton.layer.cornerRadius = 5
        deleteButton.layer.cornerRadius = 5
        
        deviceId = UserDefaults.standard.string(forKey: "DEVICE_ID") ?? ""
        carNumber = carNumberTextField.text ?? ""
        technician = technicianTextField.text ?? ""
        videoUrl = UserDefaults.standard.url(forKey: "VIDEO_URL")!
        bitrate = NSNumber(value: UserDefaults.standard.integer(forKey: "BITRATE"))
        
        compressVideo(videoUrl) { (compressedURL) in
            self.uploadVideoURL = compressedURL
            UISaveVideoAtPathToSavedPhotosAlbum(compressedURL.path, nil, nil, nil)
           // remove activity indicator
           // do something with the compressedURL such as sending to Firebase or playing it in a player on the *main queue*
        }
    
    }
    
    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }
    
    func deleteFile(url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // compression function, it returns a .mp4 but you can change it to .mov inside the do try block towards the middle. Change assetWriter = try AVAssetWriter ... AVFileType.mp4 to AVFileType.mov
    func compressVideo(_ urlToCompress: URL, completion:@escaping (URL)->Void) {
        
        var audioFinished = false
        var videoFinished = false
        
        let asset = AVAsset(url: urlToCompress)
        
        //create asset reader
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch {
            assetReader = nil
        }
        
        guard let reader = assetReader else {
            print("Could not iniitalize asset reader probably failed its try catch")
            // show user error message/alert
            return
        }
        
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else { return }
        let videoReaderSettings: [String:Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB]
        
        let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        
        var assetReaderAudioOutput: AVAssetReaderTrackOutput?
        if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
            
            let audioReaderSettings: [String : Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
            
            assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioReaderSettings)
            
            if reader.canAdd(assetReaderAudioOutput!) {
                reader.add(assetReaderAudioOutput!)
            } else {
                print("Couldn't add audio output reader")
                // show user error message/alert
                return
            }
        }
        
        if reader.canAdd(assetReaderVideoOutput) {
            reader.add(assetReaderVideoOutput)
        } else {
            print("Couldn't add video output reader")
            // show user error message/alert
            return
        }
        
        let videoSettings:[String:Any] = [
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: self.bitrate],
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoHeightKey: videoTrack.naturalSize.height,
            AVVideoWidthKey: videoTrack.naturalSize.width,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
        ]
        
        let audioSettings: [String:Any] = [AVFormatIDKey : kAudioFormatMPEG4AAC,
                                           AVNumberOfChannelsKey : 2,
                                           AVSampleRateKey : 44100.0,
                                           AVEncoderBitRateKey: 128000
        ]
        
        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioSettings)
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        videoInput.transform = videoTrack.preferredTransform
        
        let videoInputQueue = DispatchQueue(label: "videoQueue")
        let audioInputQueue = DispatchQueue(label: "audioQueue")
        
        do {
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
            let date = Date()
            let tempDir = NSTemporaryDirectory()
            let outputPath = "\(tempDir)/\(formatter.string(from: date)).mp4"
            let outputURL = URL(fileURLWithPath: outputPath)
            
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
            
        } catch {
            assetWriter = nil
        }
        guard let writer = assetWriter else {
            print("assetWriter was nil")
            // show user error message/alert
            return
        }
        
        writer.shouldOptimizeForNetworkUse = true
        writer.add(videoInput)
        writer.add(audioInput)
        
        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: CMTime.zero)
        
        let closeWriter:()->Void = {
            if (audioFinished && videoFinished) {
                self.assetWriter?.finishWriting(completionHandler: { [weak self] in
                    
                    if let assetWriter = self?.assetWriter {
                        do {
                            let data = try Data(contentsOf: assetWriter.outputURL)
                            
                            self!.showAlert(title: "Compressed File Size", message: "\(Double(data.count / 1048576)) MB")
                        } catch let err as NSError {
                            print("compressFile Error: \(err.localizedDescription)")
                        }
                    }
                    
                    if let safeSelf = self, let assetWriter = safeSelf.assetWriter {
                        completion(assetWriter.outputURL)
                    }
                })
                
                self.assetReader?.cancelReading()
            }
        }
        
        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
            while(audioInput.isReadyForMoreMediaData) {
                if let cmSampleBuffer = assetReaderAudioOutput?.copyNextSampleBuffer() {
                    
                    audioInput.append(cmSampleBuffer)
                    
                } else {
                    audioInput.markAsFinished()
                    DispatchQueue.main.async {
                        audioFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
        
        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
            // request data here
            while(videoInput.isReadyForMoreMediaData) {
                if let cmSampleBuffer = assetReaderVideoOutput.copyNextSampleBuffer() {
                    
                    videoInput.append(cmSampleBuffer)
                    
                } else {
                    videoInput.markAsFinished()
                    DispatchQueue.main.async {
                        videoFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {

        let alert = UIAlertController.init(title: "Delete video", message: "Are you sure to delete video?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) in
            
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { (alertAction) in
            let videoUrl = UserDefaults.standard.url(forKey: "VIDEO_URL")!
            self.deleteFile(url: videoUrl)
            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
                self.navigationController?.setViewControllers([viewController], animated: true)
            }
        })
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func uploadButtonPressed(_ sender: Any) {
        uploadButton.isEnabled = false
        deleteButton.isEnabled = false
        if self.uploadButton.currentTitle == "Resend video" {
            MBProgressHUD.showAdded(to: view, animated: true)
            
            ApiManager.shared.videoCheck(deviceId: deviceId, carNumber: carNumber) { (result) in
                MBProgressHUD.hide(for: self.view, animated: true)
                switch result {
                case .success(let response):
                    if response.error {
                        self.showAlert(title: "Error", message: response.msg) {
                            self.deleteFile(url: self.videoUrl)
                            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
                                self.navigationController?.setViewControllers([viewController], animated: true)
                            }
                        }
                    } else {
                        self.videoCreate(deviceId: self.deviceId, carNumber: self.carNumber, technician: self.technician)
                    }
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription) {
                        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
                            self.navigationController?.setViewControllers([viewController], animated: true)
                        }
                    }
                }
            }
        } else {
            self.videoCreate(deviceId: self.deviceId, carNumber: self.carNumber, technician: self.technician)
        }
    }
    
    func videoCreate(deviceId: String, carNumber: String, technician: String) {
        MBProgressHUD.showAdded(to: view, animated: true)
        
        ApiManager.shared.videoCreate(deviceId: deviceId, carNumber: carNumber, technician: technician) { (result) in
            MBProgressHUD.hide(for: self.view, animated: true)
            switch result {
            case .success(let response):
                if response.error {
                    self.uploadButton.setTitle("Resend video", for: .normal)
                    self.showAlert(title: "Error", message: response.message)
                } else {
                    let jwplatform_token = response.token
                    let jwplatform_key = response.key
                    self.videoUpload(token: jwplatform_token, key: jwplatform_key)
                }
            case .failure(let error):
                self.uploadButton.setTitle("Resend video", for: .normal)
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    func videoUpload (token: String, key: String) {
        
        UIApplication.shared.isIdleTimerDisabled = true
        let progressView = MBProgressHUD.showAdded(to: view, animated: true)
        progressView.mode = .indeterminate
        progressView.label.text = "Uploading..."
        
        ApiManager.shared.videoUpload(token: token, key: key, video: uploadVideoURL, progressHandler: { (progress) in
            progressView.label.text = "Uploading... \(Int(progress * 100))%"
            }) { (result) in
            UIApplication.shared.isIdleTimerDisabled = false
                
            progressView.hide(animated: true)
            switch result {
            case .success(let response):
                if response.status != "ok"{
                    self.uploadButton.setTitle("Resend video", for: .normal)
                    self.showAlert(title: "Error", message: "Upload Failed, Try again later.")
                } else {
                    self.showAlert(title: "", message: "Video upload done") {
                        self.deleteFile(url: self.videoUrl)
                        MBProgressHUD.showAdded(to: self.view, animated: true)
                        ApiManager.shared.videoSuccess(deviceId: self.deviceId, carNumber: self.carNumber) { (result) in
                            MBProgressHUD.hide(for: self.view, animated: true)
                            
                            switch result {
                            case .success(let response):
                                if response.error {
                                    return
                                } else {
                                    if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
                                        self.navigationController?.setViewControllers([viewController], animated: true)
                                    }
                                }
                            case .failure(let error):
                                self.showAlert(title: "Error", message: error.localizedDescription)
                            }
                        }
                    }
                }
            case .failure(let error):
                self.uploadButton.setTitle("Resend video", for: .normal)
                if error._code == NSURLErrorTimedOut {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
                print(error)
                
            }
        }
    }
}
