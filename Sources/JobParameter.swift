//
//  JobParameter.swift
//  PackageTest
//
//  Created by Patrick Butkiewicz on 8/25/16.
//
//

import Foundation

public struct JobParameter {
    
    private(set) var description: String = ""
    private(set) var name: String = ""
    private(set) var parameterType: JobParamaterType = .Unknown
    private(set) var parameter: AnyObject? = nil
    
    init(json: JSON) {
        if let desc = json["description"] as? String {
            self.description = desc
        }
        
        if let name = json["name"] as? String {
            self.name = name
        }
        
        if let paramType = json["type"] as? String {
            self.parameterType = JobParamaterType(type: paramType)
        }
        
        if let defaultValueBlock = json["defaultParameterValue"] as? JSON,
             let defaultValue = defaultValueBlock["value"] {
                self.parameter = defaultValue
        }
    }
    
}

public enum JobParamaterType: String {
    case String
    case Boolean
    case Unknown
    
    init(type: String) {
        switch type {
        case "hudson.model.StringParameterDefinition":
            self = .String
        case "hudson.model.BooleanParameterDefinition":
            self = .Boolean
        default:
            self = .Unknown
        }
    }
}
