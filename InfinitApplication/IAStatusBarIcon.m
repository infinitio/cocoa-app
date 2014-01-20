//
//  IAStatusBarIcon.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAStatusBarIcon.h"
#import "IAFunctions.h"

#import <QuartzCore/QuartzCore.h>

typedef enum __IAStatusBarIconStatus
{
    STATUS_BAR_ICON_NORMAL = 0,
    STATUS_BAR_ICON_FIRE,
    STATUS_BAR_ICON_CLICKED,
    STATUS_BAR_ICON_NO_CONNECTION,
    STATUS_BAR_ICON_ANIMATED,
    STATUS_BAR_ICON_FIRE_ANIMATED,
    STATUS_BAR_ICON_LOGGING_IN,
} IAStatusBarIconStatus;

typedef enum __InfinitStatusBarIconColour
{
    STATUS_BAR_ICON_COLOUR_BLACK = 0,
    STATUS_BAR_ICON_COLOUR_GREY = 1,
    STATUS_BAR_ICON_COLOUR_RED = 2,
} InfinitStatusBarIconColour;

@implementation IAStatusBarIcon
{
@private
    id _delegate;
    NSArray* _drag_types;
    NSImage* _icon[4];
    NSImageView* _icon_view;
    BOOL _is_highlighted;
    gap_UserStatus _connected;
    NSInteger _number_of_items;
    NSStatusItem* _status_item;
    CGFloat _length;
    
    IAStatusBarIconStatus _current_mode;
    NSArray* _black_animated_images;
    NSArray* _red_animated_images;
}

@synthesize isClickable = _is_clickable;
@synthesize isHighlighted = _is_highlighted;
@synthesize isLoggingIn = _logging_in;
@synthesize isTransferring = _is_transferring;

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self addSubview:_icon_view];
        _drag_types = [NSArray arrayWithObjects:NSFilenamesPboardType,
                                                nil];
        _number_of_items = 0;
        _connected = gap_user_status_offline;
        _is_clickable = YES;
        _is_transferring = NO;
        _current_mode = STATUS_BAR_ICON_NO_CONNECTION;
        [self registerForDraggedTypes:_drag_types];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterDraggedTypes];
}

