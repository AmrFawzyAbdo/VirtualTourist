//
//  Constants.swift
//  VirtualTourist
//
//  Created by Amr fawzy on 4/22/19.
//  Copyright © 2019 Amr fawzy. All rights reserved.
//

import Foundation

class Constants {
    static let APIScheme = "https"
    static let APIHost = "api.flickr.com"
    static let APIPath = "/services/rest"
    
    static let SearchBBoxHalfWidth = 0.2
    static let SearchBBoxHalfHeight = 0.2
    static let SearchLatRange = (-90.0, 90.0)
    static let SearchLonRange = (-180.0, 180.0)
    static let maxImagesPerAlbum = 20
    
    
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let BoundingBox = "bbox"
        static let PhotosPerPage = "per_page"
        static let Accuracy = "accuracy"
        static let Page = "page"
        static let PerPageKey = "perpage"
        
        static let MethodValue = "flickr.photos.search"
        static let APIValue = "4b8ff19daaa5ad1d48632afac3a570fd"
        static let ExtrasValue = "url_m"
        static let FormatValue = "json"
        static let NoJSONCallbackValue = "1"
        static let SafeSearchValue = "1"
    }
    
    struct JSONResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
}
