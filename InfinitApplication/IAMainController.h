//
//  IAMainController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//
//  This controller has several responsibilities. It's responsible for login/logout operations,
//  selecting which views should be shown and communicating with the IATransactionManager and
//  IAUserManager. It also acts as a proxy between the views and the managers so that all
//  information passes through the same place.

#import <Foundation/Foundation.h>

#import <Gap/IATransactionManager.h>
#import <Gap/IAUserManager.h>

#import "IAConversationViewController.h"
#import "IADesktopNotifier.h"
#import "IAGeneralSendController.h"
#import "IALoginViewController.h"
#import "IAMeManager.h"
#import "IANotificationListViewController.h"
#import "IANotLoggedInViewController.h"
#import "IAPopoverViewController.h"
#import "IAOnboardingViewController.h"
#import "IAStatusBarIcon.h"
#import "IAWindowController.h"

@protocol IAMainControllerProtocol;

@interface IAMainController : NSObject <IAConversationViewProtocol,
                                        IADesktopNotifierProtocol,
                                        IAGeneralSendControllerProtocol,
                                        IALoginViewControllerProtocol,
                                        IAMeManagerProtocol,
                                        IANotificationListViewProtocol,
                                        IANotLoggedInViewProtocol,
                                        IAPopoverViewProtocol,
                                        IAOnboardingProtocol,
                                        IAStatusBarIconProtocol,
                                        IATransactionManagerProtocol,
                                        IAUserManagerProtocol,
                                        IAWindowControllerProtocol>

- (id)initWithDelegate:(id<IAMainControllerProtocol>)delegate;

- (void)handleQuit;

@end

@protocol IAMainControllerProtocol <NSObject>

- (void)terminateApplication:(IAMainController*)sender;

@end