//
//  Five100px.swift
//  Photomania
//
//  Created by Essan Parto on 2014-09-25.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

@objc public protocol ResponseCollectionSerializable {
    static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [Self]
}
extension Alamofire.Request {
    public func responseCollection<T: ResponseCollectionSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, [T]?, NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            if response != nil && JSON != nil {
                return (T.collection(response: response!, representation: JSON!), nil)
            } else {
                return (nil, serializationError)
            }
        }
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            completionHandler(request, response, object as? [T], error)
        })
    }
}

@objc public protocol ResponseObjectSerializable {
    init(response: NSHTTPURLResponse, representation: AnyObject)
}

extension Alamofire.Request {
    
    public func responseObject<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, T? , NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            if response != nil && JSON != nil {
                return (T(response: response!, representation: JSON!) , nil)
            } else {
                return (nil, serializationError)
            }
        }
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            completionHandler(request, response, object as? T, error)
        })
    }
}

extension Request {
    /**
    创建了一个Image的Serializer
    */
    public class func ImageResponseSerializer() -> Serializer {
        return { request, response, data in
            if data == nil || data?.length == 0 {
                return (nil, nil)
            }
            
            var serializationError: NSError?

            let image = UIImage(data: data!, scale: UIScreen.mainScreen().scale)
            
            return (image, serializationError)
        }
    }
    
    
    /**
    Image的处理闭包
    */
    public func responseImage(completionHandler: (NSURLRequest, NSHTTPURLResponse?, UIImage?, NSError?) -> Void) -> Self {
        return response(serializer: Request.ImageResponseSerializer(), completionHandler: { request, response, image, error in
            completionHandler(request, response, image as? UIImage, error)
        })
    }
}

struct Five100px {
    enum ImageSize: Int {
        case Tiny = 1
        case Small = 2
        case Medium = 3
        case Large = 4
        case XLarge = 5
    }
    enum Router: URLRequestConvertible {
        static let baseURLString = "https://api.500px.com/v1"
        static let consumerKey = "IXNyON2qMgm277NcJyTnzZDCzq9ZpGwPuPPMGi94"
        
        case PopularPhotos(Int)
        case PhotoInfo(Int,ImageSize)
        case Comments(Int,Int)
        
        var URLRequest: NSURLRequest{
            
            let (path:String, parameters: [String:AnyObject]) = {
                switch self {
                case Router.PopularPhotos(let page):
                    let params = [
                        "consumer_key": Router.consumerKey,
                        "page": "\(page)",
                        "feature": "popular",
                        "rpp": "50",
                        "include_store": "store_download",
                        "include_states": "votes"
                    ]
                    return ("/photos",params)

                case Router.PhotoInfo(let id, let imgSize):
                    let params = [
                        "consumer_key": Router.consumerKey,
                        "image_size": "\(imgSize.rawValue)"
                    ]
                    return ("/photos/\(id)",params)
                    
                case Router.Comments(let id, let commentsPage):
                    let params = [
                        "consumer_key": Router.consumerKey,
                        "comments": "1",
                        "comments_page": "\(commentsPage)"
                    ]
                    return ("/photos/\(id)/comments", params)
                }
            }()
            
            let url = NSURL(string: Router.baseURLString)!
            let request = NSURLRequest(URL: url.URLByAppendingPathComponent(path))
            
            return Alamofire.ParameterEncoding.URL.encode(request, parameters: parameters).0
            
        }
    }
    
    enum Category: Int, Printable {
        
        case Uncategorized = 0, Celebrities, Film, Journalism, Nude, BlackAndWhite, StillLife, People, Landscapes, CityAndArchitecture, Abstract, Animals, Macro, Travel, Fashion, Commercial, Concert, Sport, Nature, PerformingArts, Family, Street, Underwater, Food, FineArt, Wedding, Transportation, UrbanExploration
        
