//
//  LITabCell.m
//  LITabControl
//
//  Created by Mark Onyschuk on 11/17/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LITabCell.h"
#import "LITabControl.h"

#import "NSImage+LITabControl.h"

#define DF_BORDER_COLOR     [NSColor lightGrayColor]
#define DF_HIGHLIGHT_COLOR  [NSColor colorWithCalibratedRed:0.119 green:0.399 blue:0.964 alpha:1.000]
#define DF_BACKGROUND_COLOR [NSColor colorWithCalibratedRed:0.854 green:0.858 blue:0.873 alpha:1.000]

@implementation LITabCell 

- (id)initTextCell:(NSString *)aString {
    if ((self = [super initTextCell:aString])) {

        _borderColor = DF_BORDER_COLOR;
        _backgroundColor = DF_BACKGROUND_COLOR;
        
        [self setBordered:NO];
        [self setHighlightsBy:NSNoCellMask];
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LITabCell *copy = [super copyWithZone:zone];
    
    copy->_borderMask = _borderMask;
    copy->_borderColor = [_borderColor copyWithZone:zone];
    copy->_backgroundColor = [_backgroundColor copyWithZone:zone];

    copy->_showsMenu = _showsMenu;
    copy->_isShowingMenu = _isShowingMenu;
    
    return copy;
}

- (void)setShowsMenu:(BOOL)showsMenu {
    if (_showsMenu != showsMenu) {
        _showsMenu = showsMenu;
        
        [self.controlView setNeedsDisplay:YES];
    }
}

- (void)setBorderColor:(NSColor *)borderColor {
    if (_borderColor != borderColor) {
        _borderColor = borderColor.copy;
        
        [self.controlView setNeedsDisplay:YES];
    }
}
- (void)setBackgroundColor:(NSColor *)backgroundColor {
    if (_backgroundColor != backgroundColor) {
        _backgroundColor = backgroundColor.copy;
        
        [self.controlView setNeedsDisplay:YES];
    }
}

- (void)setBorderMask:(LIBorderMask)borderMask {
    if (_borderMask != borderMask) {
        _borderMask = borderMask;
        
        [self.controlView setNeedsDisplay:YES];
    }
}

+ (NSImage *)popupImage {
    static NSImage *ret = nil;
    if (ret == nil) {
        ret = [[NSImage imageNamed:@"LIPullDownTemplate"] imageWithTint:[NSColor darkGrayColor]];
    }
    return ret;
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
    NSSize titleSize = [[self attributedTitle] size];
    NSSize popupSize = ([self menu] == nil) ? NSZeroSize : [[LITabCell popupImage] size];

    return NSMakeSize(titleSize.width + (popupSize.width * 2) + 36, MAX(titleSize.height, popupSize.height));
}

- (NSRect)popupRectWithFrame:(NSRect)cellFrame {
    NSRect popupRect = NSZeroRect;
    popupRect.size = [[LITabCell popupImage] size];
    popupRect.origin = NSMakePoint(NSMaxX(cellFrame) - NSWidth(popupRect) - 8, NSMidY(cellFrame) - NSHeight(popupRect) / 2);

    return popupRect;
}

- (NSRect)titleRectForBounds:(NSRect)cellFrame {
    NSSize titleSize = [[self attributedTitle] size];
    NSRect titleRect = NSMakeRect(NSMinX(cellFrame), floorf(NSMidY(cellFrame) - titleSize.height/2), NSWidth(cellFrame), titleSize.height);

    if (self.menu != nil) {
        NSRect popupRect = [self popupRectWithFrame:cellFrame];
        CGFloat titleRectInset = ceilf(NSMaxX(cellFrame) - NSMinX(popupRect));
        
        titleRect = NSOffsetRect(titleRect, 0, -2);
        titleRect = NSInsetRect(titleRect, titleRectInset, 0);
    }
    return titleRect;
}

- (LITabControl *)enclosingTabControlInView:(NSView *)controlView {
    id view = controlView;
    LITabControl *enclosingTabControl = nil;
    while ((view = [view superview])) {
        if ([view isKindOfClass:[LITabControl class]]) {
            enclosingTabControl = view;
            break;
        }
    }
    return enclosingTabControl;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
    NSRect popupRect = [self popupRectWithFrame:cellFrame];
    NSPoint location = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
    
    NSMenu *menu = [self menuForEvent:theEvent inRect:cellFrame ofView:controlView];
    
    if (menu.itemArray.count > 0 &&  NSPointInRect(location, popupRect)) {
        [menu popUpMenuPositioningItem:menu.itemArray[0] atLocation:NSMakePoint(NSMidX(popupRect), NSMaxY(popupRect)) inView:controlView];
        [self setShowsMenu:NO];
        return YES;
        
    } else {
        return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:flag];
    }
}

