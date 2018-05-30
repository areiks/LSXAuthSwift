# LSXAuthSwift

LSXAuthSwift is a lightweight xAuth (version of OAuth 1.0a) authorization header generator written in Swift. LSXAuthSwift can be used with any networking library in which you are able to set custom headers. Example project is using Alamofire. LSXAuthSwift was designed and tested with **Instapaper API** and for now this is the only xAuth API that is known to work. 

## Origin

When I was trying to connect to Instapaper API from the swift project it took me quite a long time to make it work. I have not found any working library written in Swift. Also preparing headers myself caused me a little bit of pain. Thats why I would like to share this one class project with the community.

## What is xAuth

According to http://oauthbible.com:

> xAuth is a way for desktop and mobile apps to get an OAuth access token from a user’s email and password, and it is still OAuth. So the third-party will ask for your credentials on the origin service to authenticate with.
The xAuth process will give back read-only, or read-write access tokens. Some limitations can apply, as in the Twitter spec Direct Messages read access is not provided and you must use the full flow.

1. Application Requests User Credentials
2. Application creates signed request for Access Token:
* oauth_consumer_key
* oauth_timestamp
* oauth_nonce
* oauth_signature
* oauth_signature_method
* oauth_version Optional
* oauth_callback

Along with additional parameters:
* x_auth_mode = client_auth
* x_auth_username
* x_auth_password
* x_auth_permission Optional
3. Service validates user details and grants Access Token
* oauth_token
* oauth_token_secret
4. Application uses Access Token to retrieve protected resources.

## Setup

To use LSXAuthSwift you just need to copy LSXAuthSwift.swift file into your project. File contains all of the extensions it requires to run (please check them). The only thing you need to do is to add bridging header with CommonCrypto import:

	#import <CommonCrypto/CommonCrypto.h>

To setup example project you need to download it and run pod install. Example project is using Alamofire which is obtained by cocoapods. 

Don't forget to set consumer key and consumer secret obtained after the registration (in example project you need to replace empty strings in AppDelegate):

	LSXAuthSwift.setConsumerKey(consumerKey: "", consumerSecret: "")

## Usage
	
Obtain token and token secret by making the request with xAuth username and xAuth password. To generate authorization header use **generateAuthorizationHeader(url: String, params: Dictionary<String, String>) -> String**.

	let params = ["x_auth_username" : login, "x_auth_password" : password, "x_auth_mode":"client_auth"]
            
	var authorizationHeader = LSXAuthSwift.generateAuthorizationHeader(url: accessTokenUrl, params: params)
            
	var headers = [
		"Authorization" : authorizationHeader,
		"Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
	]
            
	Alamofire.request(accessTokenUrl, method: .post, parameters: params, encoding: URLEncoding.default, headers: headers).responseString { (response) in
		//handle response with token and token secret
	}

After succesfull request you need to parse the response and set tokens in LSXAuthSwift (example project contains the code working with Instapaper):

	LSXAuthSwift.setOauthToken(oauthToken: oauthToken, oauthTokenSecret: oauthTokenSecret)
	
Finally you can make signed requests to Instapaper API. To generate header without parameters use **generateAuthorizationHeader(url: String) -> String**:

	authorizationHeader = LSXAuthSwift.generateAuthorizationHeader(url: verifyCredentialsUrl)
                    
	headers = [
		"Authorization" : authorizationHeader,
		"Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
		"Accept":"application/json"
	]
                    
	Alamofire.request(verifyCredentialsUrl, method: .post, parameters: [:], encoding: URLEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in 
	
	})
	
It is also possible to generate header with parameters (parameters need also to be encrypted). To achieve this use **generateAuthorizationHeader(url: String, params: [String:String]) -> String**:
	
	let parameters = [
		"limit":String(500)
	]
        
	let authorizationHeader = XAuthSwift.generateAuthorizationHeader(url: InstapaperEndpoint.ListBookmarks.path, params: parameters)
        
	let headers = [
		"Authorization":authorizationHeader,
		"Content-Type":"application/x-www-form-urlencoded; charset=utf-8",
		"Accept":"application/json"
	]
        
	Alamofire.request(InstapaperEndpoint.ListBookmarks.path, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers).responseJSON(completionHandler: { (response) in 
	
	})
	
To check if token is already set use **isAccessTokenAvailable()**
	
## Contribution

Let me know for which API's are you using LSXAuthSwift and what did you need to change in the code to make it work (if anything). I may add support for additional API's later on. 

## Credits

Icon comes from https://icons8.com. Some parts of the code were found by me all over the Internet and modified by me during my trials with Instapaper Api connection. If any of the original authors have something against sharing it here - let me know. If you would like to be included in credits section also let me know. 
	