        var description: String {
            
            get {
                switch self {
                case .Uncategorized: return "Uncategorized"
                case .Celebrities: return "Celebrities"
                case .Film: return "Film"
                case .Journalism: return "Journalism"
                case .Nude: return "Nude"
                case .BlackAndWhite: return "Black And White"
                case .StillLife: return "Still Life"
                case .People: return "People"
                case .Landscapes: return "Landscapes"
                case .CityAndArchitecture: return "City And Architecture"
                case .Abstract: return "Abstract"
                case .Animals: return "Animals"
                case .Macro: return "Macro"
                case .Travel: return "Travel"
                case .Fashion: return "Fashion"
                case .Commercial: return "Commercial"
                case .Concert: return "Concert"
                case .Sport: return "Sport"
                case .Nature: return "Nature"
                case .PerformingArts: return "Performing Arts"
                case .Family: return "Family"
                case .Street: return "Street"
                case .Underwater: return "Underwater"
                case .Food: return "Food"
                case .FineArt: return "Fine Art"
                case .Wedding: return "Wedding"
                case .Transportation: return "Transportation"
                case .UrbanExploration: return "Urban Exploration"
                }
            }
        }
    }
}

class PhotoInfo: NSObject, ResponseObjectSerializable {
    let id: Int
    let url: String
    
    var name: String?
    
    var favoritesCount: Int?
    var votesCount: Int?
    var commentsCount: Int?
    
    var highest: Float?
    var pulse: Float?
    var views: Int?
    var camera: String?
    var focalLength: String?
    var shutterSpeed: String?
    var aperture: String?
    var iso: String?
    var category: Five100px.Category?
    var taken: String?
    var uploaded: String?
    var desc: String?
    
    var username: String?
    var fullname: String?
    var userPictureURL: String?
    
    init(id: Int, url: String) {
        self.id = id
        self.url = url
    }
    
    required init(response: NSHTTPURLResponse, representation: AnyObject) {
        self.id = representation.valueForKeyPath("photo.id") as! Int
        self.url = representation.valueForKeyPath("photo.image_url") as! String
        
        self.favoritesCount = representation.valueForKeyPath("photo.favorites_count") as? Int
        self.votesCount = representation.valueForKeyPath("photo.votes_count") as? Int
        self.commentsCount = representation.valueForKeyPath("photo.comments_count") as? Int
        self.highest = representation.valueForKeyPath("photo.highest_rating") as? Float
        self.pulse = representation.valueForKeyPath("photo.rating") as? Float
        self.views = representation.valueForKeyPath("photo.times_viewed") as? Int
        self.camera = representation.valueForKeyPath("photo.camera") as? String
        self.focalLength = representation.valueForKeyPath("photo.focal_length") as? String
        self.shutterSpeed = representation.valueForKeyPath("photo.shutter_speed") as? String
        self.aperture = representation.valueForKeyPath("photo.aperture") as? String
        self.iso = representation.valueForKeyPath("photo.iso") as? String
        self.taken = representation.valueForKeyPath("photo.taken_at") as? String
        self.uploaded = representation.valueForKeyPath("photo.created_at") as? String
        self.desc = representation.valueForKeyPath("photo.description") as? String
        self.name = representation.valueForKeyPath("photo.name") as? String
        
        self.username = representation.valueForKeyPath("photo.user.username") as? String
        self.fullname = representation.valueForKeyPath("photo.user.fullname") as? String
        self.userPictureURL = representation.valueForKeyPath("photo.user.userpic_url") as? String
    }
    
    override func isEqual(object: AnyObject!) -> Bool {
        return (object as! PhotoInfo).id == self.id
    }
    
    override var hash: Int {
        return (self as PhotoInfo).id
    }
}

final class Comment: ResponseCollectionSerializable {
    @objc static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [Comment] {
        var comments = [Comment]()
        for comment in representation.valueForKeyPath("comments") as! [NSDictionary] {
            comments.append(Comment(JSON: comment))
        }
        return comments
    }
    let userFullname: String
    let userPictureURL: String
    let commentBody: String
    init(JSON: AnyObject) {
        userFullname = JSON.valueForKeyPath("user.fullname") as! String
        userPictureURL = JSON.valueForKeyPath("user.userpic_url") as! String
        commentBody = JSON.valueForKeyPath("body") as! String
    }
}