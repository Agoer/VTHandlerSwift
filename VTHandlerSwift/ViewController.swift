//
//  ViewController.swift
//  VTHandlerSwift
//
//  Created by yixin on 2019/8/20.
//  Copyright © 2019 IUTeam. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func bothRecordButtonPressed(_ sender: Any) { self.navigationController?.pushViewController(BothRecordController(), animated: true)
    }
    
}

