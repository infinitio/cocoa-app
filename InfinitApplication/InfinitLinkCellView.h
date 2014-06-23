//
//  InfinitLinkCellView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Gap/InfinitLinkTransaction.h>

#import "IAHoverButton.h"
#import "InfinitLinkProgressIndicator.h"
#import "InfinitLinkClickCountView.h"
#import "InfinitLinkFileIconView.h"

@protocol InfinitLinkCellProtocol;

@interface InfinitLinkCellView : NSTableCellView

@property (nonatomic, weak) IBOutlet InfinitLinkFileIconView* icon_view;
@property (nonatomic, weak) IBOutlet NSTextField* name;
@property (nonatomic, weak) IBOutlet NSTextField* information;
@property (nonatomic, weak) IBOutlet InfinitLinkClickCountView* click_count;
@property (nonatomic, weak) IBOutlet IAHoverButton* cancel;
@property (nonatomic, weak) IBOutlet IAHoverButton* link;
@property (nonatomic, weak) IBOutlet IAHoverButton* clipboard;
@property (nonatomic, weak) IBOutlet InfinitLinkProgressIndicator* progress_indicator;

@property (nonatomic, readwrite) CGFloat progress;

- (void)setupCellWithLink:(InfinitLinkTransaction*)link
              andDelegate:(id<InfinitLinkCellProtocol>)delegate
         withOnlineStatus:(gap_UserStatus)status;

@end

@protocol InfinitLinkCellProtocol <NSObject>

- (void)linkCell:(InfinitLinkCellView*)sender
gotCopyToClipboardForLink:(InfinitLinkTransaction*)link;

- (void)linkCell:(InfinitLinkCellView*)sender
gotCancelForLink:(InfinitLinkTransaction*)link;

@end
