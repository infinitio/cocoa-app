//
//  InfinitConversationPersonView.mm
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitConversationPersonView.h"

@implementation InfinitConversationPersonView
{
@private
  // WORKAROUND: 10.7 doesn't allow weak references to certain classes (like NSViewController)
  __unsafe_unretained id<InfinitConversationPersonViewProtocol> _delegate;
  NSTrackingArea* _tracking_area;
  NSInteger _tracking_options;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame])
  {
    _tracking_options = (NSTrackingInVisibleRect |
                         NSTrackingActiveAlways |
                         NSTrackingMouseEnteredAndExited);
  }
  return self;
}

- (void)setDelegate:(id<InfinitConversationPersonViewProtocol>)delegate
{
  _delegate = delegate;
}

- (void)dealloc
{
  _tracking_area = nil;
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* bg = [IAFunctions roundedTopBezierWithRect:self.bounds cornerRadius:6.0];
  [IA_GREY_COLOUR(255) set];
  [bg fill];
  NSBezierPath* dark_line =
    [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, NSWidth(self.bounds), 2.0)];
  [IA_GREY_COLOUR(230) set];
  [dark_line fill];
}

//- Mouse Handling ---------------------------------------------------------------------------------

- (void)resetCursorRects
{
  [super resetCursorRects];
  NSCursor* cursor = [NSCursor pointingHandCursor];
  [self addCursorRect:self.bounds cursor:cursor];
}

- (void)ensureTrackingArea
{
  if (_tracking_area == nil)
  {
    _tracking_area = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                  options:_tracking_options
                                                    owner:self
                                                 userInfo:nil];
  }
}

- (void)updateTrackingAreas
{
  [super updateTrackingAreas];
  [self ensureTrackingArea];
  if (![self.trackingAreas containsObject:_tracking_area])
  {
    [self addTrackingArea:_tracking_area];
  }
}

- (void)mouseDown:(NSEvent*)theEvent
{
  if (theEvent.clickCount == 1)
    [_delegate conversationPersonViewGotClick:self];
}

@end