- (NSMenu *)menuForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)view {
    LITabControl *enclosingTabControl = [self enclosingTabControlInView:view];
    
    if (enclosingTabControl) {
        NSMenu *menu = [enclosingTabControl.dataSource tabControl:enclosingTabControl menuForItem:self.representedObject];
        
        if (menu != nil) {
            // this following side-effect is a bit hokey
            // but it ensures that the receiver of context popup
            // actions can determine which tab is associated with
            // the action. It also ensures that the dataSource and
            // target of the control updates associated views prior
            // to context menu display...
            
            [enclosingTabControl setSelectedItem:self.representedObject];
            [NSApp sendAction:enclosingTabControl.action to:enclosingTabControl.target from:enclosingTabControl];
            [[NSNotificationCenter defaultCenter] postNotificationName:LITabControlSelectionDidChangeNotification object:enclosingTabControl];
        }
        
        return menu;
    } else {
        return [super menuForEvent:event inRect:cellFrame ofView:view];
    }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [self.backgroundColor set];
    NSRectFill(cellFrame);
    
    if (self.image && self.imagePosition != NSNoImage) {
        [self drawImage:[self.image imageWithTint:self.isHighlighted ? DF_HIGHLIGHT_COLOR : [NSColor darkGrayColor]] withFrame:cellFrame inView:controlView];
    }
    
    if (self.title.length && self.imagePosition != NSImageOnly) {
        NSRect titleRect = [self titleRectForBounds:cellFrame];
        
        NSMutableAttributedString *attributedTitle = self.attributedTitle.mutableCopy;
        [attributedTitle addAttributes:@{ NSForegroundColorAttributeName : (self.state ? DF_HIGHLIGHT_COLOR : [NSColor darkGrayColor]) } range:NSMakeRange(0, attributedTitle.length)];
        [attributedTitle drawInRect:titleRect];
    }
    
    NSRect *borderRects;
    NSInteger borderRectCount;
    if (LIRectArrayWithBorderMask(cellFrame, self.borderMask, &borderRects, &borderRectCount)) {
        [self.borderColor set];
        NSRectFillList(borderRects, borderRectCount);
    }
    
    if (self.showsMenu) {
        [[LITabCell popupImage] drawInRect:[self popupRectWithFrame:cellFrame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    }
}

@end

@implementation LITabButton
+ (Class)cellClass {
    return [LITabCell class];
}
@end

BOOL LIRectArrayWithBorderMask(NSRect sourceRect, LIBorderMask borderMask, NSRect **rectArray, NSInteger *rectCount) {
    NSInteger outputCount = 0;
    static NSRect outputArray[4];
    
    NSRect remainderRect;
    if (borderMask & LIBorderMaskTop) {
        NSDivideRect(sourceRect, &outputArray[outputCount++], &remainderRect, 1, NSMinYEdge);
    }
    if (borderMask & LIBorderMaskLeft) {
        NSDivideRect(sourceRect, &outputArray[outputCount++], &remainderRect, 1, NSMinXEdge);
    }
    if (borderMask & LIBorderMaskRight) {
        NSDivideRect(sourceRect, &outputArray[outputCount++], &remainderRect, 1, NSMaxXEdge);
    }
    if (borderMask & LIBorderMaskBottom) {
        NSDivideRect(sourceRect, &outputArray[outputCount++], &remainderRect, 1, NSMaxYEdge);
    }
    
    if (rectCount) *rectCount = outputCount;
    if (rectArray) *rectArray = &outputArray[0];
    
    return (outputCount > 0);
}

