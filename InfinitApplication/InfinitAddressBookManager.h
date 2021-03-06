//
//  InfinitAddressBookManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 21/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitAddressBookManager : NSObject

+ (instancetype)sharedInstance;

/// Will only upload contacts if they haven't been yet.
- (void)uploadContacts;

- (ABPerson*)personFromContact:(NSString*)contact;

@end
