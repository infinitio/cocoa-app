//
//  IAFWKeychain.m
//  FinderWindow
//
//  Created by Christopher Crone on 3/21/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import <Security/Security.h>

#import <Gap/IAGapState.h>
#import "IAKeychainManager.h"

@implementation IAKeychainManager

+ (IAKeychainManager*)sharedInstance
{
	static IAKeychainManager* keychain_manager = nil;
	if (keychain_manager == nil)
    {
		keychain_manager = [[IAKeychainManager alloc] init];
    }
    return keychain_manager;
}

- (id)init
{
	if (self = [super init])
    {
        _service_name = @"Infinit";
    }
	return self;
}

////Call SecKeychainFindGenericPassword to get a password from the keychain:
- (OSStatus)GetPasswordKeychain:(NSString*)user_email
                   passwordData:(void**)password_data
                 passwordLength:(UInt32*)password_length
                        itemRef:(SecKeychainItemRef*)itemRef
{
    OSStatus status;
    status = SecKeychainFindGenericPassword(
                                            NULL, // default keychain
                                            (UInt32)_service_name.length, // length of service name
                                            [_service_name cStringUsingEncoding:NSASCIIStringEncoding], // service name
                                            (UInt32)user_email.length, // length of account name
                                            [user_email cStringUsingEncoding:NSASCIIStringEncoding],   // account name
                                            password_length, // length of password
                                            password_data, // pointer to password data
                                            itemRef // the item reference
                                            );
    return (status);
}

//// Check if credentials are in keychain
- (BOOL)CredentialsInKeychain:(NSString*)email_address
{
    if ([self GetPasswordKeychain:email_address
                     passwordData:NULL
                   passwordLength:NULL
                          itemRef:NULL] == noErr)
        return YES;
    else
        return NO;
}

- (OSStatus)AddPasswordKeychain:(NSString*)user_email
                       password:(NSString*)password
{
    OSStatus status;
    SecAccessRef access;
    NSArray* trustedApplications = nil;
    NSString* app_path = [IAGapState.instance.protocol getApplicationPath];
    
    SecTrustedApplicationRef infinit_app;
    status = SecTrustedApplicationCreateFromPath(app_path.UTF8String, &infinit_app);
    if (status != noErr)
        return status;
    
    trustedApplications = [NSArray arrayWithObject:(__bridge id)infinit_app];
    
    status = SecAccessCreate((__bridge CFStringRef)_service_name,
                             (__bridge CFArrayRef)(trustedApplications),
                             &access);
    if (status != noErr)
        return status;
    
    SecKeychainAttribute attrs[] = {
        { kSecLabelItemAttr, (UInt32)_service_name.length, (void*)_service_name.UTF8String },
        { kSecAccountItemAttr, (UInt32)user_email.length, (void*)user_email.UTF8String },
        { kSecServiceItemAttr, (UInt32)_service_name.length, (void*)_service_name.UTF8String }
    };
    
    SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };
    
    status = SecKeychainItemCreateFromContent(
                                              kSecGenericPasswordItemClass,
                                              &attributes,
                                              (UInt32)password.length,
                                              password.UTF8String,
                                              NULL, // use the default keychain
                                              access,
                                              NULL
                                             );
    if (access) CFRelease(access);
    password = @"";
    password = nil;
    return status;
}

@end
