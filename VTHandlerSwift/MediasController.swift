//
//  MediasController.swift
//  VTHandlerSwift
//
//  Created by yixin on 2019/9/10.
//  Copyright © 2019 IUTeam. All rights reserved.
//

import UIKit

class MediasController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
      
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let cachePath = BothRecordController.getMediaCachePath()
        let mediaPath = "video_12345.mp4"
        let path = URL(fileURLWithPath: cachePath, isDirectory: true).appendingPathComponent(mediaPath).path
        let data =  FileManager.default.fileExists(atPath: path)
        print(data ?? "无数据")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
