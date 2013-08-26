//
//  IAConversationCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/15/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IAConversationElement.h"


@interface IAConversationBubbleView : NSView
@end

@interface IAConversationCellView : NSTableCellView <NSTableViewDataSource,
                                                     NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet IAConversationBubbleView* bubble_view;
@property (nonatomic, strong) IBOutlet NSTextField* date;
@property (nonatomic, strong) IBOutlet NSButton* files_icon;
@property (nonatomic, strong) IBOutlet NSTextField* files_label;
@property (nonatomic, strong) IBOutlet NSTextField* information_text;
@property (nonatomic, strong) IBOutlet NSButton* message_button;
@property (nonatomic, strong) IBOutlet NSTextField* message_text;
@property (nonatomic, strong) IBOutlet NSProgressIndicator* progress_indicator;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;

+ (CGFloat)heightOfCellWithElement:(IAConversationElement*)element;

- (void)setupCellWithElement:(IAConversationElement*)element;

- (void)updateProgress;

@end
