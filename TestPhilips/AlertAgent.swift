//
//  AlertAgent.swift
//  TestPhilips
//
//  Created by Duyen Hoa Ha on 19/04/2016.
//  Copyright © 2016 Duyen Hoa Ha. All rights reserved.
//

import Foundation
import UIKit

class AlertAgent {
    /**
     Show an simple alert on top of all window
     */
    func showSimpleAlert(title: String, msg: String, okButtonTitle : String, animated : Bool) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let _alertWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
            _alertWindow.rootViewController = UIViewController()
            _alertWindow.windowLevel = UIWindowLevelAlert + 1
            _alertWindow.hidden = false
            
            let alert = UIAlertController(title: title ?? "", message: msg ?? "", preferredStyle: UIAlertControllerStyle.Alert)
            let okBtn = UIAlertAction(title: okButtonTitle ?? "", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
                _alertWindow.resignKeyWindow()
                _alertWindow.hidden = true
                
            }
            
            alert.addAction(okBtn)
            
            _alertWindow.makeKeyWindow()
            _alertWindow.rootViewController!.presentViewController(alert, animated: animated, completion: nil)
        }
        
        
    }
}
