//
//  FlickerAgent.swift
//  TestPhilips
//
//  Created by Duyen Hoa Ha on 19/04/2016.
//  Copyright © 2016 Duyen Hoa Ha. All rights reserved.
//

import Foundation
import UIKit
/**
 Represent a Flickr Image object
 */
struct FlickrImage {
   /**
    EXAMPLE of an FlickrImage data
     id: "26502335296",
     owner: "134352553@N04",
     secret: "b2e1f03960",
     server: "1508",
     farm: 2,
     title: "Le soup bar, Paris",
     ispublic: 1,
     isfriend: 0,
     isfamily: 0
     
     */
    //id of image
    var imageId : String!
    //server of image
    var server : String!
    //secrect key to get image
    var secret : String!
    //farm
    var farm : Int!
    
    /**
     Title of the image
     */
    var title : String?
    
    /**
     Init the default value for this FlickrImage.
     */
    init() {
        imageId = "" //init with unknown imageId
    }
    
    init (jsonDict : NSDictionary) {
        //get tite
        if let _imageTitle = jsonDict["title"] as? String {
            self.title = _imageTitle
        }
        
        //get imageId
        if let _aId = jsonDict["id"] as? String {
            self.imageId = _aId
        }
        
        //get secret
        if let _aSecret = jsonDict["secret"] as? String {
            self.secret = _aSecret
        }
        
        //get server
        if let _aServer = jsonDict["server"] as? String {
            self.server = _aServer
        }
        
        //get farm
        if let _aFarm = jsonDict["farm"] as? Int {
            self.farm = _aFarm
        }
    }
}

struct FlickrImageInfo {
    var fi : FlickrImage
    
    var takenDate : String
    var owner : String
    var view : Int!
    
    init(aDate : String, name: String, viewCount : Int, fi: FlickrImage) {
        self.takenDate = aDate
        self.owner = name
        self.view = viewCount
        self.fi = fi
    }
}

/**
 Definition of the completion that will be called after a 'Refresh' images
 - parameter page: requested page.
 - parameter imagesArray: if the download is finished with data, this object holds the images of the requested page
 - parameter gotError: if the download is failed, this object holds the error.
 */
typealias GetImagesCompletion = ((page : Int, imagesArray : [FlickrImage]?, gotError : NSError?) -> ())

/**
 Completion that be called after a fetch info finished.
 */
typealias GetImageInfo = ((fii : FlickrImageInfo?, gotError : NSError?) -> ())

private let _shareAgent = FlickrAgent()

class FlickrAgent {
    
    /**
     Contains found image after a search
     */
    var foundPhotos = [FlickrImage]()
    
    let privateKey = "f668a6f84ce47e07a2dccf4ab6e9a616"

    //to know what is next page to download
    var lastPage: Int! = 0
    var currentSearchText : String?

    private var _isSearching : Bool = false
    
    /**
     Simple singleton
     */
    class var shareAgent : FlickrAgent {
        return _shareAgent
    }
    
    /**
        Search image that match a search text.
     */
    func searchImages(page: Int, imagesPerPage:Int = 100, text: String, completion : GetImagesCompletion) {
        print("Searching images")

        //simple test for refreshing state
        if _isSearching {
            print("Another refresh is in progress")
            return
        }
        
        _isSearching = true
        
        self.lastPage = page
        self.currentSearchText = text
        
        //download json, remember to add ATSS to bypass security
        let requestURL: NSURL = NSURL(string: self.createSearchUrl(text, page: page, imagesPerPage: imagesPerPage))!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            //be sure that we downloaded somethings.
            guard error == nil && data != nil else {
                //show alert
                AlertAgent().showSimpleAlert("Error", msg: "An error has occured. Please try to search later", okButtonTitle: "OK", animated: true)
                
                //got error
                completion(page: page, imagesArray: nil, gotError:  NSError(domain: "com.haduyenhoa.network", code: statusCode, userInfo: nil))
                
                return
            }
            
             if (statusCode == 200) {
                self.parseFoundImagesJson(data!, completion: completion)
            } else {
                //show alert
                AlertAgent().showSimpleAlert("Error", msg: "An error has occured. Please try to search later", okButtonTitle: "OK", animated: true)
                
                //got error
                completion(page: page, imagesArray: nil, gotError:  NSError(domain: "com.haduyenhoa.network", code: statusCode, userInfo: nil))
            }
            
            self._isSearching = false
        }
        
