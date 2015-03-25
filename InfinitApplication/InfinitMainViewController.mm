//
//  InfinitMainViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 13/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "InfinitMainViewController.h"
#import "InfinitMetricsManager.h"
#import "InfinitOnboardingController.h"
#import "InfinitTooltipViewController.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>

#undef check
#import <elle/log.hh>
#import <version.hh>

ELLE_LOG_COMPONENT("OSX.MainViewController");

#define IA_FEEDBACK_LINK "http://feedback.infinit.io?utm_source=app&utm_medium=mac"

//- Main Controller --------------------------------------------------------------------------------

@interface InfinitMainViewController ()

@property (nonatomic, unsafe_unretained) NSViewController* current_controller;
@property (nonatomic, strong) InfinitLinkViewController* link_controller;
@property (nonatomic, strong) InfinitTransactionViewController* transaction_controller;

@end

@implementation InfinitMainViewController
{
@private
  __weak id<InfinitMainViewProtocol> _delegate;

  NSString* _version_str;

  InfinitTooltipViewController* _tooltip;

  BOOL _for_people_view;
}

#pragma mark - Init

- (id)initWithDelegate:(id<InfinitMainViewProtocol>)delegate
         forPeopleView:(BOOL)flag;
{
  if (self = [super initWithNibName:self.className bundle:nil])
  {
    _for_people_view = flag;
    _delegate = delegate;
    _transaction_controller =
      [[InfinitTransactionViewController alloc] initWithDelegate:self];
    _link_controller =
      [[InfinitLinkViewController alloc] initWithDelegate:self];
    if (_for_people_view)
      _current_controller = _transaction_controller;
    else
      _current_controller = _link_controller;

    _version_str =
      [NSString stringWithFormat:@"v%@", [NSString stringWithUTF8String:INFINIT_VERSION]];
  }
  return self;
}

- (void)dealloc
{
  _transaction_controller = nil;
  _link_controller = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)awakeFromNib
{
  [self.main_view addSubview:_current_controller.view];
  NSArray* contraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                            options:0
                                            metrics:nil
                                              views:@{@"view": self.current_controller.view}];
  [self.main_view addConstraints:contraints];
  _version_item.title = _version_str;
}

- (CATransition*)transitionFromLeft:(BOOL)from_left
{
  CATransition* transition = [CATransition animation];
  transition.type = kCATransitionPush;
  if (from_left)
    transition.subtype = kCATransitionFromLeft;
  else
    transition.subtype = kCATransitionFromRight;
  return transition;
}

- (void)loadView
{
  [super loadView];
  [self.view_selector setDelegate:self];
  [self.view_selector setupViewForPeopleView:_for_people_view];
  [self.view_selector setLinkCount:self.link_controller.linksRunning];
  [self.view_selector setTransactionCount:self.transaction_controller.unreadRows];

  if (_for_people_view)
  {
    ELLE_LOG("%s: loading main view for people", self.description.UTF8String);
    self.send_button.image = [IAFunctions imageNamed:@"icon-transfer"];
    self.send_button.toolTip = NSLocalizedString(@"Send a file", nil);
  }
  else
  {
    ELLE_LOG("%s: loading main view for links", self.description.UTF8String);
    self.send_button.image = [IAFunctions imageNamed:@"icon-upload"];
    self.send_button.toolTip = NSLocalizedString(@"Get a link", nil);
  }

  InfinitOnboardingState onboarding_state = [_delegate onboardingState:self];

  if (onboarding_state == INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION)
  {
    [self performSelector:@selector(delayedStartSendOnboarding) withObject:nil afterDelay:0.5];
  }
  else if (onboarding_state == INFINIT_ONBOARDING_SEND_FILE_SENDING ||
           onboarding_state == INFINIT_ONBOARDING_SEND_FILE_SENT)
  {
    [self.transaction_controller performSelector:@selector(delayedFileSentOnboarding)
                                      withObject:nil
                                      afterDelay:0.5];
    [_delegate setOnboardingState:INFINIT_ONBOARDING_DONE];
  }
}

#pragma mark - Onboarding

- (void)delayedStartSendOnboarding
{
  if (_tooltip == nil)
    _tooltip = [[InfinitTooltipViewController alloc] init];
  NSString* message = NSLocalizedString(@"Click here to send a file", nil);
  [_tooltip showPopoverForView:self.send_button
            withArrowDirection:INPopoverArrowDirectionLeft
                   withMessage:message
              withPopAnimation:YES
                       forTime:5.0];
}

