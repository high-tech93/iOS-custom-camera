//
//  ApiManager.swift
//  VIService
//
//  Created by HONGYUN on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import Foundation
import Alamofire
import AVFoundation
import AVKit
import UIKit

class ApiManager {
    
    static let shared = ApiManager()
    
    public var sessionManager: SessionManager
    public var backgroundSessionManager: SessionManager

    private init() {
        
        let defaultConfig = URLSessionConfiguration.default
        defaultConfig.timeoutIntervalForRequest = 600.0
        defaultConfig.timeoutIntervalForResource = 600.0
        
        self.sessionManager = Alamofire.SessionManager(configuration: defaultConfig)

        let backgroundConfig = URLSessionConfiguration.background(withIdentifier: "com.star.VIService")
        backgroundConfig.timeoutIntervalForRequest = 600.0
        backgroundConfig.timeoutIntervalForResource = 600.0

        self.backgroundSessionManager = Alamofire.SessionManager(configuration: backgroundConfig)
        
    }
    
    enum Command {
        case deviceLogin
        case videoCheck
        case videoUpload
        case videoCreate
        case videoSuccess
    }
    
    func deviceLogin(id: String, password: String, completion: @escaping DeviceLoginHandler) {
        let parameters: Parameters = [
            "id": id,
            "password": password
        ]
        sendApiRequest(command: .deviceLogin, method: .get, parameters: parameters) { (response) in
            self.handleResponse(command: .deviceLogin, response: response, completion: completion)
        }
    }
    
    func videoCheck(deviceId: String, carNumber: String, completion: @escaping VideoCheckHandler) {
        let parameters: Parameters = [
            "deviceID": deviceId,
            "car_number": carNumber
        ]
        sendApiRequest(command: .videoCheck, method: .get, parameters: parameters) { (response) in
            self.handleResponse(command: .videoCheck, response: response, completion: completion)
        }
    }
    
    func videoCreate(deviceId: String, carNumber: String, technician: String, completion: @escaping VideoCreateHandler) {
        let parameters: Parameters = [
            "deviceID": deviceId,
            "car_number": carNumber,
            "tech_name" : technician
        ]
        sendApiRequest(command: .videoCreate, method: .get, parameters: parameters) { (response) in
            self.handleResponse(command: .videoCreate, response: response, completion: completion)
        }
    }
    
    func videoSuccess(deviceId: String, carNumber: String, completion: @escaping VideoSuccessHandler) {
        let parameters: Parameters = [
            "deviceID": deviceId,
            "car_number": carNumber
        ]
        sendApiRequest(command: .videoSuccess, method: .get, parameters: parameters) { (response) in
            self.handleResponse(command: .videoSuccess, response: response, completion: completion)
        }
    }
    
    // usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold
    
    func videoUpload(token: String, key: String, video: URL, progressHandler: @escaping (Double) -> (), completion: @escaping VideoUploadHandler) {
        let url = UPLOAD_URL + "?key=" + key + "&token=" + token + "&api_format=json"
        let fileMgr = FileManager.default
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = dirPaths[0].appendingPathComponent("Video_\(datePresentString()).mp4")
        let asset = AVURLAsset(url: video, options: nil)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720)
        
        exportSession?.outputFileType = AVFileType.mp4
        exportSession?.metadata = asset.metadata
        exportSession?.outputURL = filePath
        
        exportSession?.exportAsynchronously {
            if exportSession?.status == .completed {
                self.backgroundSessionManager.upload(multipartFormData: { (multipartFormData) in
                    multipartFormData.append(filePath, withName: "file", fileName: filePath.path, mimeType: "video/mp4")
                }, usingThreshold: UInt64.init(), to: url, method: .post) { (result) in
                    switch result {
                        case .success(let uploadRequest, _, _):
                            uploadRequest.uploadProgress { (progress) in
                                progressHandler(progress.fractionCompleted)
                            }.responseData { (response) in
                                if let data = response.data, let utf8String = String(data: data, encoding: .utf8) {
                                    print("Response data: \(utf8String)")
                                    self.handleResponse(command: .videoUpload, response: response, completion: completion)
                                }
                            }
                        
                        case .failure(let error):
                            completion(.failure(error))
                    }
                    debugPrint(result)
                }
            }
        }
    }
    
    private func sendApiRequest(command: Command, method: HTTPMethod = .get, headers: HTTPHeaders? = nil, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.default, completion: @escaping (DataResponse<Data>) -> ()) {
        var url = ""
        switch command {
        case .deviceLogin:
            url = API_URL + "/device_login"
        case .videoCheck:
            url = API_URL + "/video_check"
        case .videoUpload:
            url = API_URL + "/video_upload"
        case .videoCreate:
            url = API_URL + "/video_create"
        case .videoSuccess:
            url = API_URL + "/video_upload_success"
        }
        
        sessionManager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).responseData { (response) in
            print("Response url:", response.request?.url?.absoluteString ?? "")
            if let data = response.data, let utf8String = String(data: data, encoding: .utf8) {
                print("Response data: \(utf8String)")
                completion(response)
            }
        }
    }
    
    private func handleResponse<T>(command: Command, response: DataResponse<Data>, completion: (Result<T>) -> ()) where T: Decodable {
        switch response.result {
        case .success(_):
            guard let responseData = response.data else { return }
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(T.self, from: responseData)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    public func datePresentString() -> String {
         let date = Date()
         let dateFormatter = DateFormatter()
         let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
         dateFormatter.calendar = Calendar(identifier: .iso8601)
         dateFormatter.locale = enUSPosixLocale
         dateFormatter.timeZone = TimeZone.current
         dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
         
         let iso8601String = dateFormatter.string(from: date as Date)
         
         return iso8601String
     }

}
