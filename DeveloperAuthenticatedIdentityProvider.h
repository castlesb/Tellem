//
//  DeveloperAuthenticatedIdentityProvider.h
//  Tellem
//
//  Created by Brian Castles on 1/18/16.
//  Copyright © 2016 Brian Castles. All rights reserved.
//

#import <AWSCore/AWSCore.h>

@class DeveloperAuthenticationClient;

@interface DeveloperAuthenticatedIdentityProvider : AWSAbstractCognitoIdentityProvider

@property (strong, atomic, readonly) DeveloperAuthenticationClient *client;

- (instancetype)initWithRegionType:(AWSRegionType)regionType
                        identityId:(NSString *)identityId
                    identityPoolId:(NSString *)identityPoolId
                            logins:(NSDictionary *)logins
                      providerName:(NSString *)providerName
                        authClient:(DeveloperAuthenticationClient *)client;

@end