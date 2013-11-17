//
//  LITabCell.h
//  LITabControl
//
//  Created by Mark Onyschuk on 11/17/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    LIBorderMaskTop     = (1<<0),
    LIBorderMaskLeft    = (1<<1),
    LIBorderMaskRight   = (1<<2),
    LIBorderMaskBottom  = (1<<3)
} LIBorderMask;

@interface LITabCell : NSButtonCell

@property(nonatomic) BOOL showsMenu;

@property(nonatomic) LIBorderMask borderMask;
@property(nonatomic, copy) NSColor *borderColor;
@property(nonatomic, copy) NSColor *backgroundColor;


@end

extern BOOL LIRectArrayWithBorderMask(NSRect sourceRect, LIBorderMask borderMask, NSRect **rectArray, NSInteger *rectCount);