- (id)initWithDelegate:(id<IAStatusBarIconProtocol>)delegate
            statusItem:(NSStatusItem*)status_item
{
    if (self = [super init])
    {
        _delegate = delegate;
        [self setUpAnimatedIcons];
        _icon[STATUS_BAR_ICON_NORMAL] = [IAFunctions imageNamed:@"icon-menu-bar-active"];
        _icon[STATUS_BAR_ICON_FIRE] = [IAFunctions imageNamed:@"icon-menu-bar-fire"];
        _icon[STATUS_BAR_ICON_CLICKED] = [IAFunctions imageNamed:@"icon-menu-bar-clicked"];
        _icon[STATUS_BAR_ICON_NO_CONNECTION] = [IAFunctions
                                                imageNamed:@"icon-menu-bar-inactive"];
        
        _icon_view = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 16.0, 16.0)];
        _icon_view.image = _icon[STATUS_BAR_ICON_NO_CONNECTION];
        // Must unregister drags from image view so that they are passed to parent view.
        [_icon_view unregisterDraggedTypes];
        
        _status_item = status_item;
        _length = _icon[STATUS_BAR_ICON_NORMAL].size.width + 15.0;
        CGFloat height = [[NSStatusBar systemStatusBar] thickness];
        NSRect rect = NSMakeRect(0.0, 0.0, _length, height);
        self = [self initWithFrame:rect];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSAttributedString* notifications_str;
    _length = _icon[0].size.width + 15.0;
    if (_number_of_items > 0)
    {
        NSDictionary* style;
        NSFont* font = [NSFont systemFontOfSize:15.0];
        if (_is_highlighted)
        {
            style = [IAFunctions textStyleWithFont:font
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_GREY_COLOUR(255.0)
                                            shadow:nil];
        }
        else if (_connected == gap_user_status_online)
        {
            style = [IAFunctions textStyleWithFont:font
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_RGB_COLOUR(221.0, 0.0, 0.0)
                                            shadow:nil];
        }
        else if (_connected != gap_user_status_online)
        {
            style = [IAFunctions textStyleWithFont:font
                                    paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                            colour:IA_GREY_COLOUR(93.0)
                                            shadow:nil];
        }
        NSString* number_str = _number_of_items > 99 ?
        @"+" : [[NSNumber numberWithInteger:_number_of_items] stringValue];
        notifications_str = [[NSAttributedString alloc] initWithString:number_str
                                                           attributes:style];
        if (_number_of_items > 9)
            _length += notifications_str.length + 20.0;
        else
            _length += notifications_str.length + 10.0;
    }
    
    self.frame = NSMakeRect(0.0, 0.0, _length, [[NSStatusBar systemStatusBar] thickness]);
    
    if (_is_highlighted)
    {
        [[NSColor selectedMenuItemColor] set];
        NSRect rect = NSMakeRect(self.frame.origin.x,
                                 self.frame.origin.y + 1.0,
                                 NSWidth(self.bounds),
                                 NSHeight(self.bounds) - 1.0);
        NSRectFill(rect);
    }
    
    if (_is_highlighted)
    {
        _current_mode = STATUS_BAR_ICON_CLICKED;
        _icon_view.image = _icon[STATUS_BAR_ICON_CLICKED];
    }
    else if (_logging_in)
    {
        if (_current_mode != STATUS_BAR_ICON_LOGGING_IN)
        {
            _current_mode = STATUS_BAR_ICON_LOGGING_IN;
            _icon_view.image = _icon[STATUS_BAR_ICON_NO_CONNECTION];
            [self showAnimatedImageWithColour:STATUS_BAR_ICON_COLOUR_GREY];
        }
        
    }
    else if (_connected == gap_user_status_offline)
    {
        _current_mode = STATUS_BAR_ICON_NO_CONNECTION;
        _icon_view.image = _icon[STATUS_BAR_ICON_NO_CONNECTION];
    }
    else if (_is_transferring && _number_of_items > 0)
    {
        if (_current_mode != STATUS_BAR_ICON_FIRE_ANIMATED)
        {
            _current_mode = STATUS_BAR_ICON_FIRE_ANIMATED;
            _icon_view.image = _icon[STATUS_BAR_ICON_FIRE];
            [self showAnimatedImageWithColour:STATUS_BAR_ICON_COLOUR_RED];
        }
    }
    else if (!_is_transferring && _number_of_items > 0)
    {
        _current_mode = STATUS_BAR_ICON_FIRE;
        _icon_view.image = _icon[STATUS_BAR_ICON_FIRE];
    }
    else if (_is_transferring && _number_of_items == 0)
    {
        if (_current_mode != STATUS_BAR_ICON_ANIMATED)
        {
            _current_mode = STATUS_BAR_ICON_ANIMATED;
            _icon_view.image = _icon[STATUS_BAR_ICON_NORMAL];
            [self showAnimatedImageWithColour:STATUS_BAR_ICON_COLOUR_BLACK];
        }
    }
    else
    {
        _current_mode = STATUS_BAR_ICON_NORMAL;
        _icon_view.image = _icon[STATUS_BAR_ICON_NORMAL];
    }
    
    CGFloat x;
    if (_number_of_items == 0)
        x = roundf((NSWidth(self.bounds) - NSWidth(_icon_view.frame)) / 2);
    else
        x = round((NSWidth(self.bounds) - NSWidth(_icon_view.frame) - notifications_str.size.width) / 2.0 - 2.0);
    CGFloat y = roundf((NSHeight(self.bounds) - NSHeight(_icon_view.frame)) / 2.0);
    [_icon_view setFrameOrigin:NSMakePoint(x, y)];
    
    if (_number_of_items > 0)
    {
        [notifications_str drawAtPoint:NSMakePoint(_length - notifications_str.size.width - 5.0, 2.0)];
    }
}


