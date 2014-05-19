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
@property(readonly, nonatomic) BOOL isShowingMenu;

@property(nonatomic) CGFloat borderWidth;
@property(nonatomic) LIBorderMask borderMask;
@property(nonatomic, copy) NSColor *borderColor;
@property(nonatomic, copy) NSColor *backgroundColor;

@property(nonatomic, copy) NSColor *titleColor;
@property(nonatomic, copy) NSColor *titleHighlightColor;

@property(nonatomic) CGFloat minWidth, maxWidth;

// NOTE:
// Returns an adjusted field editor frame
// used when editing the cell's title. Override
// if cell contents appear to shift while editing

- (NSRect)editingRectForBounds:(NSRect)rect;

@end

@interface LITabButton : NSButton
+ (Class)cellClass;

@property(nonatomic) BOOL showsMenu;
@property(readonly, nonatomic) BOOL isShowingMenu;

@property(nonatomic) LIBorderMask borderMask;
@property(nonatomic, copy) NSColor *borderColor;
@property(nonatomic, copy) NSColor *backgroundColor;

@property(nonatomic, copy) NSColor *titleColor;
@property(nonatomic, copy) NSColor *titleHighlightColor;

@property(nonatomic) CGFloat minWidth, maxWidth;

@end

extern BOOL LIRectArrayWithBorderMask(NSRect sourceRect, CGFloat borderWidth, LIBorderMask borderMask, NSRect **rectArray, NSInteger *rectCount);
