//
//  IASearchResultsViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IAUserSearchViewProtocol;

@interface IAUserSearchViewController : NSViewController <NSTableViewDataSource,
                                                          NSTableViewDelegate,
                                                          NSTextViewDelegate>

@property (nonatomic, strong) IBOutlet NSButton* clear_search;
@property (nonatomic, strong) IBOutlet NSView* search_box_view;
@property (nonatomic, strong) IBOutlet NSTextField* search_field;
@property (nonatomic, strong) IBOutlet NSTableView* table_view;
@property (nonatomic, strong) IBOutlet NSScrollView* results_view;
@property (nonatomic, strong) IBOutlet NSTextField* no_results_message;

- (id)init;

- (void)setDelegate:(id<IAUserSearchViewProtocol>)delegate;

@end

@protocol IAUserSearchViewProtocol <NSObject>

- (void)searchView:(IAUserSearchViewController*)sender
       changedSize:(NSSize)size;

@end