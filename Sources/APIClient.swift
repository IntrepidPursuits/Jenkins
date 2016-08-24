//
//  ApiClient.swift
//  Jenkins
//
//  Created by Patrick Butkiewicz on 8/19/16.
//
//

import Foundation

typealias JSON = [String: AnyObject]
private let ApiClientTimeout: TimeInterval = 30

internal enum APIError: Error {
    case InvalidHost
    case InvalidConnection
    case NotFound
    case ParsingError
    case UnknownError
}

internal enum APIMethod: String, CustomStringConvertible {
    case POST
    case GET
    
    var description: String {
        switch self {
        case .GET:  return "GET"
        case .POST: return "POST"
        }
    }
}

internal final class APIClient {
    private(set) var host: String
    private(set) var path: String?
    private(set) var port: Int
    private(set) var user: String
    private(set) var token: String
    private(set) var transport: String
    private(set) var baseURL: URL
    
    private var basicAuth: (String, String) {
        return (self.user, self.token)
    }
    
    init(host: String, port: Int, path: String? = "", user: String, token: String, transport: String = "http") throws {
        self.host = host
        self.path = path
        self.port = port
        self.user = user
        self.token = token
        self.transport = transport
        
        guard let url = URL(string:"\(self.transport)://\(self.host):\(self.port)/\(self.path)") else {
            throw APIError.InvalidHost
        }
        self.baseURL = url
    }
    
    func get(path: URL, rawResponse: Bool = false, headers: [String : String] = [:], params: [String : AnyObject] = [:], _ handler: (AnyObject?) -> (Void)) {
        let request: URLRequest = requestFor(path, method: .GET, headers: headers, params: params, body: nil)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                handler(nil)
                return
            }
            
            if let _ = error {
                handler(nil)
                return
            }
            
            let retVal: AnyObject? = (rawResponse == true)
                ? String(data: data, encoding: String.Encoding.utf8)
                : try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            
            handler(retVal)
        }
        
        task.resume()
    }
    
    func post(path: URL, rawResponse: Bool = false, headers: [String : String] = [:], params: [String : AnyObject] = [:], body: String? = nil, _ handler: (AnyObject?) -> Void) {
        let bodyData: Data? = body?.data(using: String.Encoding.utf8)
        let request: URLRequest = requestFor(path, method: .POST, headers: headers, params: params, body: bodyData)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                handler(nil)
                return
            }

            if let _ = error {
                handler(nil)
                return
            }

            let retVal: AnyObject? = (rawResponse == true)
                ? String(data: data, encoding: String.Encoding.utf8)
                : try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            
            handler(retVal)
        }
        
        task.resume()
    }
    
    private func requestFor(_ url: URL, method: APIMethod, headers: [String : String] = [:], params: [String : AnyObject] = [:], body: Data?) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: ApiClientTimeout)
        request.httpMethod = method.description
        
        _ = headers.map { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        if let body = body {
            request.httpBody = body
        } else {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems: [URLQueryItem] = params.map {
                if let val = $0.value as? String {
                    return URLQueryItem(name: $0.key, value: val)
                } else {
                    return URLQueryItem(name: $0.key, value: String($0.value))
                }
            }
            
            components?.queryItems = queryItems
            request.httpBody = components?.percentEncodedQuery?.data(using: String.Encoding.utf8)
        }
        
        return request
    }
    
}

extension APIClient {
    func apiURLByAppendingPath(_ path: String?) -> String {
        guard let path = path else {
            return baseURL.appendingPathComponent("api")
                .appendingPathComponent("json")
                .absoluteString
        }
        
        let fixedPath = (path.contains(baseURL.absoluteString))
            ? path.stringByReplacingFirstOccurrenceOfString(baseURL.absoluteString, withString: "")
            : path
        
        return baseURL.appendingPathComponent(fixedPath)
            .appendingPathComponent("api")
            .appendingPathComponent("json")
            .absoluteString
    }
}

private extension String {
    func stringByReplacingFirstOccurrenceOfString(_ target: String, withString replaceString: String) -> String {
        if let range = self.range(of: target){
            return self.replacingCharacters(in: range, with: replaceString)
        }
        return self
    }
}