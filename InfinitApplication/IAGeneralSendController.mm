//
//  IAGeneralSendController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAGeneralSendController.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.GeneralSendController");

@implementation IAGeneralSendController
{
@private
  // Delegate
  id<IAGeneralSendControllerProtocol> _delegate;
  
  // Send views
  IAFavouritesSendViewController* _favourites_send_controller;
  InfinitCombinedSendViewController* _combined_send_controller;
  
  IAUserSearchViewController* _user_search_controller;
  NSMutableArray* _files;
  BOOL _send_view_open;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAGeneralSendControllerProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    _files = [NSMutableArray array];
    _send_view_open = NO;
  }
  return self;
}

//- General Functions ------------------------------------------------------------------------------

- (void)filesOverStatusBarIcon
{
  if (!_send_view_open)
  {
    [self cancelOpenFavourites];
    [self performSelector:@selector(showFavourites)
               withObject:nil
               afterDelay:0.5];
  }
}

- (void)cancelOpenFavourites
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)openFileDialogForView:(id)sender
{
  if (sender != _combined_send_controller)
    return;
  
  ELLE_TRACE("%s: open file diaglog for: %s", self.description.UTF8String,
             [sender description].UTF8String);
  
  NSOpenPanel* file_dialog = [NSOpenPanel openPanel];
  file_dialog.canChooseFiles = YES;
  file_dialog.canChooseDirectories = YES;
  file_dialog.allowsMultipleSelection = YES;
  
  if ([file_dialog runModal] == NSOKButton)
  {
    NSArray* dialog_files = [file_dialog URLs];
    for (NSURL* file_url in dialog_files)
    {
      if (![_files containsObject:[file_url path]])
        [_files addObject:[file_url path]];
    }
  }
  [sender filesUpdated];
}

//- Open Functions ---------------------------------------------------------------------------------

- (void)openWithNoFile
{
  _send_view_open = YES;
  [_favourites_send_controller hideFavourites];
  if (_combined_send_controller == nil)
  {
    if (_user_search_controller == nil)
      _user_search_controller = [[IAUserSearchViewController alloc] init];
    _combined_send_controller =
      [[InfinitCombinedSendViewController alloc] initWithDelegate:self
                                              andSearchController:_user_search_controller
                                                         fullview:YES];
  }
  [_delegate sendController:self wantsActiveController:_combined_send_controller];
}

- (void)openWithFiles:(NSArray*)files
              forUser:(IAUser*)user
{
  if (user != nil)
  {
    ELLE_TRACE("%s: open send view for user: %s", self.description.UTF8String,
               user.fullname.UTF8String);
  }
  else
  {
    ELLE_TRACE("%s: open send view for no user", self.description.UTF8String);
  }
  _send_view_open = YES;
  [self cancelOpenFavourites];
  [_favourites_send_controller hideFavourites];
  for (NSString* file in files)
  {
    if (![_files containsObject:file])
      [_files addObject:file];
  }
  if (_combined_send_controller == nil)
  {
    if (_user_search_controller == nil)
      _user_search_controller = [[IAUserSearchViewController alloc] init];
    if (files.count > 0)
    {
      _combined_send_controller =
        [[InfinitCombinedSendViewController alloc] initWithDelegate:self
                                                andSearchController:_user_search_controller
                                                           fullview:YES];
    }
    else
    {
      _combined_send_controller =
        [[InfinitCombinedSendViewController alloc] initWithDelegate:self
                                                andSearchController:_user_search_controller
                                                           fullview:YES];
    }
  }
  else
  {
    [_combined_send_controller filesUpdated];
  }
  [_delegate sendController:self wantsActiveController:_combined_send_controller];
  [_user_search_controller addUser:user];
}

- (void)showFavourites
{
  ELLE_TRACE("%s: show favourites", self.description.UTF8String);
  if (_favourites_send_controller == nil)
  {
    _favourites_send_controller = [[IAFavouritesSendViewController alloc] initWithDelegate:self];
    [_favourites_send_controller showFavourites];
  }
}

//- Combined Send View Protocol --------------------------------------------------------------------

- (void)combinedSendViewWantsCancel:(InfinitCombinedSendViewController*)sender
{
  _files = nil;
  [_delegate sendControllerWantsClose:self];
}

- (NSArray*)combinedSendViewWantsFileList:(InfinitCombinedSendViewController*)sender
{
  return [NSArray arrayWithArray:_files];
}

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
  wantsRemoveFileAtIndex:(NSInteger)index
{
  [_files removeObjectAtIndex:index];
  [sender filesUpdated];
}

- (void)combinedSendViewWantsOpenFileDialogBox:(InfinitCombinedSendViewController*)sender
{
  [self openFileDialogForView:sender];
}

- (NSArray*)combinedSendView:(InfinitCombinedSendViewController*)sender
              wantsSendFiles:(NSArray*)files
                     toUsers:(NSArray*)users
                 withMessage:(NSString*)message
{
  [_delegate sendControllerWantsClose:self];
  return [_delegate sendController:self
                    wantsSendFiles:files
                           toUsers:users
                       withMessage:message];
}

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
       wantsAddFavourite:(IAUser*)user
{
  [_delegate sendController:self
          wantsAddFavourite:user];
}

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
    wantsRemoveFavourite:(IAUser*)user
{
  [_delegate sendController:self
       wantsRemoveFavourite:user];
}

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
wantsSetOnboardingSendTransactionId:(NSNumber*)transaction_id
{
  [_delegate sendController:self wantsSetOnboardingSendTransactionId:transaction_id];
}

- (NSArray*)combinedSendViewWantsFriendsByLastInteraction:(InfinitCombinedSendViewController*)sender
{
  return [_delegate sendControllerWantsFriendsByLastInteraction:self];
}

//- Favourites Send View Protocol ------------------------------------------------------------------

- (NSArray*)favouritesViewWantsFavourites:(IAFavouritesSendViewController*)sender
{
  return [_delegate sendControllerWantsFavourites:self];
}

- (NSArray*)favouritesViewWantsSwaggers:(IAFavouritesSendViewController*)sender
{
  return [_delegate sendControllerWantsSwaggers:self];
}

- (NSPoint)favouritesViewWantsMidpoint:(IAFavouritesSendViewController*)sender
{
  return [_delegate sendControllerWantsMidpoint:self];
}

- (void)favouritesView:(IAFavouritesSendViewController*)sender
         gotDropOnUser:(IAUser*)user
             withFiles:(NSArray*)files
{
  [_favourites_send_controller hideFavourites];
  _favourites_send_controller = nil;
  [_delegate sendControllerGotDropOnFavourite:self];
  [self openWithFiles:files forUser:user];
}

- (void)favouritesViewWantsClose:(IAFavouritesSendViewController*)sender
{
  [_favourites_send_controller hideFavourites];
  _favourites_send_controller = nil;
}

- (void)combinedSendView:(InfinitCombinedSendViewController*)sender
         hadFilesDropped:(NSArray*)files
{
  for (NSString* file in files)
  {
    NSURL* file_url = [NSURL fileURLWithPath:file];
    if (![_files containsObject:[file_url path]])
      [_files addObject:[file_url path]];
  }
  [sender filesUpdated];
}

//- Onboarding Protocol ----------------------------------------------------------------------------

- (InfinitOnboardingState)onboardingState:(IAViewController*)sender
{
  return [_delegate onboardingState:sender];
}

- (BOOL)onboardingSend:(IAViewController*)sender
{
  return [_delegate onboardingSend:sender];
}

- (void)setOnboardingState:(InfinitOnboardingState)state
{
  [_delegate setOnboardingState:state];
}

@end