- (void)linkAdded:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitLinkTransaction* link =
    [[InfinitLinkTransactionManager sharedInstance] transactionWithId:id_];
  if (_current_controller != _link_controller)
    return;
  [self.link_controller linkAdded:link];
  [self.view_selector setLinkCount:self.link_controller.linksRunning];
}

- (void)linkUpdated:(NSNotification*)notification
{
  if (_current_controller != self.link_controller)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitLinkTransaction* link =
    [[InfinitLinkTransactionManager sharedInstance] transactionWithId:id_];
  [_link_controller linkUpdated:link];
  [self.view_selector setLinkCount:_link_controller.linksRunning];
}

- (void)transactionAdded:(NSNotification*)notification
{
  if (self.current_controller != self.transaction_controller)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  [_transaction_controller transactionAdded:transaction];
  [self.view_selector setTransactionCount:_transaction_controller.unreadRows];
}

- (void)transactionUpdated:(NSNotification*)notification
{
  if (self.current_controller != self.transaction_controller)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  [self.transaction_controller transactionUpdated:transaction];
  [self.view_selector setTransactionCount:self.transaction_controller.unreadRows];
}

#pragma mark - User Handling

- (void)userUpdated:(NSNotification*)notification
{
  if (self.current_controller != self.transaction_controller)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:id_];
  [self.transaction_controller userUpdated:user];
}

#pragma mark - Connection Status Handling

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (self.current_controller == self.link_controller)
    [self.link_controller selfStatusChanged:connection_status.status];
}

#pragma mark - Link View Protocol

- (void)copyLinkToPasteBoard:(InfinitLinkTransaction*)link
{
  [_delegate copyLinkToClipboard:link];
}

- (void)linksViewResizeToHeight:(CGFloat)height
{
  if (height == self.content_height_constraint.constant)
  {
    [_link_controller resizeComplete];
    return;
  }

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [self.content_height_constraint.animator setConstant:height];
   }
                      completionHandler:^
   {
     self.content_height_constraint.constant = height;
     [_link_controller resizeComplete];
   }];
}


#pragma mark - Peer Transaction Protocol

- (void)transactionsViewResizeToHeight:(CGFloat)height
{
  if (height == self.content_height_constraint.constant)
    return;

  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.content_height_constraint.animator setConstant:height];
  }
                      completionHandler:^
  {
    self.content_height_constraint.constant = height;
  }];
}
- (void)userGotClicked:(InfinitUser*)user
{
  self.transaction_controller.changing = YES;
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.content_height_constraint.animator setConstant:0.0];
  }
                      completionHandler:^
  {
    [_delegate userGotClicked:user];
  }];
}

- (InfinitPeerTransaction*)receiveOnboardingTransaction:(InfinitTransactionViewController*)sender
{
  return [_delegate receiveOnboardingTransaction:self];
}

- (InfinitPeerTransaction*)sendOnboardingTransaction:(InfinitTransactionViewController*)sender
{
  return [_delegate sendOnboardingTransaction:self];
}

//- Transaction Link Protocol ----------------------------------------------------------------------

- (void)gotUserClick:(InfinitMainTransactionLinkView*)sender
{
  if (_current_controller == _transaction_controller)
    return;

  ELLE_LOG("%s: changing to people view", self.description.UTF8String);

  self.send_button.image = [IAFunctions imageNamed:@"icon-transfer"];
  self.send_button.toolTip = NSLocalizedString(@"Send a file", nil);

  [_transaction_controller updateModel];
  [_transaction_controller.table_view scrollRowToVisible:0];

  [self.view_selector setMode:INFINIT_MAIN_VIEW_TRANSACTION_MODE];
  _link_controller.changing = YES;
  self.main_view.animations = @{@"subviews": [self transitionFromLeft:NO]};
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
   {
     context.duration = 0.15;
     [self.main_view.animator replaceSubview:_current_controller.view
                                        with:_transaction_controller.view];
     _current_controller = _transaction_controller;
   }
                      completionHandler:^
   {
     NSArray* constraints =
       [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                               options:0
                                               metrics:nil
                                                 views:@{@"view": _current_controller.view}];
     [self.main_view addConstraints:constraints];
     if (self.content_height_constraint.constant != _transaction_controller.height)
     {
       [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
        {
          context.duration = 0.15;
          [self.content_height_constraint.animator setConstant:_transaction_controller.height];
        }
                           completionHandler:^
        {
          _transaction_controller.changing = NO;
        }];
     }
     else
     {
       _transaction_controller.changing = NO;
     }
   }];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_PEOPLE];
}

