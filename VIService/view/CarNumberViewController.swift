//
//  CarNumberViewController.swift
//  VIService
//
//  Created by HONGYUN on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import MBProgressHUD
import SkyFloatingLabelTextField
import MediaPlayer

class CarNumberViewController: UIViewController {

 
    @IBOutlet weak var carNumberTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var technicianTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.layer.cornerRadius = 5
        logoutButton.layer.cornerRadius = 5
//        MPVolumeView.setVolume(1.0)
//        (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(1, animated: false)
    }
    
    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }

    @IBAction func logoutButtonPressed(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "DEVICE_ID")
        performSegue(withIdentifier: "login", sender: nil)
    }
    
    @IBAction func bitrateBtnTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "adjust", sender: nil)
    }
    @IBAction func nextButtonPressed(_ sender: Any) {
//        self.performSegue(withIdentifier: "recording", sender: nil)
        let deviceId = UserDefaults.standard.string(forKey: "DEVICE_ID") ?? ""
        let carNumber = carNumberTextField.text ?? ""
        let technician = technicianTextField.text ?? ""

        if carNumber.isEmpty {
            showAlert(title: "Error", message: "Please enter car number.")
            return
        }
//        else if technician.isEmpty {
//            showAlert(title: "Error", message: "Please enter technician.")
//            return
//        }

        MBProgressHUD.showAdded(to: view, animated: true)

        ApiManager.shared.videoCheck(deviceId: deviceId, carNumber: carNumber) { (result) in
            MBProgressHUD.hide(for: self.view, animated: true)

            switch result {
            case .success(let response):
                if response.error {
                    self.showAlert(title: "Error", message: response.msg)
                } else {
                    UserDefaults.standard.set(carNumber, forKey: "CAR_NUMBER")
                    if technician.isEmpty {
                        UserDefaults.standard.set("", forKey: "TECHNICIAN")
                    }
                    else {
                        UserDefaults.standard.set(technician, forKey: "TECHNICIAN")
                    }

                    self.performSegue(withIdentifier: "recording", sender: nil)
                }
            case .failure(let error):
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
}
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        // Need to use the MPVolumeView in order to change volume, but don't care about UI set so frame to .zero
        let volumeView = MPVolumeView()
        let screenSize: CGRect = UIScreen.main.bounds
        volumeView.frame = CGRect( x: 0, y: screenSize.height/2, width: volumeView.frame.size.width, height: volumeView.frame.size.height )
        // Search for the slider
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        // Update the slider value with the desired volume.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
        // Optional - Remove the HUD
        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
            volumeView.alpha = 0.9
            window.addSubview(volumeView)
        }
    }
    
}
