//
//  JobConfiguration.swift
//  Jenkins
//
//  Created by Patrick Butkiewicz on 8/22/16.
//
//

import Foundation

public typealias JobConfiguration = String

// MARK: Job Configuration

public extension Jenkins {
    func fetchJobConfiguration(_ job: Job, _ handler: @escaping (_ response: String?, _ error: Error?) -> Void) {
        fetchJobConfiguration(job.name, handler)
    }
    
    func fetchJobConfiguration(_ name: String, _ handler: @escaping (_ response: String?, _ error: Error?) -> Void) {
        guard let url = URL(string: jobURL)?
            .appendingPathComponent(name)
            .appendingPathComponent("config.xml") else {
                handler(nil, JenkinsError.InvalidJenkinsURL)
                return
        }
        
        fetchJobConfiguration(url: url, handler)
    }
    
    func fetchJobConfiguration(url: URL, _ handler: @escaping (_ response: String?, _ error: Error?) -> Void) {
        client?.get(path: url, rawResponse: true) { xml, error in
            
            if let xml = xml as? String {
                handler(xml, nil)
                return
            }
            
            handler(nil, error)
        }
    }
}

// MARK: Job Configuration crud operations

public extension Jenkins {
    private var createCopyPath: String { return "/createItem" }
    
    func copy(_ job: Job, to: String, _ handler: @escaping (_ error: Error?) -> Void) {
        copy(job.name, to: to, handler)
    }
    
    func copy(_ name: String, to: String, _ handler: @escaping (_ error: Error?) -> Void) {
        guard let copyFromJob = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let copyToJob = to.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
                handler(JenkinsError.InvalidJenkinsURL)
                return
        }
        
        guard var url = URLComponents(string: jenkinsURL) else {
            handler(JenkinsError.InvalidJenkinsURL)
            return
        }
        
        url.path = createCopyPath
        url.queryItems = [
            URLQueryItem(name: "name", value: copyToJob),
            URLQueryItem(name: "mode", value: "copy"),
            URLQueryItem(name: "from", value: copyFromJob),
        ]
        
        client?.post(path: url.url!) { response, error in
            handler(error)
        }
    }
    
    func create(_ job: Job, configuration: JobConfiguration, _ handler: @escaping (_ error: Error?) -> Void) {
        create(job.name, configuration: configuration, handler)
    }
    
    func create(_ name: String, configuration: JobConfiguration, _ handler: @escaping (_ error: Error?) -> Void) {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            handler(JenkinsError.InvalidJenkinsURL)
            return
        }
        
        let queryItem = URLQueryItem(name: "name", value: encodedName)
        
        guard var url = URLComponents(string: jenkinsURL) else {
                handler(JenkinsError.InvalidJenkinsURL)
                return
        }
        
        url.path = createCopyPath
        url.queryItems = [queryItem]
        
        client?.post(path: url.url!, headers: ["Content-Type" : "text/xml"], body: configuration) { response, error in
            handler(error)
        }
    }
    
    func update(_ job: Job, description: String, _ handler: @escaping (_ error: Error?) -> Void) {
        update(job.name, description: description, handler)
    }
    
    func update(_ name: String, description: String, _ handler: @escaping (_ error: Error?) -> Void) {
        guard let url = URL(string: jobURL)?
            .appendingPathComponent(name)
            .appendingPathComponent("description") else {
                handler(JenkinsError.InvalidJenkinsURL)
                return
        }
        
        client?.post(path: url, params: ["description" : description]) { response, error in
            handler(error)
        }
    }
    
    func update(_ job: Job, configuration: JobConfiguration, _ handler: @escaping (_ error: Error?) -> Void) {
        update(job.name, configuration: configuration, handler)
    }
    
    func update(_ name: String, configuration: JobConfiguration, _ handler: @escaping (_ error: Error?) -> Void) {
        guard let url = URL(string: jobURL)?
            .appendingPathComponent(name)
            .appendingPathComponent("config.xml") else {
                handler(JenkinsError.InvalidJenkinsURL)
                return
        }
        
        client?.post(path: url, body: configuration) { response, error in
            handler(error)
        }
    }
    
    func delete(_ job: Job, _ handler: @escaping (Error?) -> Void) {
        delete(job.name, handler)
    }
    
    func delete(_ name: String, _ handler: @escaping (Error?) -> Void) {
        guard let url = URL(string: jobURL)?
            .appendingPathComponent(name)
            .appendingPathComponent("doDelete") else {
                handler(JenkinsError.InvalidJenkinsURL)
                return
        }
        
        client?.post(path: url) { response, error in
            handler(error)
        }
    }

}

