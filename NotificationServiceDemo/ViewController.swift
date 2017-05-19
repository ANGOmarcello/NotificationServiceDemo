//
//  ViewController.swift
//  NotificationServiceDemo
//
//  Created by Angelo Cammalleri on 18.05.17.
//  Copyright © 2017 Angelo Cammalleri. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private var urlString:String = "https://github.com/KnuffApp/Knuff"

    @IBAction func knuffButton(_ sender: Any) {
        let svc = SFSafariViewController(url: URL(string: self.urlString)!)
        self.present(svc, animated: true, completion: nil)
    }

}

