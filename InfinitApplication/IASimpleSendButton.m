//
//  IASimpleSendButton.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASimpleSendButton.h"

@implementation IASimpleSendButton

//- Initialisation ---------------------------------------------------------------------------------

@synthesize enabled = _enabled;

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _enabled = NO;
        [self setIgnoresMultiClick:YES];
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
        self.image = [IAFunctions imageNamed:@"btn-send-files-simple"];
    }
    else
    {
        self.image = [IAFunctions imageNamed:@"btn-send-files-simple-disabled"];
    }
}

- (void)mouseDown:(NSEvent*)theEvent
{
    if (!_enabled)
        return;
    [super mouseDown:theEvent];
}

@end
