//
//  InfinitScreenshotManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 25/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MASShortcut.h"

@interface InfinitScreenshotManager : NSObject <NSMetadataQueryDelegate>

@property (nonatomic, readwrite) MASShortcut* area_shortcut;
@property (nonatomic, readwrite) MASShortcut* fullscreen_shortcut;

@property (nonatomic, readwrite) BOOL watch;

+ (instancetype)sharedInstance;

@end
