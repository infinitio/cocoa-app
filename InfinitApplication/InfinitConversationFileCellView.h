//
//  InfinitConversationFileCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 24/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InfinitConversationFileCellView : NSTableCellView

@property (nonatomic, readwrite) BOOL clickable;
@property (nonatomic, readonly) NSTextField* file_name;

- (id)initWithFrame:(NSRect)frame
             onLeft:(BOOL)on_left;

- (void)setFileName:(NSString*)name;

@end
