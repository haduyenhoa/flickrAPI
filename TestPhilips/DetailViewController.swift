//
//  DetailViewController.swift
//  TestPhilips
//
//  Created by Duyen Hoa Ha on 18/04/2016.
//  Copyright © 2016 Duyen Hoa Ha. All rights reserved.
//

import Foundation
import UIKit

class DetailViewController : UIViewController {
    @IBOutlet var vLoading : UIView!
    
    
    @IBOutlet var btnBack : UIButton!
    @IBOutlet var lblOwner : UILabel!
    @IBOutlet var lblDate : UILabel!
    @IBOutlet var lblDescription : UILabel!
    
    @IBOutlet var ivLargeImage : UIImageView!
    @IBOutlet var scrvMainContent : UIScrollView!
    
    var fi : FlickrImage?
    
    @IBAction func back(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrvMainContent.minimumZoomScale = 1.0;
        self.scrvMainContent.maximumZoomScale = 10.0;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //load image
        if let _fi = fi {
            let imageUrl = FlickrAgent.shareAgent.createOriginalImageUrl(_fi.farm, serverId: _fi.server, id: _fi.imageId, secret: _fi.secret)
            
            if let _imageData = ImageCache.shareCache.getImageData(imageUrl) {
                self.ivLargeImage.image = UIImage(data: _imageData)
                return
            }
            
            //else, download image
            NSURLSession.sharedSession().dataTaskWithURL( NSURL(string:imageUrl)!, completionHandler: {
                (data, response, error) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if let data = data {
                        ImageCache.shareCache.cacheImageData(data, imageId: imageUrl)
                        self.ivLargeImage.image = UIImage(data: data)
                    }
                }
            }).resume()
            
            
            //get info
            FlickrAgent.shareAgent.getImageInfo(_fi, completion: { (fii, gotError) in
                if let _fii = fii {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.lblDescription.text = self.fi?.title
                        self.lblOwner.text = fii?.owner ?? ""
                        self.lblDate.text = "Taken date: \(_fii.takenDate)"
                        
                        self.vLoading.alpha = 0.0
                    })
                }
            })
        }
    }
}

extension DetailViewController : UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
    {
        return self.ivLargeImage
    }
}