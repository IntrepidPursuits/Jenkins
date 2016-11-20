//
//  ApiClient.swift
//  Jenkins
//
//  Created by Patrick Butkiewicz on 8/19/16.
//
//

import Foundation

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

@objc
internal final class APIClient: NSObject {
    private(set) var host: String
    private(set) var path: String
    private(set) var port: Int
    private(set) var user: String
    private(set) var token: String
    private(set) var transport: String
    private(set) var baseURL: URL
    
    private var encodedAuthorizationHeader: String {
        if let encoded = "\(user):\(token)"
            .data(using: String.Encoding.utf8)?
            .base64EncodedString() {
            return "Basic \(encoded)"
        }
        
        return ""
    }
    
    init(host: String, port: Int, path: String = "", user: String, token: String, transport: String = "http") throws {
        self.host = host
        self.path = path
        self.port = port
        self.user = user
        self.token = token
        self.transport = transport
        
        let urlString = "\(self.transport)://\(self.host):\(self.port)/"
        guard let url = URL(string: urlString) else {
            throw APIError.InvalidHost
        }
        
        self.baseURL = url
    }
    
    func get(path: URL, rawResponse: Bool = false, headers: [String : String] = [:], params: [String : String] = [:], _ handler: @escaping (AnyObject?, Error?) -> Void) {
        let request: URLRequest = requestFor(path, method: .GET, headers: headers, params: params, body: nil)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request) { data, response, error in
            self.decodeResponse(response, rawOutput: rawResponse, data: data, error: error, handler: handler)
        }
        
        task.resume()
    }
    
    func post(path: URL, rawResponse: Bool = false, headers: [String : String] = [:], params: [String : String] = [:], body: String? = nil, _ handler: @escaping (AnyObject?, Error?) -> Void) {
        let bodyData: Data? = body?.data(using: String.Encoding.utf8)
        let request: URLRequest = requestFor(path, method: .POST, headers: headers, params: params, body: bodyData)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        let task = session.dataTask(with: request) { data, response, error in
            self.decodeResponse(response, rawOutput: rawResponse, data: data, error: error, handler: handler)
        }
        
        task.resume()
    }
    
    // MARK: Private Helpers
    
    private func requestFor(_ url: URL, method: APIMethod, headers: [String : String] = [:], params: [String : String] = [:], body: Data?) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: ApiClientTimeout)
        request.httpMethod = method.description
        request.addValue(encodedAuthorizationHeader, forHTTPHeaderField: "Authorization")
        
        _ = headers.map { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        if method == .POST {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        
        if let body = body {
            request.httpBody = body
        } else {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems: [URLQueryItem] = params.map {
//                if let val = $0.value as? String {
                    return URLQueryItem(name: $0.key, value: $0.value)
//                } else {
//                    return URLQueryItem(name: $0.key, value: String(describing: $0.value))
//                }
            }
            
            components?.queryItems = queryItems
            request.url = components?.url
        }
        
        return request
    }
    
    private func decodeResponse(_ response: URLResponse?, rawOutput: Bool, data: Data?, error: Error?, handler: @escaping (AnyObject?, Error?) -> Void) {
        guard let data = data else {
            handler(nil, error)
            return
        }
        
        if let _ = error {
            handler(nil, error)
            return
        }
        
        if let response = response as? HTTPURLResponse {
            if response.statusCode >= 400 {
                print(response)
                let error = JenkinsError(httpStatusCode: response.statusCode)
                handler(nil, error)
            }
        }
        
        if rawOutput {
            handler(String(data: data, encoding: String.Encoding.utf8) as AnyObject?, nil)
        } else {
            let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            handler(json as AnyObject?, nil)
        }
    }
    
}

extension APIClient: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
