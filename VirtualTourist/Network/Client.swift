//
//  Client.swift
//  VirtualTourist
//
//  Created by Amr fawzy on 4/22/19.
//  Copyright © 2019 Amr fawzy. All rights reserved.
//

import Foundation
import MapKit

class Client : NSObject {
    override init() {
        super.init()
    }
    
    func buildURL(host: String, apiPath: String, parameters: [String:AnyObject]?) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.APIScheme
        components.host = host
        components.path = apiPath
        components.queryItems = [URLQueryItem]()
        if(parameters != nil)
        {
            for (key, value) in parameters!
            {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                components.queryItems!.append(queryItem)
            }
        }
        
        return components.url!
    }
    
    
    func configureRequest(url: URL, methodType: String, headers: [String: String]?, jsonBody: String?)->URLRequest
    {
        var request = URLRequest(url: url)
        
        request.httpMethod = methodType
        
        if(headers != nil)
        {
            for(key, value) in headers!
            {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if(jsonBody != nil)
        {
            request.httpBody = jsonBody!.data(using: .utf8)
        }
        
        return request
    }
    
    func makeNetworkRequest(request: URLRequest, ignoreInitialCharacters: Bool, completionHandler: @escaping (AnyObject?,Error?)->Void)
    {
        let task = URLSession.shared.dataTask(with: request)
        {
            data, response, error in
            
            func sendError(_ error: String)
            {
                print(error)
                let internetOfflineErrorMessage = "NSURLErrorDomain Code=-1009"
                let userInfo = [NSLocalizedDescriptionKey : error]
                if(error.contains(internetOfflineErrorMessage))
                {
                    completionHandler(nil, NSError(domain: "noInternetConnection", code: 1, userInfo: userInfo))
                }
                else
                {
                    completionHandler(nil, NSError(domain: "makeNetworkRequest", code: 2, userInfo: userInfo))
                }
            }
            
            // GUARD: Was there an error?
            guard (error == nil) else
            {
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else
            {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else
            {
                sendError("No data was returned by the request!")
                return
            }
            
            // Parse the data and use the data (happens in completion handler)
            let (parsedResult, error) = self.parseData(data: data, ignoreInitialCharacters: ignoreInitialCharacters)
            completionHandler(parsedResult, error)
        }
        
        task.resume()
    }
    
    private func parseData(data: Data, ignoreInitialCharacters: Bool)->(AnyObject?, Error?)
    {
        var actualData: Data
        if(ignoreInitialCharacters)
        {
            let range = Range(5..<data.count)
            actualData = data.subdata(in: range)
        }
        else
        {
            actualData = data
        }
        
        var result: (AnyObject?, Error?)
        
        do
        {
            let parsedResult = try JSONSerialization.jsonObject(with: actualData, options: .allowFragments) as AnyObject
            print(parsedResult)
            result = (parsedResult, nil)
        }
        catch
        {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(actualData)'"]
            let error = NSError(domain: "processData", code: 2, userInfo: userInfo)
            result = (nil, error)
        }
        
        return result
    }
    
    class func sharedInstance() -> Client
    {
        struct Singleton
        {
            static var sharedInstance = Client()
        }
        return Singleton.sharedInstance
    }
}



extension Client
{
    func getPhotos(latitude: CLLocationDegrees?, longitude:CLLocationDegrees?, completionHandler: @escaping (_ success: Bool,_ totalImages: Int, _ pages: Int, _ perPage: Int, _ errorString: String?)->Void)
    {
        // Build URL
        let URL : URL
        var parameters : [String: AnyObject] = [:]
        
        // Add the method
        parameters[Constants.FlickrParameterKeys.Method] = Constants.FlickrParameterKeys.MethodValue as AnyObject
        parameters[Constants.FlickrParameterKeys.Format] = Constants.FlickrParameterKeys.FormatValue as AnyObject
        parameters[Constants.FlickrParameterKeys.APIKey] = Constants.FlickrParameterKeys.APIValue as AnyObject
        parameters[Constants.FlickrParameterKeys.BoundingBox] = bboxString(latitude: latitude!, longitude: longitude!) as AnyObject
        parameters[Constants.FlickrParameterKeys.SafeSearch] = Constants.FlickrParameterKeys.SafeSearchValue as AnyObject
        parameters[Constants.FlickrParameterKeys.NoJSONCallback] = Constants.FlickrParameterKeys.NoJSONCallbackValue as AnyObject
        
        URL = buildURL(host: Constants.APIHost, apiPath: Constants.APIPath, parameters: parameters)
        
        let request = configureRequest(url: URL, methodType: "GET", headers: nil, jsonBody: nil)
        
        makeNetworkRequest(request: request, ignoreInitialCharacters: false)
        {
            (results: AnyObject?, error: Error?)->Void in
            
            guard (error == nil) else
            {
                print(error!)
                if((error! as NSError).domain == "CheckYournetworkConnection")
                {
                    completionHandler(false, 0, 0, 0, "Check your network connection")
                }
                else
                {
                    completionHandler(false, 0, 0, 0, "Error downloading results from Flickr")
                }
                
                return
            }
            
            
            let photos = results?["photos"] as! [String: AnyObject]
            let totalImages = Int((photos["total"]! as? String)!)
            let pages = photos["pages"]! as? Int
            let perpage = photos["perpage"]! as? Int
            
            completionHandler(true, totalImages!,pages!,perpage!, nil)
        }
    }
    
    func getRandomPhotos(latitude: CLLocationDegrees?, longitude:CLLocationDegrees?, totalImages: Int, totalPages: Int, perPage: Int, maxPhotos: Int, completionHandler: @escaping (_ success: Bool,_ imageURLs:[String],_ errorString: String?)->Void)
    {
        let URL : URL
        var parameters : [String: AnyObject] = [:]
        
        let highestPageIndex = min(totalPages, 4000/perPage)
        let randomPageIndex = Int(arc4random_uniform(UInt32(highestPageIndex))) + 1
        
        parameters[Constants.FlickrParameterKeys.Method] = Constants.FlickrParameterKeys.MethodValue as AnyObject
        parameters[Constants.FlickrParameterKeys.Format] = Constants.FlickrParameterKeys.FormatValue as AnyObject
        parameters[Constants.FlickrParameterKeys.APIKey] = Constants.FlickrParameterKeys.APIValue as AnyObject
        parameters[Constants.FlickrParameterKeys.BoundingBox] = bboxString(latitude: latitude!, longitude: longitude!) as AnyObject
        parameters[Constants.FlickrParameterKeys.SafeSearch] = Constants.FlickrParameterKeys.SafeSearchValue as AnyObject
        parameters[Constants.FlickrParameterKeys.Extras] = Constants.FlickrParameterKeys.ExtrasValue as AnyObject
        parameters[Constants.FlickrParameterKeys.NoJSONCallback] = Constants.FlickrParameterKeys.NoJSONCallbackValue as AnyObject
        parameters[Constants.FlickrParameterKeys.Page] = randomPageIndex as AnyObject
        parameters[Constants.FlickrParameterKeys.PerPageKey] = perPage as AnyObject
        
        URL = buildURL(host: Constants.APIHost, apiPath: Constants.APIPath, parameters: parameters)
        
        let request = configureRequest(url: URL, methodType: "GET", headers: nil, jsonBody: nil)
        
        makeNetworkRequest(request: request, ignoreInitialCharacters: false)
        {
            (results: AnyObject?, error: Error?)->Void in
            
            // Check for error
            guard (error == nil) else
            {
                print(error!)
                if((error! as NSError).domain == "CheckYourNetworkConnection")
                {
                    completionHandler(false, [], "Check your network connection")
                }
                else
                {
                    completionHandler(false, [], "Error")
                }
                
                return
            }
            
            let photos = results?["photos"] as! [String: AnyObject]
            let photoArray = photos["photo"] as! [[String: AnyObject]]
            let numPhotos = min(photoArray.count, maxPhotos)
            var indexSet = Set<Int>()
            var randomPhotoIndex: Int
            while(indexSet.count < numPhotos)
            {
                repeat
                {
                    randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                }
                    while(indexSet.contains(randomPhotoIndex))
                
                indexSet.insert(randomPhotoIndex)
            }
            
            
            var imageURLs: [String] = []
            for index in indexSet
            {
                if(imageURLs.count < numPhotos)
                {
                    imageURLs.append(photoArray[index]["url_m"] as! String)
                }
                else
                {
                    break
                }
            }
            completionHandler(true, imageURLs, nil)
        }
    }
    
    func getImageFromUrl(urlString: String, completionHandler: @escaping (_ success: Bool, _ urlString:String?, _ imageData: Data?, _ errorString: String?)->Void)
    {
        let url = URL(string: urlString)
        
        let task = URLSession.shared.dataTask(with: url!)
        {
            data, response, error in
            
            func sendError(_ error: String)
            {
                print(error)
                let internetOfflineErrorMessage = "NSURLErrorDomain Code=-1009"
                // let userInfo = [NSLocalizedDescriptionKey : error]
                if(error.contains(internetOfflineErrorMessage))
                {
                    completionHandler(false, nil, nil, error)
                }
                else
                {
                    completionHandler(false, nil, nil, error)
                }
            }
            
            // GUARD: Was there an error?
            guard (error == nil) else
            {
                sendError("Request error: \(error!)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else
            {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else
            {
                sendError("Error")
                return
            }
            
            completionHandler(true, urlString, data, nil)
        }
        
        task.resume()
    }
    
    
    private func bboxString(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> String
    {
        let minimumLon = max(longitude - Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.1)
        
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
}

}
