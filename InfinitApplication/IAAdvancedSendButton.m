//
//  IAAdvancedSendButton.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAdvancedSendButton.h"

@implementation IAAdvancedSendButton

//- Initialisation ---------------------------------------------------------------------------------

@synthesize enabled = _enabled;

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _enabled = NO;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

//- General Functions ------------------------------------------------------------------------------

- (BOOL)isEnabled
{
    return self.enabled;
}

- (void)setEnabled:(BOOL)flag
{    
    _enabled = flag;
    if (flag)
    {
        self.image = [IAFunctions imageNamed:@"btn-send-files"];
    }
    else
    {
        self.image = [IAFunctions imageNamed:@"btn-send-files-disabled"];
    }
}

@end