//
//  LandingViewController.swift
//  VIService
//
//  Created by HONGYUN on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit

class LandingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if UserDefaults.standard.string(forKey: "DEVICE_ID") == nil {
            performSegue(withIdentifier: "login", sender: nil)
        } else {
            performSegue(withIdentifier: "carnumber", sender: nil)
        }
    }

}
