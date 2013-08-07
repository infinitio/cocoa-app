//
//  IASearchResultsViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAUserSearchViewController.h"

#import "IAAvatarManager.h"
#import "IASearchResultsCellView.h"

@interface IAUserSearchViewController ()
@end

@interface IASearchBoxView : NSView
@end

@implementation IASearchBoxView


- (void)drawRect:(NSRect)dirtyRect
{
    // White background
    NSBezierPath* white_bg = [NSBezierPath bezierPathWithRect:self.bounds];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_bg fill];
    
    // Grey Line
    NSRect grey_line_box = NSMakeRect(self.bounds.origin.x,
                                      self.bounds.origin.y + 1.0,
                                      self.bounds.size.width,
                                      1.0);
    NSBezierPath* grey_line = [NSBezierPath bezierPathWithOvalInRect:grey_line_box];
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
    [grey_line fill];
}

- (NSSize)intrinsicContentSize
{
    return self.frame.size;
}

@end

@interface IASearchResultsTableRowView : NSTableRowView
@end

@implementation IASearchResultsTableRowView

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Dark line
    NSRect dark_rect = NSMakeRect(self.bounds.origin.x,
                                  self.bounds.origin.y + self.bounds.size.height - 1.0,
                                  self.bounds.size.width,
                                  1.0);
    NSBezierPath* dark_line = [NSBezierPath bezierPathWithRect:dark_rect];
    [TH_RGBCOLOR(209.0, 209.0, 209.0) set];
    [dark_line fill];
    
    // White line
    NSRect white_rect = NSMakeRect(self.bounds.origin.x,
                                   self.bounds.origin.y + self.bounds.size.height - 2.0,
                                   self.bounds.size.width,
                                   1.0);
    NSBezierPath* white_line = [NSBezierPath bezierPathWithRect:white_rect];
    [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
    [white_line fill];
    
    if (self.selected)
    {
        // Background
        NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                    self.bounds.origin.y,
                                    self.bounds.size.width,
                                    self.bounds.size.height - 2.0);
        NSBezierPath* bg_path = [NSBezierPath bezierPathWithRect:bg_rect];
        [TH_RGBCOLOR(255.0, 255.0, 255.0) set];
        [bg_path fill];
    }
    else
    {
        // Background
        NSRect bg_rect = NSMakeRect(self.bounds.origin.x,
                                    self.bounds.origin.y,
                                    self.bounds.size.width,
                                    self.bounds.size.height - 2.0);
        NSBezierPath* bg_path = [NSBezierPath bezierPathWithRect:bg_rect];
        [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
        [bg_path fill];
    }
}

@end

@implementation IAUserSearchViewController
{
    id<IAUserSearchViewProtocol> _delegate;
    
    NSMutableArray* _search_results;
    
    BOOL _no_results;
    
    CGFloat _row_height;
    NSInteger _max_rows_shown;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _row_height = 42.0;
        _max_rows_shown = 5;
        _delegate = nil;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(avatarCallback:)
                                                   name:IA_AVATAR_MANAGER_AVATAR_FETCHED
                                                 object:nil];
    }
    
    return self;
}

- (void)setDelegate:(id<IAUserSearchViewProtocol>)delegate
{
    _delegate = delegate;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSString*)description
{
    return @"[SearchResultsViewController]";
}

- (void)awakeFromNib
{
    [self.clear_search setHidden:YES];
    [self.no_results_message setHidden:YES];
}

//- Avatar Callback --------------------------------------------------------------------------------

- (void)avatarCallback:(NSNotification*)notification
{
    IAUser* user = [notification.userInfo objectForKey:@"user"];
    if (![_search_results containsObject:user])
        return;
    
    [self.table_view reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[_search_results
                                                                            indexOfObject:user]]
                               columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

//- Search Functions -------------------------------------------------------------------------------

- (void)cancelLastSearchOperation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(doSearchNow)
                                               object:nil];
}

- (void)doDelayedSearch
{
    [self performSelector:@selector(doSearchNow)
               withObject:nil
               afterDelay:0.5];
}

- (void)doSearchNow
{
    [self cancelLastSearchOperation];
    NSString* search_string = self.search_field.stringValue;
    if ([IAFunctions stringIsValidEmail:search_string]) // Search using using email address
    {
        NSMutableDictionary* data = [NSMutableDictionary dictionaryWithObject:search_string
                                                                       forKey:@"entered_email"];
        [[IAGapState instance] getUserIdfromEmail:search_string
                                  performSelector:@selector(searchUserEmailCallback:)
                                         onObject:self withData:data];
    }
    else // Normal search
    {
        [[IAGapState instance] searchUsers:search_string
                           performSelector:@selector(searchResultsCallback:)
                                  onObject:self];
    }
}

- (void)searchUserEmailCallback:(IAGapOperationResult*)result
{
    if (!result.success)
    {
        IALog(@"%@ WARNING: Searching for email address failed", self);
        _search_results = nil;
        return;
    }
    
    NSDictionary* data = result.data;
    NSString* user_id = (NSString*)[data objectForKey:@"user_id"];
    if (![user_id isEqualToString:@""])
    {
        IAUser* user = [IAUser userWithId:user_id];
        _search_results = [NSMutableArray arrayWithObject:user];
    }
    else
    {
        _search_results = [NSMutableArray array];
    }
    [self updateResultsTable];
}

