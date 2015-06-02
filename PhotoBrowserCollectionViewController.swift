//
//  PhotoBrowserCollectionViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-20.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

class PhotoBrowserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var photos = NSMutableOrderedSet()
    
    let refreshControl = UIRefreshControl()
    let imageCache = NSCache()
    
    let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
    let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
    
    var populatingPhotos = false
    var currentPage = 1
    
    // MARK: Life-cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        populatePhotos()
        
//        let consumerKey = "IXNyON2qMgm277NcJyTnzZDCzq9ZpGwPuPPMGi94"
//        let urlString = "https://api.500px.com/v1/photos"
//        
//        Alamofire.request(.GET, urlString, parameters: ["consumer_key": consumerKey]).responseJSON {
//            (_, _, data, _) -> Void in
//            
//            if let json = data as? NSDictionary {
//                
//                
//                if let photos = json.valueForKey("photos") as? [NSDictionary] {
//                    
//                    let safePhotos = photos.filter{
//                        //安全图片
//                        ($0["nsfw"] as! Bool) == false
//                    }
//                    
//                  
//                    
//                    self.photos.addObjectsFromArray(newPhotos)
//                    
//                    self.collectionView!.reloadData()
//                }
//            }
//        }
    }
    
    func populatePhotos(){
        
        if populatingPhotos {
            return
        }
        
        populatingPhotos = true
        
        Alamofire.request(Five100px.Router.PopularPhotos(self.currentPage)).responseJSON { (_, _, data, error) -> Void in
            if error == nil {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    let photoInfos = (((data as! NSDictionary).valueForKey("photos") as! [NSDictionary]).filter{($0["nsfw"] as! Bool) == false}).map{
                        PhotoInfo(id: $0["id"] as! Int, url: $0["image_url"] as! String)
                    }
                    
                    let lastItem = self.photos.count
                    
                    self.photos.addObjectsFromArray(photoInfos)
                    
                    let indexPaths = (lastItem..<self.photos.count).map{
                        NSIndexPath(forItem: $0, inSection: 0)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.collectionView?.insertItemsAtIndexPaths(indexPaths)
                    })
                    
                    self.currentPage++
                    
                })
                
                
            }
        }
        
        populatingPhotos = false
            
        
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8{
            populatePhotos()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: CollectionView
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoBrowserCellIdentifier, forIndexPath: indexPath) as! PhotoBrowserCollectionViewCell
        
        let imageURL = (self.photos.objectAtIndex(indexPath.row) as! PhotoInfo).url
        
        // 1
        if cell.request?.request.URLString != imageURL {
            cell.request?.cancel()
        }
        // 2
        if let image = self.imageCache.objectForKey(imageURL) as? UIImage {
            cell.imageView.image = image
        } else {
            // 3
            cell.imageView.image = nil
            
            // 4
            cell.request = Alamofire.request(.GET, imageURL).validate(contentType: ["image/*"]).responseImage() {
                (request, _, image, error) in
                if error == nil && image != nil {
                    // 5
                    self.imageCache.setObject(image!, forKey: request.URLString)
                    // 6
                    if request.URLString == cell.request?.request.URLString {
                        cell.imageView.image = image
                    }
                } else {
                    /*
                    If the cell went off-screen before the image was downloaded, we cancel it and
                    an NSURLErrorDomain (-999: cancelled) is returned. This is a normal behavior.
                    */
                }
            }
        }

//        cell.request = Alamofire.request(.GET, imageURL).responseImage{ (request, _, image, error) -> Void in
//            if (error == nil && image != nil){
//                if request.URLString == cell.request?.request.URLString{
//                    cell.imageView.image = image
//                }
//            }
//        }
        
//        Alamofire.request(.GET, photo.url).response { (_, _, data, _) -> Void in
//            if let data = data as? NSData {
//                cell.imageView.image = UIImage(data: data)
//            }
//        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: PhotoBrowserFooterViewIdentifier, forIndexPath: indexPath) as! UICollectionReusableView
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("ShowPhoto", sender: (self.photos.objectAtIndex(indexPath.item) as! PhotoInfo).id)
    }
    
    // MARK: Helper
    
    func setupView() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        let layout = UICollectionViewFlowLayout()
        let itemWidth = (view.bounds.size.width - 2) / 3
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        layout.footerReferenceSize = CGSize(width: collectionView!.bounds.size.width, height: 100.0)
        
        collectionView!.collectionViewLayout = layout
        
        let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 60.0, height: 30.0))
        titleLabel.text = "Photomania"
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        navigationItem.titleView = titleLabel
        
        collectionView!.registerClass(PhotoBrowserCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: PhotoBrowserCellIdentifier)
        collectionView!.registerClass(PhotoBrowserCollectionViewLoadingCell.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PhotoBrowserFooterViewIdentifier)
        
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.addTarget(self, action: "handleRefresh", forControlEvents: .ValueChanged)
        collectionView!.addSubview(refreshControl)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowPhoto" {
            (segue.destinationViewController as! PhotoViewerViewController).photoID = sender!.integerValue
            (segue.destinationViewController as! PhotoViewerViewController).hidesBottomBarWhenPushed = true
        }
    }
    
    func handleRefresh() {
        refreshControl.beginRefreshing()
        self.photos.removeAllObjects()
        self.currentPage = 1
        self.collectionView!.reloadData()
        refreshControl.endRefreshing()
        populatePhotos()
    }
}

class PhotoBrowserCollectionViewCell: UICollectionViewCell {
    let imageView = UIImageView()
    var request: Alamofire.Request?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        imageView.frame = bounds
        addSubview(imageView)
    }
}

class PhotoBrowserCollectionViewLoadingCell: UICollectionReusableView {
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        spinner.startAnimating()
        spinner.center = self.center
        addSubview(spinner)
    }
}
