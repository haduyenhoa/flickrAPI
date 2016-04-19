//
//  ImageCache.swift
//  TestPhilips
//
//  Created by Duyen Hoa Ha on 18/04/2016.
//  Copyright © 2016 Duyen Hoa Ha. All rights reserved.
//

import Foundation

private let _shareCache : ImageCache = ImageCache()

private var _imageCache = [String:NSData]()

//Limit image cache to 500 images
let CACHE_LIMIT = 500

/**
 This is simple method to cache image data, we can also setup 2 level of caches: files -> memory -> download from internet
 */
class ImageCache {
    /**
     Singleton
     */
    class var shareCache : ImageCache {
        return _shareCache
    }
    
    /**
     Cache an image into temp memory
     - parameter data: binary data of image to be cached
     - parameter imageId: unique Id for this image
     */
    func cacheImageData(data : NSData?, imageId : String?) {
        if data == nil || imageId == nil {
            return
        }
        
        //remove if out of limit
        if _imageCache.keys.count >= CACHE_LIMIT {
            _imageCache.removeValueForKey(_imageCache.keys.first!)
        }
        
        //add image to cache
        _imageCache[imageId!] = data!
    }
    
    
    /**
     Get cached image from the memory
     - parameter imageId: unique identifier of an image to be retrieve. We can use url of image in server as identifier.
     - returns: binary of image if this image has already cached
     */
    func getImageData(imageId: String?) -> NSData? {
        if let _imageId = imageId {
            return _imageCache[_imageId]
        }
        return nil
    }
    
    /**
     Call when we receive 'didreceivememorywarning'
     */
    func clearCache() {
        _imageCache.removeAll()
    }
}
