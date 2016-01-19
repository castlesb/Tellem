//
//  DeveloperAuthenticationClient.h
//  Tellem
//
//  Created by Brian Castles on 1/18/16.
//  Copyright © 2016 Brian Castles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UICKeyChainStore/UICKeyChainStore.h>

FOUNDATION_EXPORT NSString *const LoginURI;
FOUNDATION_EXPORT NSString *const GetTokenURI;
FOUNDATION_EXPORT NSString *const DeveloperAuthenticationClientDomain;
typedef NS_ENUM(NSInteger, DeveloperAuthenticationClientErrorType) {
    DeveloperAuthenticationClientInvalidConfig,
    DeveloperAuthenticationClientDecryptError,
    DeveloperAuthenticationClientLoginError,
    DeveloperAuthenticationClientUnknownError,
};

@class AWSTask;

@interface DeveloperAuthenticationResponse : NSObject

@property (nonatomic, strong, readonly) NSString *identityId;
@property (nonatomic, strong, readonly) NSString *identityPoolId;
@property (nonatomic, strong, readonly) NSString *token;

@end

@interface DeveloperAuthenticationClient : NSObject

@property (nonatomic, strong) NSString *appname;
@property (nonatomic, strong) NSString *endpoint;

+ (instancetype)identityProviderWithAppname:(NSString *)appname endpoint:(NSString *)endpoint;
- (instancetype)initWithAppname:(NSString *)appname endpoint:(NSString *)endpoint;

- (BOOL)isAuthenticated;
- (AWSTask *)getToken:identityId logins:(NSDictionary *)logins;
- (AWSTask *)login:(NSString *)username password:(NSString *)password;
- (void)logout;

@end