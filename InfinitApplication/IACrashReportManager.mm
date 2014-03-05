//
//  IACrashReportManager.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IACrashReportManager.h"

#import <CrashReporter/CrashReporter.h>

#import "IALogFileManager.h"
#import "IAUserPrefs.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("OSX.CrashReportManager");

@implementation IACrashReportManager

+ (IACrashReportManager*)sharedInstance
{
    static IACrashReportManager* instance = nil;
    if (instance == nil)
    {
        instance = [[IACrashReportManager alloc] init];
    }
    return instance;
}


- (void)setupCrashReporter
{
    NSLog(@"%@ Starting crash reporter", self);
    PLCrashReporter* crash_reporter = [PLCrashReporter sharedReporter];
    NSError* error;
    
//    [self removeOldCrashReports];
    
    // Enable the Crash Reporter
    if (![crash_reporter enableCrashReporterAndReturnError:&error])
        NSLog(@"%@ WARNING: Could not enable crash reporter: %@", self, error);
}

- (void)sendExistingCrashReports
{
    PLCrashReporter* crash_reporter = [PLCrashReporter sharedReporter];
    
    // Check if we previously crashed
    if ([crash_reporter hasPendingCrashReport])
        [self handleCrashReport];
}

- (void)removeOldCrashReports
{
    NSArray* dir_files = [[NSFileManager defaultManager]
                          contentsOfDirectoryAtPath:[[IALogFileManager sharedInstance] logPath]
                                              error:nil];
    NSArray* crash_files = [dir_files filteredArrayUsingPredicate:
                          [NSPredicate predicateWithFormat:@"self ENDSWITH '.crash'"]];
    for (NSString* file in crash_files)
    {
        NSString* file_path = [[[IALogFileManager sharedInstance] logPath]
                               stringByAppendingPathComponent:file];
            [NSFileManager.defaultManager removeItemAtPath:file_path
                                                     error:nil];
    }
}

// XXX Fetch Apple crash report until we are able to symbolicate our crash reports
- (NSString*)getAppleCrashReport
{
    NSString* dir = [NSHomeDirectory() stringByAppendingPathComponent:
                                                                @"Library/Logs/DiagnosticReports"];
    NSArray* dir_files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir
                                                                             error:nil];
    NSMutableArray* infinit_crashes = [NSMutableArray arrayWithArray:
                                       [dir_files filteredArrayUsingPredicate:
                                        [NSPredicate
                                         predicateWithFormat:@"self BEGINSWITH 'InfinitApplication'"]]];
    [infinit_crashes sortUsingSelector:@selector(compare:)];
    if (infinit_crashes.count > 0)
        return [dir stringByAppendingPathComponent:infinit_crashes[infinit_crashes.count - 1]];
    
    return nil;
}

// XXX For now we just use this to find out when we crashed and fetch the Apple crash report. Plan
// is to use our own when we can properly symbolicate the reports.
- (void)handleCrashReport
{
    PLCrashReporter* crash_reporter = [PLCrashReporter sharedReporter];
//    NSData* crash_data;
//    NSError* error;
//    
//    // Try loading the crash report
//    crash_data = [crash_reporter loadPendingCrashReportDataAndReturnError:&error];
//    if (crash_data == nil)
//    {
//        NSLog(@"%@ WARNING: Could not load crash report: %@", self, error);
//        [crash_reporter purgePendingCrashReport];
//        return;
//    }
//    
//    PLCrashReport* report = [[PLCrashReport alloc] initWithData:crash_data
//                                                          error:&error];
//    if (report == nil)
//    {
//        NSLog(@"%@ WARNING: Could not parse crash report %@", self, error);
//        [crash_reporter purgePendingCrashReport];
//        return;
//    }
//    
//    NSString* text_report = [PLCrashReportTextFormatter
//                             stringValueForCrashReport:report
//                                        withTextFormat:PLCrashReportTextFormatiOS];
//    
//    NSString* filename = @"crash_log.crash";
//    NSString* crash_file_path = [[[IALogFileManager sharedInstance] logPath]
//                                 stringByAppendingPathComponent:filename];
//    
//    [text_report writeToFile:crash_file_path atomically:YES
//                    encoding:NSUTF8StringEncoding
//                       error:&error];
//    if (error.code != 0)
//        NSLog(@"%@ WARNING: Writing crash report failed", self);
    
    ELLE_LOG("%s: sending existing crash report", self.description.UTF8String);
    
    NSString* last_state_log = [[IALogFileManager sharedInstance] lastLogFilePath];
    NSString* crash_file_path = [self getAppleCrashReport];
    
    NSString* os_description = [NSString stringWithFormat:@"OS X %@", [IAFunctions osVersionString]];
    
    NSString* user_name = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
    NSString* additional_info = @"None";
    
    if (last_state_log != nil && crash_file_path != nil && user_name != nil)
    {
        gap_send_last_crash_logs(user_name.UTF8String,
                                 crash_file_path.UTF8String,
                                 last_state_log.UTF8String,
                                 os_description.UTF8String,
                                 additional_info.UTF8String);
    }
    [crash_reporter purgePendingCrashReport];
}

- (void)sendUserReportWithMessage:(NSString*)message
                          andFile:(NSString*)file_path
{
    NSString* user_name = [[IAUserPrefs sharedInstance] prefsForKey:@"user:email"];
    NSString* os_description = [NSString stringWithFormat:@"OS X %@", [IAFunctions osVersionString]];
    
    NSDictionary* user_report = @{@"user_name": user_name,
                                  @"message": message,
                                  @"file_path": file_path,
                                  @"os_description": os_description};
    
    [self performSelectorInBackground:@selector(threadedSendUserReportWithMessage:)
                           withObject:user_report];
}

- (void)threadedSendUserReportWithMessage:(NSDictionary*)user_report
{
    ELLE_LOG("%s: sending user report", self.description.UTF8String);

    NSString* user_name = [user_report valueForKey:@"user_name"];
    NSString* message = [user_report valueForKey:@"message"];
    NSString* file_path = [user_report valueForKey:@"file_path"];
    NSString* os_description = [user_report valueForKey:@"os_description"];
    
    gap_send_user_report(user_name.UTF8String,
                         message.UTF8String,
                         file_path.UTF8String,
                         os_description.UTF8String);
}

@end