        task.resume()
    }
    
    func getImageInfo(fi: FlickrImage, completion : GetImageInfo) {
        print("Fetching info")
        
        //download json, remember to add ATSS to bypass security
        let requestURL: NSURL = NSURL(string: self.createGetImageInfo(fi))!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            //be sure that we downloaded somethings.
            guard error == nil && data != nil else {
                //show alert
                AlertAgent().showSimpleAlert("Error", msg: "An error has occured. Please try again later", okButtonTitle: "OK", animated: true)
                
                //got error
                completion(fii: nil, gotError:  NSError(domain: "com.haduyenhoa.network", code: statusCode, userInfo: nil))
                
                return
            }
            
            if (statusCode == 200) {
                //parse json
                self.parseImageInfoJson(data!, fi: fi, completion: completion)
            } else {
                //show alert
                AlertAgent().showSimpleAlert("Error", msg: "An error has occured. Please try again later", okButtonTitle: "OK", animated: true)
                
                //got error
                completion(fii: nil, gotError:  NSError(domain: "com.haduyenhoa.network", code: statusCode, userInfo: nil))
            }
            
            self._isSearching = false
        }
        
        task.resume()
    }
    
    /**
        Create HTTP GET search url to get all image from search text.
    */
    func createSearchUrl(searchText: String, page: Int, imagesPerPage: Int) -> String {
        //create url string to search base on search Text. Consider that searchText is valid.
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(privateKey)&text=\(searchText)&per_page=\(imagesPerPage)&page=\(page)&format=json&nojsoncallback=1"
        
        return urlString
    }
    
    /**
     Create HTTP GET to get image Info.
     */
    func createGetImageInfo(fi : FlickrImage) -> String {
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=\(privateKey)&photo_id=\(fi.imageId)&format=json&nojsoncallback=1"
        return urlString
    }
    
    /**
        Get image from static url https://www.flickr.com/services/api/misc.urls.html
    */
    func createImageUrl(farmId: Int, serverId: String, id: String, secret: String) -> String {
        return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret)_c.jpg"
    }
    
    func createOriginalImageUrl(farmId: Int, serverId: String, id: String, secret: String) -> String {
        return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret)_h.jpg"
    }
    
    /*
     Parse json after retrieved from server.
     - parameter jsonData : data to be parsed
     - parameter completion: handler to be called after parsing is finished
     */
    func parseFoundImagesJson(jsonData : NSData, completion : GetImagesCompletion) {

        var jsonObject : NSDictionary?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
        } catch  {
            //got error
            completion(page: 0, imagesArray: nil, gotError: NSError(domain: "com.haduyenhoa.network", code: 1001, userInfo: nil))
            
            //show alert
            AlertAgent().showSimpleAlert("Error", msg: "Got error while trying to parse result from downloaded data", okButtonTitle: "OK", animated: true)
            return
        }
        
        //use guard to verify the integretiy of json object (swift 2.0+)
        guard let _jsonObject = jsonObject,
            let _ = _jsonObject["photos"] as? NSDictionary
            else {
                //do nothing cause the object is not conformed to the right structure
                
                return
        }
        
        //create flicker image object
        if let photosDict = _jsonObject["photos"] as? NSDictionary,
            let _photoDict = photosDict["photo"] as? [NSDictionary],
            let _pageCount = photosDict["pages"]
        {
            var result = [FlickrImage]()
            for aDict in _photoDict {
                let fi = FlickrImage(jsonDict: aDict)
                
                //add only valid flickrImage
                if fi.farm > 0
                    && !fi.imageId.isEmpty
                    && !fi.secret.isEmpty
                    && !fi.server.isEmpty
                {
                    result.append(fi)
                }
            }
            completion(page: _pageCount.integerValue, imagesArray: result, gotError: nil)
        } else {
            //return error
        }
    }
    
    func parseImageInfoJson(jsonData : NSData,fi : FlickrImage, completion : GetImageInfo) {
        
        var jsonObject : NSDictionary?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
        } catch  {
            //got error
            completion(fii: nil, gotError: NSError(domain: "com.haduyenhoa.network", code: 1001, userInfo: nil))
            
            //show alert
            AlertAgent().showSimpleAlert("Error", msg: "Got error while trying to parse result from downloaded data", okButtonTitle: "OK", animated: true)
            return
        }
        
        //use guard to verify the integretiy of json object (swift 2.0+)
        guard let _jsonObject = jsonObject,
            let _ = _jsonObject["photo"] as? NSDictionary
            else {
                //do nothing cause the object is not conformed to the right structure
                
                return
        }
        
        //create flicker image info object
        if let photoDict = _jsonObject["photo"] as? NSDictionary,
            let _dateDict = photoDict["dates"] as? NSDictionary,
            let _ownerDict = photoDict["owner"] as? NSDictionary
        {
            let takenDate = _dateDict["taken"] as? String
            let owner = _ownerDict["username"] as? String
            let count = (photoDict["views"] as? Int) ?? 0
            
            let fii = FlickrImageInfo(aDate: takenDate ?? "", name: owner ?? "", viewCount: count, fi: fi)
            
            completion(fii:fii, gotError: nil)
        } else {
            //return error
            completion(fii: nil, gotError: NSError(domain: "com.haduyenhoa.data", code: 1002, userInfo: nil))
        }
    }

}