- (void)searchResultsCallback:(IAGapOperationResult*)results
{
    if (!results.success)
    {
        IALog(@"%@ WARNING: Searching for users failed with error: %d", self, results.status);
        _search_results = nil;
        return;
    }
    _search_results = [NSMutableArray arrayWithArray:results.data];
    [self updateResultsTable];
}

//- Search Field -----------------------------------------------------------------------------------

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    NSControl* control = aNotification.object;
    if (control == self.search_field)
    {
        if (self.search_field.stringValue.length == 0)
        {
            [self.clear_search setHidden:YES];
            [self clearResults];
            [self cancelLastSearchOperation];
        }
        else
        {
            [self.clear_search setHidden:NO];
            [self.no_results_message setHidden:YES];
            [self cancelLastSearchOperation];
            [self doDelayedSearch];
        }
    }
}

- (IBAction)clearSearchField:(NSButton*)sender
{
    if (sender == self.clear_search)
    {
        self.search_field.stringValue = @"";
        [self.clear_search setHidden:YES];
        [self cancelLastSearchOperation];
        [self clearResults];
    }
}

- (BOOL)control:(NSControl*)control
       textView:(NSTextView*)textView
doCommandBySelector:(SEL)commandSelector
{
    if (control != self.search_field)
        return NO;
    
    if (commandSelector == @selector(insertNewline:))
    {
        [self addSelectedUser];
        return YES;
    }
    else if (commandSelector == @selector(moveDown:))
    {
        IALog(@"down");
        [self moveTableSelectionBy:1];
        return YES;
    }
    else if (commandSelector == @selector(moveUp:))
    {
        IALog(@"up");
        [self moveTableSelectionBy:-1];
        return YES;
    }
    
    return NO;
}

//- Table Drawing Functions ------------------------------------------------------------------------

- (void)clearResults
{
    [self.view setFrameSize:self.search_box_view.frame.size];
    [_delegate searchView:self changedSize:self.view.frame.size];
    _search_results = nil;
    [self.no_results_message setHidden:YES];
}

- (void)updateResultsTable
{
    NSSize new_size = NSZeroSize;
    if (_search_results.count == 0) // No results so show message
    {
        [self.no_results_message setHidden:NO];
        new_size = NSMakeSize(self.view.frame.size.width,
                              self.search_box_view.frame.size.height +
                                self.no_results_message.frame.size.height + 10.0);
    }
    else
    {
        new_size = NSMakeSize(self.view.frame.size.width,
                              self.search_box_view.frame.size.height + [self tableHeight]);
    }
    [_delegate searchView:self
              changedSize:new_size];
    [self.table_view reloadData];
}

- (CGFloat)tableHeight
{
    CGFloat total_height = _search_results.count * _row_height;
    CGFloat max_height = _row_height * _max_rows_shown;
    if (total_height > max_height)
        return max_height;
    else
        return total_height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _search_results.count;
}

- (CGFloat)tableView:(NSTableView*)tableView
         heightOfRow:(NSInteger)row
{
    return _row_height;
}

- (NSView*)tableView:(NSTableView*)tableView
  viewForTableColumn:(NSTableColumn*)tableColumn
                 row:(NSInteger)row
{    
    IAUser* user = [_search_results objectAtIndex:row];
    if (user == nil || [user.user_id isEqualToString:@""])
        return nil;
    
    IASearchResultsCellView* cell = [tableView makeViewWithIdentifier:@"user_search_cell"
                                                                owner:self];
    [cell setUserFullname:user.fullname];
    [cell setUserFavourite:NO]; // XXX check if user is favourite
    NSImage* avatar = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:user
                                                                     andLoadIfNeeded:YES]
                                          ofRadius:25
                                   withWhiteBorder:NO];
    [cell setUserAvatar:avatar];
    return cell;
}

- (NSTableRowView*)tableView:(NSTableView*)tableView
               rowViewForRow:(NSInteger)row
{
    IASearchResultsTableRowView* row_view = [tableView rowViewAtRow:row makeIfNecessary:YES];
    if (row_view == nil)
        row_view = [[IASearchResultsTableRowView alloc] initWithFrame:NSZeroRect];
    return row_view;
}

//- User Interactions With Table -------------------------------------------------------------------

- (BOOL)tableView:(NSTableView*)aTableView
  shouldSelectRow:(NSInteger)row
{
    return YES;
}

- (IBAction)tableViewAction:(NSTableView*)sender
{
    NSInteger row = self.table_view.clickedRow;
    if (row == -1)
        return;
    [self addSelectedUser];
}

- (void)addSelectedUser
{
    NSInteger row = self.table_view.selectedRow;
    if (row == -1)
        return;
    IALog(@"Adding user %@", [_search_results objectAtIndex:row]);
}

- (void)moveTableSelectionBy:(NSInteger)displacement
{
    NSInteger row = self.table_view.selectedRow;
    if (row + displacement < 0 &&
        row + displacement >= _search_results.count - 1)
    {
        return;
    }
    [self.table_view selectRowIndexes:[NSIndexSet indexSetWithIndex:(row + displacement)] byExtendingSelection:NO];
}

@end
