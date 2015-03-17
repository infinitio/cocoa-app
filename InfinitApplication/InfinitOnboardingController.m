//
//  InfinitOnboardingController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 02/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitOnboardingController.h"

@implementation InfinitOnboardingController
{
@private
  id<InfinitOnboardingProtocol> _delegate;
}

@synthesize state = _state;
@synthesize receive_transaction = _receive_transaction;
@synthesize send_transaction = _send_transaction;
@synthesize receive_onboarding_done = _receive_onboarding_done;

- (id)initWithDelegate:(id<InfinitOnboardingProtocol>)delegate
 andReceiveTransaction:(InfinitPeerTransaction*)transaction
{
  if (self = [super init])
  {
    _delegate = delegate;
    _receive_transaction = transaction;
    _receive_onboarding_done = NO;
  }
  return self;
}

- (id)initForSendOnboardingWithDelegate:(id<InfinitOnboardingProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    _receive_onboarding_done = YES;
    _receive_transaction = nil;
    _state = INFINIT_ONBOARDING_RECEIVE_DONE;
  }
  return self;
}

- (InfinitOnboardingState)state
{
  return _state;
}

- (void)setState:(InfinitOnboardingState)state
{
  _state = state;
  if (state >= INFINIT_ONBOARDING_RECEIVE_DONE)
    _receive_onboarding_done = YES;
}

- (BOOL)inSendOnboarding
{
  switch (_state)
  {
    case INFINIT_ONBOARDING_RECEIVE_DONE:
    case INFINIT_ONBOARDING_SEND_FILES_NO_DESTINATION:
    case INFINIT_ONBOARDING_SEND_NO_FILES_NO_DESTINATION:
    case INFINIT_ONBOARDING_SEND_NO_FILES_DESTINATION:
    case INFINIT_ONBOARDING_SEND_FILES_DESTINATION:
      return YES;
      
    default:
      return NO;
  }
}

@end
