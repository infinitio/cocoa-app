//
//  IAConversationProgressBar.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/23/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IAConversationProgressBar : NSProgressIndicator

@property (nonatomic, setter = setDoubleValue:) double doubleValue;
@property (nonatomic, setter = setIndeterminate:) BOOL indeterminate;
@property (nonatomic) NSNumber* totalSize;

@end
