//
//  InfinitScreenshotManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 25/05/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitScreenshotManager.h"

#import "IAUserPrefs.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.ScreenshotManager");

@implementation InfinitScreenshotManager
{
@private
  __weak id<InfinitScreenshotManagerProtocol> _delegate;
  NSMetadataQuery* _query;

  BOOL _watch;

  // Used to ensure that we only upload new screenshots.
  NSDate* _last_capture_time;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<InfinitScreenshotManagerProtocol>)delegate
{
  if (self = [super init])
  {
    _query = [[NSMetadataQuery alloc] init];
    _delegate = delegate;
    if ([[IAUserPrefs sharedInstance] prefsForKey:@"upload_screenshots"] == nil)
    {
      _watch = NO;
      [[IAUserPrefs sharedInstance] setPref:@"0" forKey:@"upload_screenshots"];
    }
    else if ([[[IAUserPrefs sharedInstance] prefsForKey:@"upload_screenshots"] isEqualToString:@"1"])
    {
      _watch = YES;
    }
    else
    {
      _watch = NO;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gotScreenShot:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:_query];
    _last_capture_time = [NSDate date];

    NSPredicate* main_predicate = [NSPredicate predicateWithFormat:@"kMDItemIsScreenCapture = 1"];
    NSPredicate* type_predicate =
      [NSPredicate predicateWithFormat:@"kMDItemContentTypeTree == 'public.image'"];
    _query.delegate = self;
    _query.predicate =
      [NSCompoundPredicate andPredicateWithSubpredicates:@[main_predicate, type_predicate]];
    _query.notificationBatchingInterval = 0.1;
    _query.searchScopes = @[[self screenCaptureLocation]];

    if (_watch)
      [_query startQuery];
  }
  return self;
}

- (NSString*)screenCaptureLocation
{
	NSString* location =
    [[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.screencapture"] objectForKey:@"location"];
	if (location)
  {
		location = [location stringByExpandingTildeInPath];
		if (![location hasSuffix:@"/"])
    {
			location = [location stringByAppendingString:@"/"];
		}
		return location;
	}

	return [[@"~/Desktop" stringByExpandingTildeInPath] stringByAppendingString:@"/"];
}

- (void)dealloc
{
  _query.delegate = nil;
  [_query stopQuery];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

//- Watching ---------------------------------------------------------------------------------------

- (void)setWatch:(BOOL)watch
{
  if (_watch == watch)
    return;

  _watch = watch;
  NSString* value = [NSString stringWithFormat:@"%d", _watch];
  [[IAUserPrefs sharedInstance] setPref:value forKey:@"upload_screenshots"];
  if (_watch)
  {
    [_query startQuery];
    ELLE_LOG("%s: start watching for screenshots", self.description.UTF8String);
  }
  else
  {
    [_query stopQuery];
    ELLE_LOG("%s: stop watching for screenshots", self.description.UTF8String);
  }

}

//- Screenshot Handling ----------------------------------------------------------------------------

- (void)gotScreenShot:(NSNotification*)notification
{
  NSMetadataItem* data_item = [notification.userInfo[@"kMDQueryUpdateAddedItems"] lastObject];

  if (data_item == nil)
    return;

  NSDate* new_date = [data_item valueForAttribute:NSMetadataItemFSCreationDateKey];
  
  if ([new_date compare:_last_capture_time] == NSOrderedAscending)
    return;

  NSString* screenshot_path = [data_item valueForAttribute:NSMetadataItemPathKey];
  if (screenshot_path.length == 0)
    return;

  _last_capture_time = [NSDate date];

  ELLE_LOG("%s: got screenshot with path: %s",
           self.description.UTF8String, screenshot_path.UTF8String);
  [_delegate screenshotManager:self gotScreenshot:screenshot_path];
}

@end
