//
//  Crypto.h
//  Tellem
//
//  Created by Brian Castles on 1/18/16.
//  Copyright © 2016 Brian Castles. All rights reserved.
//

#include <UIKit/UIKit.h>

@interface Crypto: NSObject {
}

+(NSData *)decrypt:(NSString *)data key:(NSString *)key;
+(NSData *)aes128Decrypt:(NSData *)data key:(NSData *)key withIV:(NSData *)iv;

+(NSData *)hexDecode:(NSString *)hexString;
+(NSString *)hexEncode:(NSString *)string;

+(NSData *)sha256HMac:(NSData *)data withKey:(NSString *)key;

+(NSString *)generateRandomString;

@end