- (void)gotLinkClick:(InfinitMainTransactionLinkView*)sender
{
  if (self.current_controller == self.link_controller)
    return;

  ELLE_LOG("%s: changing to link view", self.description.UTF8String);

  [_tooltip close];
  [self.transaction_controller closeToolTips];
  [self.transaction_controller markTransactionsRead];

  self.send_button.image = [IAFunctions imageNamed:@"icon-upload"];
  self.send_button.toolTip = NSLocalizedString(@"Get a link", nil);

  [self.link_controller updateModel];
  [self.link_controller.table_view scrollRowToVisible:0];

  [self.view_selector setMode:INFINIT_MAIN_VIEW_LINK_MODE];
  self.transaction_controller.changing = YES;
  self.main_view.animations = @{@"subviews": [self transitionFromLeft:YES]};
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.main_view.animator replaceSubview:self.current_controller.view
                                       with:self.link_controller.view];
    _current_controller = self.link_controller;
  }
                      completionHandler:^
  {
    NSArray* constraints =
      [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                              options:0
                                              metrics:nil
                                                views:@{@"view": self.current_controller.view}];
    [self.main_view addConstraints:constraints];
    if (self.content_height_constraint.constant != self.link_controller.height)
    {
      [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
      {
        context.duration = 0.15;
        [self.content_height_constraint.animator setConstant:self.link_controller.height];
      }
                          completionHandler:^
      {
        self.link_controller.changing = NO;
      }];
    }
    else
    {
      self.link_controller.changing = NO;
    }
  }];
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_LINKS];
}

#pragma mark - User Interaction

- (IBAction)gearButtonClicked:(NSButton*)sender
{
  NSPoint point = NSMakePoint(sender.frame.origin.x + NSWidth(sender.frame),
                              sender.frame.origin.y);
  NSPoint menu_origin = [sender.superview convertPoint:point toView:nil];
  NSEvent* event = [NSEvent mouseEventWithType:NSLeftMouseDown
                                      location:menu_origin
                                 modifierFlags:NSLeftMouseDownMask
                                     timestamp:0
                                  windowNumber:sender.window.windowNumber
                                       context:sender.window.graphicsContext
                                   eventNumber:0
                                    clickCount:1
                                      pressure:1];
  [NSMenu popUpContextMenu:_gear_menu withEvent:event forView:sender];
}

- (IBAction)sendButtonClicked:(NSButton*)sender
{
  _transaction_controller.changing = YES;
  [InfinitMetricsManager sendMetric:INFINIT_METRIC_MAIN_SEND];
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.15;
    [self.content_height_constraint.animator setConstant:0.0];
  } completionHandler:^
  {
    if (self.view_selector.mode == INFINIT_MAIN_VIEW_TRANSACTION_MODE)
      [_delegate sendGotClicked:self];
    else
      [_delegate makeLinkGotClicked:self];
  }];
}

- (IBAction)quitClicked:(NSMenuItem*)sender
{
  [_delegate quit:self];
}

- (IBAction)logoutClicked:(NSMenuItem*)sender
{
  [_delegate logout:self];
} 

- (IBAction)onFeedbackClick:(NSMenuItem*)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:
                                          [NSString stringWithUTF8String:IA_FEEDBACK_LINK]]];
}

- (IBAction)onReportProblemClick:(NSMenuItem*)sender
{
  [_delegate reportAProblem:self];
}

- (IBAction)onSettingsClick:(NSMenuItem*)sender
{
  [_delegate settings:self];
}

#pragma mark - IAViewController

- (BOOL)closeOnFocusLost
{
  [self.transaction_controller closeToolTips];
  return YES;
}

- (void)viewActive
{
  [super viewActive];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userUpdated:)
                                               name:INFINIT_USER_STATUS_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkAdded:)
                                               name:INFINIT_NEW_LINK_TRANSACTION_NOTIFICATION 
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkUpdated:)
                                               name:INFINIT_LINK_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkUpdated:)
                                               name:INFINIT_LINK_TRANSACTION_DATA_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(linkUpdated:)
                                               name:INFINIT_LINK_TRANSACTION_DELETED_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionAdded:)
                                               name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionUpdated:)
                                               name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(connectionStatusChanged:)
                                               name:INFINIT_CONNECTION_STATUS_CHANGE
                                             object:nil];
  // WORKAROUND stop flashing when changing subview by enabling layer backing. Need to do this once
  // the view has opened so that we get a shadow during opening animation.
  self.main_view.wantsLayer = YES;
  self.main_view.layer.masksToBounds = YES;
}

- (void)aboutToChangeView
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (_current_controller == _transaction_controller)
    _transaction_controller.changing = YES;
  else if (_current_controller == _link_controller)
    _link_controller.changing = YES;
  [_tooltip close];
  [_transaction_controller closeToolTips];
  [_transaction_controller markTransactionsRead];
}

@end
