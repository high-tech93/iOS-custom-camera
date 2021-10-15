//
//  AdjustViewController.swift
//  VIService
//
//  Created by Wang on 10/14/21.
//  Copyright © 2021 Polestar. All rights reserved.
//

import UIKit

class AdjustViewController: UIViewController {

    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var bitrateValue: UILabel!
    @IBOutlet weak var slideValue: UISlider!
    var bit_rate = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        backBtn.layer.cornerRadius = 5
        slideValue.value = Float(UserDefaults.standard.integer(forKey: "BITRATE"))
        bitrateValue.text = String(UserDefaults.standard.integer(forKey: "BITRATE"))
    }
    
    @IBAction func changeBitRate(_ sender: Any) {
        bit_rate = Int(slideValue.value)
        bitrateValue.text = "\(bit_rate)"
    }
    @IBAction func backBtnTapped(_ sender: Any) {
        UserDefaults.standard.set(bit_rate, forKey: "BITRATE")
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
            self.navigationController?.setViewControllers([viewController], animated: true)
        }
    }
    
}
