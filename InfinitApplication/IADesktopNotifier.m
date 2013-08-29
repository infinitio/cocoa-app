//
//  IADesktopNotifier.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IADesktopNotifier.h"

@implementation IADesktopNotifier
{
@private
    id <IADesktopNotifierProtocol> _delegate;
    NSUserNotificationCenter* _notification_centre;
    
}

//- Inititalisation --------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IADesktopNotifierProtocol>)delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        _notification_centre = [NSUserNotificationCenter defaultUserNotificationCenter];
        [_notification_centre setDelegate:self];
    }
    return self;
}

//- General Functions ------------------------------------------------------------------------------

- (NSString*)truncateFilename:(NSString*)filename
{
    NSUInteger max_filename_length = 15;
    NSString* filename_prefix = [filename stringByDeletingPathExtension];
    NSMutableString* truncated_filename;
    if (filename_prefix.length > max_filename_length)
    {
        NSRange truncate_range = {0, MIN([filename_prefix length], max_filename_length)};
        truncate_range = [filename_prefix rangeOfComposedCharacterSequencesForRange:truncate_range];
        
        truncated_filename = [NSMutableString stringWithString:[filename_prefix
                                                                substringWithRange:truncate_range]];
        [truncated_filename appendString:@"..."];
        [truncated_filename appendString:[filename pathExtension]];
    }
    else
        truncated_filename = [NSMutableString stringWithString:filename];
    return truncated_filename;
}

- (NSUserNotification*)notificationFromTransaction:(IATransaction*)transaction
{
    NSUserNotification* res = [[NSUserNotification alloc] init];
    NSString* filename;
    NSString* message;
    NSString* title;
    if (transaction.files_count > 1)
    {
        filename = [NSString stringWithFormat:@"%lu %@", transaction.files_count,
                                                        NSLocalizedString(@"files", @"files")];
    }
    else if ([transaction.files[0] length] > 18)
    {
        filename = [self truncateFilename:transaction.files[0]];
    }
    else
    {
        filename = transaction.files[0];
    }
    
    switch (transaction.view_mode)
    {
        case TRANSACTION_VIEW_WAITING_ACCEPT:
            if (transaction.from_me)
                return nil;
            title = NSLocalizedString(@"New share", @"new share");
            message = [NSString stringWithFormat:@"%@ %@ %@ %@", transaction.other_user.fullname,
                       NSLocalizedString(@"would like to share", @"would like to share"),
                       filename,
                       NSLocalizedString(@"with you", @"with you")];
            break;
        
        case TRANSACTION_VIEW_REJECTED:
            if (!transaction.from_me)
                return nil;
            title = NSLocalizedString(@"Share declined", @"share declined");
            message = [NSString stringWithFormat:@"%@ %@", transaction.other_user.fullname,
                       NSLocalizedString(@"declined your share", @"declined your share")];
            break;
            
        case TRANSACTION_VIEW_CANCELLED_OTHER:
            title = NSLocalizedString(@"Transfer cancelled", @"transfer cancelled");
            message = [NSString stringWithFormat:@"%@ %@ %@",
                       NSLocalizedString(@"Transfer with", @"transfer with"),
                       transaction.other_user.fullname,
                       NSLocalizedString(@"cancelled", @"cancelled")];
            break;
            
        case TRANSACTION_VIEW_CANCELLED_SELF:
            title = NSLocalizedString(@"Transfer cancelled", @"transfer cancelled");
            message = [NSString stringWithFormat:@"%@ %@ %@",
                       NSLocalizedString(@"Transfer with", @"transfer with"),
                       transaction.other_user.fullname,
                       NSLocalizedString(@"cancelled", @"cancelled")];
            break;
            
        case TRANSACTION_VIEW_FAILED:
            title = NSLocalizedString(@"Transfer failed", @"transfer failed");
            message = [NSString stringWithFormat:@"%@ %@",
                       NSLocalizedString(@"Problem connecting with", @"problem connecting with"),
                       transaction.other_user.fullname];
            break;
            
        case TRANSACTION_VIEW_FINISHED:
            title = NSLocalizedString(@"Transfer successful", @"transfer successful");
            if (transaction.from_me)
                message = [NSString stringWithFormat:@"%@ %@ %@", filename,
                           NSLocalizedString(@"sent to", @"sent to"),
                           transaction.other_user.fullname];
            else
                message = [NSString stringWithFormat:@"%@ %@ %@", filename,
                           NSLocalizedString(@"received from", @"received from"),
                           transaction.other_user.fullname];
            
            break;
        default:
            break;
    }
    
    res.title = title;
    res.informativeText = message;
    res.userInfo = @{@"user_id": transaction.other_user.user_id};
    
    return res;
}

- (void)clearAllNotifications
{
    [_notification_centre removeAllDeliveredNotifications];
}


//- Transaction Handling ---------------------------------------------------------------------------

- (void)transactionAdded:(IATransaction*)transaction
{
    NSUserNotification* user_notification = [self notificationFromTransaction:transaction];
    
    if (user_notification == nil)
        return;
    
    [_notification_centre deliverNotification:user_notification];
}

- (void)transactionUpdated:(IATransaction*)transaction
{    
    NSUserNotification* user_notification = [self notificationFromTransaction:transaction];
    
    if (user_notification == nil)
        return;
    
    [_notification_centre deliverNotification:user_notification];
}

//- User Notifications Protocol --------------------------------------------------------------------

- (void)userNotificationCenter:(NSUserNotificationCenter*)center
       didActivateNotification:(NSUserNotification*)notification
{
    NSDictionary* dict = notification.userInfo;
    NSNumber* user_id;
    if ([[dict objectForKey:@"user_id"] isKindOfClass:NSNumber.class])
        user_id = [dict objectForKey:@"user_id"];
    
    if (user_id == nil || user_id.unsignedIntValue == 0)
        return;
    
    [_delegate desktopNotifier:self hadClickNotificationForUserId:user_id];
}

@end