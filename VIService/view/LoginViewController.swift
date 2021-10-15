//
//  LoginViewController.swift
//  VIService
//
//  Created by HONGYUN on 10/12/19.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import Network
import MBProgressHUD
import SkyFloatingLabelTextField

class LoginViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var userField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordField: SkyFloatingLabelTextField!
    @IBOutlet weak var btnLogin: UIButton!
    
//    var connected :Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnLogin.layer.cornerRadius = 5
//        NetworkManager.shared.delegate = self
//
//        NetworkManager.shared.getRequest()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.delegate = self // This is not required
        self.view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillAppear() {
        //Do something here
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= 32
        }

    }

    @objc func keyboardWillDisappear() {
        //Do something here
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc fileprivate func dismissKeyboard(sender:UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    
    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }

    @IBAction func onLogin(_ sender: Any) {
        self.performSegue(withIdentifier: "next", sender: nil)
//        let deviceId = userField.text ?? ""
//        let pinPassword = passwordField.text ?? ""
//
//        if deviceId.isEmpty {
//            showAlert(title: "Error", message: "Please enter device id.")
//            return
//        } else if pinPassword.isEmpty {
//            showAlert(title: "Error", message: "Please enter pin password.")
//            return
//        }
//
//        MBProgressHUD.showAdded(to: view, animated: true)
//
//        ApiManager.shared.deviceLogin(id: deviceId, password: pinPassword) { (result) in
//            MBProgressHUD.hide(for: self.view, animated: true)
//
//            switch result {
//            case .success(let response):
//                if response.error {
//                    self.showAlert(title: "Error", message: response.msg)
//                } else {
//                    UserDefaults.standard.set(deviceId, forKey: "DEVICE_ID")
//                    self.performSegue(withIdentifier: "next", sender: nil)
//                }
//            case .failure(let error):
//                self.showAlert(title: "Error", message: error.localizedDescription)
//            }
//        }

    }
}

//extension LoginViewController: NetworkManagerDelegate {
//    // Success response that uses the response tuple to set the connectivity status and instruction.
//    func networkFinishedWithData(response: (String, String, [String : AnyObject])) {
//        DispatchQueue.main.async { [weak self] in
//            self?.connected = 1
//        }
//    }
//    // Error response that uses the response tuple to set the connectivity status and instruction.
//    func networkFinishedWithError(response: (String, String, [String : AnyObject])) {
//        DispatchQueue.main.async { [weak self] in
//            self?.connected = 0
//        }
//    }
//
//}