- (NSArray*)animationArrayWithColour:(InfinitStatusBarIconColour)colour
{
    NSString* colour_str;
    NSMutableArray* array = [[NSMutableArray alloc] init];
    switch (colour)
    {
        case STATUS_BAR_ICON_COLOUR_BLACK:
            colour_str = @"black";
            break;
        case STATUS_BAR_ICON_COLOUR_GREY:
            colour_str = @"black";
            break;
        case STATUS_BAR_ICON_COLOUR_RED:
            colour_str = @"red";
            break;
        default:
            colour_str = @"black";
            break;
    }
    for (int i = 1; i <= 18; i++)
    {
        NSString* image_name =
            [NSString stringWithFormat:@"icon-menu-bar-animated-%@-%d", colour_str, i];
        [array addObject:[IAFunctions imageNamed:image_name]];
    }
    return array;
}

- (void)setUpAnimatedIcons
{
    _black_animated_images = [self animationArrayWithColour:STATUS_BAR_ICON_COLOUR_BLACK];
    _red_animated_images = [self animationArrayWithColour:STATUS_BAR_ICON_COLOUR_RED];
}

- (void)showAnimatedImageWithColour:(InfinitStatusBarIconColour)colour
{
    NSArray* images;
    CGFloat alpha = 1.0;
    switch (colour)
    {
        case STATUS_BAR_ICON_COLOUR_BLACK:
            images = _black_animated_images;
            break;
        case STATUS_BAR_ICON_COLOUR_GREY:
            images = _black_animated_images;
            alpha = 0.67;
            break;
        case STATUS_BAR_ICON_COLOUR_RED:
            images = _red_animated_images;
            break;

        default:
            return;
    }
    CAKeyframeAnimation* kfa = [CAKeyframeAnimation animation];
    kfa.repeatCount = HUGE_VALF;
    kfa.values = images;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
    {
        context.duration = 1.0;
        _icon_view.alphaValue = alpha;
        _icon_view.animations = @{@"image": kfa};
        _icon_view.animator.image = images[images.count - 1];
    }
                        completionHandler:^
     {
         _icon_view.alphaValue = 1.0;
     }];
}

//- General Functions ------------------------------------------------------------------------------

- (void)setConnected:(gap_UserStatus)connected
{
    _connected = connected;
    [self setNeedsDisplay:YES];
}

- (void)setHighlighted:(BOOL)is_highlighted
{
    _is_highlighted = is_highlighted;
    [self setNeedsDisplay:YES];
}

- (void)setLoggingIn:(BOOL)isLoggingIn
{
    _logging_in = isLoggingIn;
    [self setNeedsDisplay:YES];
}

- (void)setNumberOfItems:(NSInteger)number_of_items
{
    _number_of_items = number_of_items;
    [self setNeedsDisplay:YES];
}

- (void)setTransferring:(BOOL)isTransferring
{
    _is_transferring = isTransferring;
    [self setNeedsDisplay:YES];
}

//- Click Operations -------------------------------------------------------------------------------

- (void)mouseDown:(NSEvent*)theEvent
{
    if (_is_clickable)
        [_delegate statusBarIconClicked:self];
}

//- Drag Operations --------------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste_board = sender.draggingPasteboard;
    if ([paste_board availableTypeFromArray:_drag_types] && _is_clickable)
    {
        [_delegate statusBarIconDragEntered:self];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste_board = sender.draggingPasteboard;
    if (![paste_board availableTypeFromArray:_drag_types])
        return NO;
    
    NSArray* files = [paste_board propertyListForType:NSFilenamesPboardType];
    
    if (files.count > 0)
        [_delegate statusBarIconDragDrop:self withFiles:files];
    
    return YES;
}

@end
