//
//  IASearchResultsCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASearchResultsCellView.h"

@implementation IASearchResultsCellView
{
    BOOL _is_favourite;
    id<IASearchResultsCellProtocol> _delegate;
}

//- Set Cell Values --------------------------------------------------------------------------------

- (BOOL)isOpaque
{
    return NO;
}

- (void)setDelegate:(id<IASearchResultsCellProtocol>)delegate
{
    _delegate = delegate;
}

- (void)setUserFullname:(NSString*)fullname
{
    NSDictionary* style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:IA_RGB_COLOUR(37.0, 47.0, 51.0)
                                                  shadow:nil];
    NSAttributedString* fullname_str = [[NSAttributedString alloc] initWithString:fullname
                                                                       attributes:style];
    self.result_fullname.attributedStringValue = fullname_str;
}

- (void)setUserAvatar:(NSImage*)image
{
    self.result_avatar.image = image;
}

- (void)setUserFavourite:(BOOL)favourite
{
    _is_favourite = favourite;
    if (favourite)
    {
        self.result_star.image = [IAFunctions imageNamed:@"icon-star-selected"];
        [self.result_star setToolTip:NSLocalizedString(@"Remove user as favourite",
                                                       @"remove user as favourite")];
    }
    else
    {
        self.result_star.image = [IAFunctions imageNamed:@"icon-star"];
        [self.result_star setToolTip:NSLocalizedString(@"Add user as favourite",
                                                       @"add user as favourite")];
    }
}

//- Cell Actions -----------------------------------------------------------------------------------

- (IBAction)starClicked:(NSButton*)sender
{
    if (sender != self.result_star)
        return;
    if (_is_favourite)
    {
        _is_favourite = NO;
        self.result_star.image = [IAFunctions imageNamed:@"icon-star"];
        [_delegate searchResultCellWantsRemoveFavourite:self];
        [self.result_star setToolTip:NSLocalizedString(@"Add user as favourite",
                                                       @"add user as favourite")];
    }
    else
    {
        _is_favourite = YES;
        self.result_star.image = [IAFunctions imageNamed:@"icon-star-selected"];
        [_delegate searchResultCellWantsAddFavourite:self];
        [self.result_star setToolTip:NSLocalizedString(@"Remove user as favourite",
                                                       @"remove user as favourite")];
    }
}

@end
