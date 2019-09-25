//
//  AGRecordEngine.swift
//  VTHandlerSwift
//
//  Created by yixin on 2019/9/6.
//  Copyright © 2019 IUTeam. All rights reserved.
//

import Foundation
import CoreMedia

enum AGRecordEngineState {
    case stoped
    case capturing
    case paused
    
}

struct AGRecordEngineStatus {
    //是否中断过
    var state:AGRecordEngineState = .stoped
    var hadSuspend = false
    //录制的偏移CMTime
    var offsetTime:CMTime = CMTimeMake(value: 0, timescale: 0)
    //记录上一次视频数据文件的CMTime
    var lastVideoTime:CMTime = CMTimeMake(value: 0, timescale: 0)
    //记录上一次音频数据文件的CMTime
    var lastAudioTime:CMTime = CMTimeMake(value: 0, timescale: 0)
    
    //开始录制的时间
    var startTime:CMTime = CMTimeMake(value: 0, timescale: 0)
    
    //当前录制时间
    var currentRecordTime:Float64 = 0
    
    //最长录制时间
    var maxRecordTime:Float64 = 60
}

class AGRecordEngine: NSObject {
 
    
}
