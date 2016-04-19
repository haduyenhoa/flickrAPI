//
//  MainViewController.swift
//  TestPhilips
//
//  Created by Duyen Hoa Ha on 18/04/2016.
//  Copyright © 2016 Duyen Hoa Ha. All rights reserved.
//

import Foundation
import UIKit

class MainViewController : UIViewController {
    @IBOutlet var tblMain : UITableView!
    var isLoadingMoreImages = false
    let limitRefreshOffset: CGFloat = 30.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tblMain.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let destination = segue.destinationViewController as! DetailViewController
            
            if let selectedIndex = self.tblMain.indexPathForSelectedRow {
                let _fi = FlickrAgent.shareAgent.foundPhotos[selectedIndex.row]
                    destination.fi = _fi
                
                
            }
            
        }
    }
}

extension MainViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //searching now
        searchBar.resignFirstResponder()
        
        if searchBar.text == nil || searchBar.text!.isEmpty {
            //do nothing
            return
        }
        
        //then start search
        FlickrAgent.shareAgent.lastPage = 0
        FlickrAgent.shareAgent.searchImages(FlickrAgent.shareAgent.lastPage + 1, imagesPerPage: 50, text: searchBar.text!) { (page, imagesArray, gotError) in
            //add to FlickrAgent
            self.tblMain.userInteractionEnabled = false
            FlickrAgent.shareAgent.foundPhotos.removeAll()
            
            if let _imagesArray = imagesArray {
                FlickrAgent.shareAgent.foundPhotos.appendContentsOf(_imagesArray)
            }
            
            self.tblMain.userInteractionEnabled = true
            
            dispatch_async(dispatch_get_main_queue(), {
                self.tblMain.setContentOffset(CGPointZero, animated: false) //scroll to top
                self.tblMain.reloadData()
            })
            
            
        }
    }
}

extension MainViewController : UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        dispatch_async(dispatch_queue_create("com.haduyenhoa.tableview.refreshcontrol", nil)) {
            let contentOffset = scrollView.contentOffset.y
            let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
            
            if !self.isLoadingMoreImages &&  (maximumOffset - contentOffset <= self.limitRefreshOffset) {
                print("refreshing...")
                self.isLoadingMoreImages = true

                //show "loading" cell
                dispatch_async(dispatch_get_main_queue()) {
                    self.tblMain.reloadData() //refresh table view
                }
                
                FlickrAgent.shareAgent.searchImages(FlickrAgent.shareAgent.lastPage + 1, imagesPerPage: 50, text: FlickrAgent.shareAgent.currentSearchText ?? "") { (page, imagesArray, gotError) in
                    //add to FlickrAgent
                    self.tblMain.userInteractionEnabled = false
                    
                    if let _imagesArray = imagesArray {
                        FlickrAgent.shareAgent.foundPhotos.appendContentsOf(_imagesArray)
                    }
                    
                    self.tblMain.userInteractionEnabled = true
                    self.isLoadingMoreImages = false
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.tblMain.reloadData()
                    })
                    
                    
                }
            } else {
//                print("no refresh now")
            }
        }
        
    }
}

extension MainViewController : UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if self.isLoadingMoreImages && indexPath.row == FlickrAgent.shareAgent.foundPhotos.count {
            //return loading more row
            let cell = self.tblMain.dequeueReusableCellWithIdentifier("LoadingMoreCellId")! as UITableViewCell
            return cell
        }
        
        let cell = self.tblMain.dequeueReusableCellWithIdentifier("ImageCellId", forIndexPath: indexPath) as! ImageCell
        
        //assign flickr image to this image cell
        let fi = FlickrAgent.shareAgent.foundPhotos[indexPath.row]
        
        if let _title = fi.title {
            cell.vTitleContainer.alpha = 1.0
            cell.lblTitle.text = _title
        } else {
            cell.vTitleContainer.alpha = 0.0;
        }
        
        cell.ivImage.image = nil //use empty image while waiting for downloaded image
        cell.ivImage.downloadImageFrom(link: FlickrAgent.shareAgent.createImageUrl(fi.farm, serverId: fi.server, id: fi.imageId, secret: fi.secret), contentMode: .ScaleAspectFill)
        
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isLoadingMoreImages {
            return FlickrAgent.shareAgent.foundPhotos.count + 1
        }
        return FlickrAgent.shareAgent.foundPhotos.count
    }
}

extension MainViewController : UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if self.isLoadingMoreImages && indexPath.row ==  FlickrAgent.shareAgent.foundPhotos.count {
            return 100
        } else {
            return 250
        }
    }
}