//
//  IALoginViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/29/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IALoginViewController.h"

#import <Gap/IAGapState.h>

@interface IALoginViewController ()

@end

//- Login window -----------------------------------------------------------------------------------

@implementation IALoginWindow


- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end

//- Login view -------------------------------------------------------------------------------------

@interface IALoginView : NSView

@property (nonatomic) CGFloat shadow_size;

@end

@implementation IALoginView

@synthesize shadow_size;

- (void)awakeFromNib
{
    shadow_size = 10.0;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSShadow* shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, 0.0)
                                          blurRadius:shadow_size
                                               color:TH_RGBACOLOR(0.0, 0.0, 0.0, 0.5)];
    [shadow set];
    CGFloat corner_radius = 5.0;
    NSRect inner_bounds = NSZeroRect;
    inner_bounds.origin = NSMakePoint(self.bounds.origin.x + shadow_size / 2.0,
                                      self.bounds.origin.y + shadow_size / 2.0);
    inner_bounds.size = NSMakeSize(self.bounds.size.width - shadow_size,
                                   self.bounds.size.height - shadow_size);
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:inner_bounds
                                                         xRadius:corner_radius
                                                         yRadius:corner_radius];
    
    [TH_RGBCOLOR(246.0, 246.0, 246.0) set];
    [path fill];
}

@end

//- Initiailisation --------------------------------------------------------------------------------

@implementation IALoginViewController
{
@private
    id<IALoginViewControllerProtocol> _delegate;
    NSWindow* _window;
}

+ (IALoginWindow*)windowWithFrame:(NSRect)frame screen:(NSScreen*)screen
{
    IALoginWindow* result = [[IALoginWindow alloc] initWithContentRect:frame
                                                             styleMask:NSBorderlessWindowMask
                                                               backing:NSBackingStoreBuffered
                                                                 defer:YES
                                                                screen:screen];
    result.alphaValue = 0.0;
	result.backgroundColor = [NSColor clearColor];
    result.hasShadow = YES;
	result.opaque = NO;
    [result setLevel:NSFloatingWindowLevel];
    [result setMovableByWindowBackground:YES];
    return result;
}

- (id)initWithDelegate:(id<IALoginViewControllerProtocol>)delegate
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
    }
    return self;
}

- (void)setLoginButtonText
{
    NSMutableParagraphStyle* style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSCenterTextAlignment;
    NSShadow* shadow = [IAFunctions shadowWithOffset:NSMakeSize(0.0, -1.0)
                                          blurRadius:1.0
                                               color:[NSColor blackColor]];
    
    NSDictionary* button_style = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:13.0]
                                                 paragraphStyle:style
                                                         colour:[NSColor whiteColor]
                                                         shadow:shadow];
    self.login_button.attributedTitle = [[NSAttributedString alloc]
                                         initWithString:NSLocalizedString(@"LOGIN", @"login")
                                         attributes:button_style];
}

// Shadows not drawn for transparent NSBorderlessWindowMask windows.
// Work around by increasing view size and drawing manually.
- (void)prepareForShadow
{
    NSRect new_main_rect = NSZeroRect;
    new_main_rect.origin = NSMakePoint(self.view.frame.origin.x,
                                     self.view.frame.origin.y);
    new_main_rect.size = NSMakeSize(self.login_view.frame.size.width + self.login_view.shadow_size,
                                    self.login_view.frame.size.height + self.login_view.shadow_size);
    self.view.frame = new_main_rect;    
}

- (void)awakeFromNib
{
    [self.email_address setDelegate:self];
    [self.error_message setHidden:YES];
    self.error_message.stringValue = @"";
    [self.password setDelegate:self];

    [self prepareForShadow];
    
    [self setLoginButtonText];
}

- (NSString*)description
{
    return @"[LoginViewController]";
}

- (void)showLoginWindowOnScreen:(NSScreen*)screen
{
    if (_window != nil)
        return;
    NSRect frame = NSZeroRect;
    frame.size = self.view.bounds.size;
    frame.origin = [self centreFrame:frame onScreen:screen];
    
    NSRect rect = NSMakeRect(5.0, 5.0, self.login_view.frame.size.width, self.login_view.frame.size.height);
    self.login_view.frame = rect;
    [self.view addSubview:self.login_view];
    _window = [IALoginViewController windowWithFrame:frame screen:screen];
    _window.alphaValue = 0.0;
    _window.delegate = self;
    _window.contentView = self.view;
    
    [_window makeKeyAndOrderFront:nil];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [_window.animator setAlphaValue:1.0];
     }
                        completionHandler:^
     {
     }];
}

- (void)showLoginWindowOnScreen:(NSScreen*)screen withError:(NSString*)error
{
    if (_window == nil)
    {
        [self showLoginWindowOnScreen:screen];
    }
    self.error_message.stringValue = error;
    [self.error_message setHidden:NO];
}

//- General Functions ------------------------------------------------------------------------------

- (NSPoint)centreFrame:(NSRect)frame onScreen:(NSScreen*)screen
{
    CGFloat x = floor(NSWidth(screen.frame) / 2.0 - NSWidth(frame) / 2.0);
    CGFloat y = floor(NSHeight(screen.frame) / 2.0 - NSHeight(frame) / 2.0);
    return NSMakePoint(x, y);
}

- (void)closeLoginWindow
{
    if (_window == nil)
    {
        return;
    }
    _window.delegate = nil;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
     {
         context.duration = 0.25;
         [_window.animator setAlphaValue:0.0];
     }
                        completionHandler:^
     {
         [_window orderOut:nil];
         _window = nil;
     }];
}

- (BOOL)loginWindowOpen
{
    if (_window == nil)
        return NO;
    else
        return YES;
}

//- Text Fields ------------------------------------------------------------------------------------

- (void)controlTextDidChange:(NSNotification*)aNotification
{
    NSControl* control = aNotification.object;
    [self.error_message setHidden:YES];
    if (control == self.email_address)
    {
        if (self.email_address.stringValue.length == 0)
            [self.create_account_link setHidden:NO];
        else
            [self.create_account_link setHidden:YES];
    }
    else if (control == self.password)
    {
        if (self.password.stringValue.length == 0)
            [self.fogot_password_link setHidden:NO];
        else
            [self.fogot_password_link setHidden:YES];
    }
}

//- Login ------------------------------------------------------------------------------------------

- (BOOL)inputsGood
{
    if (![IAFunctions stringIsValidEmail:self.email_address.stringValue])
    {
        self.error_message.stringValue = NSLocalizedString(@"Please enter a valid email address",
                                                           @"email not valid");
        [self.error_message setHidden:NO];
        return NO;
    }
    else if (self.password.stringValue.length == 0)
    {
        self.error_message.stringValue = NSLocalizedString(@"Please enter your password",
                                                           @"no password entered");
        [self.error_message setHidden:NO];
        return NO;
    }
    return YES;
}

- (IBAction)loginClicked:(NSButton*)sender
{
    if (sender == self.login_button)
    {
        if ([self inputsGood])
        {
            [_delegate tryLogin:self
                       username:self.email_address.stringValue
                       password:self.password.stringValue];
        }
    }
}

//- Close Button -----------------------------------------------------------------------------------

- (IBAction)closeButtonClicked:(NSButton*)sender
{
    if (sender == self.close_button)
        [self closeLoginWindow];
}

@end
