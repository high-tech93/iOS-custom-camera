//
//  PreviewVideoViewController.swift
//  VIService
//
//  Created by HONGYUN on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import AVKit

protocol CameraViewDelegate:NSObjectProtocol {
    func retake()
}

class PreviewVideoViewController: UIViewController {

   weak var deletage:CameraViewDelegate?
   var videoPath:URL?
   fileprivate  var player = AVPlayer()
   fileprivate var playerController = AVPlayerViewController()
    @IBOutlet weak var view_Preview: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func uploadWithDimiss(_ sender: UIButton) {
        
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func retakeVideo(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
        self.deletage?.retake()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.videoPath != nil {
            player = AVPlayer(url: self.videoPath!)
            player.rate = 1 //auto play
          //  let playerLayer = AVPlayerLayer(player: player)
          //  playerLayer.frame = CGRect(x:0, y:0, width:self.view_Preview.frame.size.width, height:self.view_Preview.frame.size.height)
           // let playerController = AVPlayerViewController()
            playerController.player = player
            playerController.videoGravity = .resizeAspectFill
          
            //playerController.videoGravity = .resize
            player.isMuted = false
            self.addChild(playerController)
            
            // Add your view Frame
            playerController.view.frame = self.view_Preview.frame//CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 300) //self.view_Preview.frame
            _ = AVAsset(url: self.videoPath!)
            //let item = AVPlayerItem(asset: asset)
            // Add subview in your view
            self.view.addSubview(playerController.view)
            
            player.play()
        }
    }

}
