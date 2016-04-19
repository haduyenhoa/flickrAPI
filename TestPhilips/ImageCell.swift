//
//  ImageCell.swift
//  TestPhilips
//
//  Created by Duyen Hoa Ha on 18/04/2016.
//  Copyright © 2016 Duyen Hoa Ha. All rights reserved.
//

import Foundation

import UIKit

class ImageCell : UITableViewCell {
    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var ivImage : UIImageView!
    @IBOutlet weak var vTitleContainer : UIView!
}

extension UIImageView {
    func downloadImageFrom(link link:String, contentMode: UIViewContentMode) {
        if let _imageData = ImageCache.shareCache.getImageData(link) {
            self.image = UIImage(data: _imageData)
            return
        }
        
        //else, download image
        NSURLSession.sharedSession().dataTaskWithURL( NSURL(string:link)!, completionHandler: {
            (data, response, error) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                self.contentMode =  contentMode
                if let data = data {
                    ImageCache.shareCache.cacheImageData(data, imageId: link)
                    self.image = UIImage(data: data)
                }
            }
        }).resume()
    }
}