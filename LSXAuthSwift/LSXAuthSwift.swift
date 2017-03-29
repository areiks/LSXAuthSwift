//
//  LSXAuthSwift.swift
//  LSXAuthSwift
//
//  Created by Lukasz Skierkowski on 28.03.2017.
//  Copyright © 2017 Lukasz Skierkowski. All rights reserved.
//

import Foundation

class LSXAuthSwift {
    
    private struct XAuthData {
        static var oauthToken = ""
        static var oauthTokenSecret = ""
        static var consumerKey = ""
        static var consumerSecret = ""
        static let signatureMethod = "HMAC-SHA1"
        static let authVersion = "1.0"
    }
    
    class private func defaultParameter() -> Dictionary<String, String> {
        var parameters = Dictionary<String, String>()
        parameters["oauth_consumer_key"] = XAuthData.consumerKey
        parameters["oauth_signature_method"] = XAuthData.signatureMethod
        parameters["oauth_timestamp"] = String(Int64(Date().timeIntervalSince1970))
        parameters["oauth_nonce"] = generateNonce()
        parameters["oauth_version"] = XAuthData.authVersion
        parameters["oauth_token"] = XAuthData.oauthToken
        //parameters["oauth_callback"] = "https://localhost"
        
        return parameters
    }
    
    class private func generateNonce() -> String {
        let uuidString = UUID().uuidString
        let startIndex = uuidString.index(uuidString.startIndex, offsetBy: 7)
        return uuidString.substring(to: startIndex)
    }
    
    class private func parameterBuilder(url: String, param: Dictionary<String, String>) -> String {
        var parameters = defaultParameter()
        let defaultParam = parameters
        for (key, value) in param {
            parameters[key] = value
        }
        
        parameters["oauth_signature"] = signatureOauth(url: url, parameters: parameters)
        
        var authorizationParam = defaultParam
        authorizationParam["oauth_signature"] = parameters["oauth_signature"]
        var authorizationParameterComponents = authorizationParam.urlEncodedQuery.components(separatedBy: "&") as [String]
        authorizationParameterComponents.sort { $0 < $1 }
        
        var headerComponents = [String]()
        for component in authorizationParameterComponents {
            let subcomponent = component.components(separatedBy:"=") as [String]
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        
        let header = "OAuth " + headerComponents.joined(separator: ", ")
        
        return header
    }
    
    class private func signatureOauth(url: String, parameters: Dictionary<String, String>) -> String {
        let encodedTokenSecret = XAuthData.oauthTokenSecret.urlEncodedString
        let encodedConsumerSecret = XAuthData.consumerSecret.urlEncodedString
        
        let signingKey = "\(encodedConsumerSecret)&\(encodedTokenSecret)"
        
        var parameterComponents = parameters.urlEncodedQuery.components(separatedBy: "&")
        parameterComponents.sort {
            let p0 = $0.components(separatedBy: "=")
            let p1 = $1.components(separatedBy: "=")
            if p0.first == p1.first { return p0.last ?? "" < p1.last ?? "" }
            return p0.first ?? "" < p1.first ?? ""
        }
        
        let parameterString = parameterComponents.joined(separator: "&")
        let encodedParameterString = parameterString.urlEncodedString
        
        let encodedURL = url.urlEncodedString
        //Instapaper allows only POST 
        let method = "POST"
        
        let signatureBaseString = "\(method)&\(encodedURL)&\(encodedParameterString)"
        
        let key = signingKey
        let msg = signatureBaseString
        
        let hmacResult: String = msg.hmac(algorithm: HMACAlgorithm.SHA1, key: key)
        
        return hmacResult
    }
    
    class public func isAccessTokenAvailable() -> Bool {
        if (XAuthData.oauthToken != "" && XAuthData.oauthTokenSecret != "") {
            return true
        } else {
            return false
        }
    }
    
    class public func setConsumerKey(consumerKey: String, consumerSecret:String) {
        XAuthData.consumerKey = consumerKey
        XAuthData.consumerSecret = consumerSecret
    }
    
    class public func setOauthToken(oauthToken: String, oauthTokenSecret: String) {
        XAuthData.oauthToken = oauthToken
        XAuthData.oauthTokenSecret = oauthTokenSecret
    }
    
    class public func generateAuthorizationHeader(url: String, params: Dictionary<String, String>) -> String {
        
        let authorizationHeader = parameterBuilder(url: url, param: params)
        
        return authorizationHeader
    }
    
    class public func generateAuthorizationHeader(url: String) -> String {
        
        let authorizationHeader = parameterBuilder(url: url, param: [:])
        
        return authorizationHeader
    }
    
}

extension String {
    
    //also possible with:
    /*
     func encode() -> String {
     return addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
     }
     */
    
    var urlEncodedString: String {
        let customAllowedSet =  CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        let escapedString = self.addingPercentEncoding(withAllowedCharacters: customAllowedSet)
        return escapedString!
    }
    
    func hmac(algorithm: HMACAlgorithm, key: String) -> String {
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(algorithm.digestLength()))
        CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData:NSData = NSData(bytes: result, length: (Int(algorithm.digestLength())))
        let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength76Characters)
        return String(hmacBase64)
    }
    
}

extension Dictionary {
    
    var urlEncodedQuery: String {
        var parts = [String]()
        
        for (key, value) in self {
            let keyString = "\(key)".urlEncodedString
            let valueString = "\(value)".urlEncodedString
            let query = "\(keyString)=\(valueString)"
            parts.append(query)
        }
        
        return parts.joined(separator: "&")
    }
}

enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func toCCHmacAlgorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}
