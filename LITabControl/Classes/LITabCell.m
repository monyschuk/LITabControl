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

#define INCH                72.0f

#define DF_BORDER_COLOR     [NSColor lightGrayColor]
#define DF_TITLE_COLOR      [NSColor darkGrayColor]
#define DF_HIGHLIGHT_COLOR  [NSColor colorWithCalibratedRed:0.119 green:0.399 blue:0.964 alpha:1.000]
#define DF_BACKGROUND_COLOR [NSColor colorWithCalibratedRed:0.854 green:0.858 blue:0.873 alpha:1.000]

@interface LITabButton (Private)
- (void)constrainSizeWithCell:(LITabCell *)cell;
@end

@implementation LITabCell 

- (id)initTextCell:(NSString *)aString {
    if ((self = [super initTextCell:aString])) {

        _borderColor = DF_BORDER_COLOR;
        _backgroundColor = DF_BACKGROUND_COLOR;
        
        _titleColor = DF_TITLE_COLOR;
        _titleHighlightColor = DF_HIGHLIGHT_COLOR;
        
        _minWidth = INCH * 2.75;
        _maxWidth = INCH * 2.75;
        
        [self setBordered:YES];
        [self setBackgroundStyle:NSBackgroundStyleLight];
        
        [self setHighlightsBy:NSNoCellMask];
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LITabCell *copy = [super copyWithZone:zone];

    copy->_minWidth = _minWidth;
    copy->_maxWidth = _maxWidth;
    
    copy->_borderMask = _borderMask;
    copy->_borderColor = [_borderColor copyWithZone:zone];
    copy->_backgroundColor = [_backgroundColor copyWithZone:zone];

    copy->_titleColor = [_titleColor copyWithZone:zone];
    copy->_titleHighlightColor = [_titleHighlightColor copyWithZone:zone];
    
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

- (void)setMinWidth:(CGFloat)minWidth {
    if (_minWidth != minWidth) {
        _minWidth = minWidth;
        
        if ([self.controlView respondsToSelector:@selector(constrainSizeWithCell:)]) {
            [(id)self.controlView constrainSizeWithCell:self];
        }
    }
}

- (void)setMaxWidth:(CGFloat)maxWidth {
    if (_maxWidth != maxWidth) {
        _maxWidth = maxWidth;
        
        if ([self.controlView respondsToSelector:@selector(constrainSizeWithCell:)]) {
            [(id)self.controlView constrainSizeWithCell:self];
        }
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
        
        titleRect = NSOffsetRect(titleRect, 0, -1);
        titleRect = NSInsetRect(titleRect, titleRectInset, 0);
    }
    return titleRect;
}

- (NSRect)editingRectForBounds:(NSRect)rect {
    return [self titleRectForBounds:NSOffsetRect(rect, 0, -1)];
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

#pragma mark -
#pragma mark Drawing

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawWithFrame:cellFrame inView:controlView];
    
    if (self.image && self.imagePosition != NSNoImage) {
        [self drawImage:[self.image imageWithTint:self.isHighlighted ? DF_HIGHLIGHT_COLOR : [NSColor darkGrayColor]] withFrame:cellFrame inView:controlView];
    }
    
    if (self.showsMenu) {
        [[LITabCell popupImage] drawInRect:[self popupRectWithFrame:cellFrame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    }
}

- (void)drawBezelWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [self.backgroundColor set];
    NSRectFill(cellFrame);
    
    NSRect *borderRects;
    NSInteger borderRectCount;
    if (LIRectArrayWithBorderMask(cellFrame, self.borderMask, &borderRects, &borderRectCount)) {
        [self.borderColor set];
        NSRectFillList(borderRects, borderRectCount);
    }
}

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
    NSRect titleRect = [self titleRectForBounds:frame];
    [title drawInRect:titleRect];
    return titleRect;
}

- (NSAttributedString *)attributedTitle {
    NSMutableAttributedString *attributedTitle = [[super attributedTitle] mutableCopy];
    [attributedTitle addAttributes:@{ NSForegroundColorAttributeName : (self.state ? self.titleHighlightColor : self.titleColor) } range:NSMakeRange(0, attributedTitle.length)];
    return attributedTitle;
}

@end

@implementation LITabButton {
    NSLayoutConstraint *_minWidthConstraint, *_maxWidthConstraint;
}

+ (Class)cellClass {
    return [LITabCell class];
}

- (BOOL)showsMenu {
    return [self.cell showsMenu];
}
- (void)setShowsMenu:(BOOL)showsMenu {
    [self.cell setShowsMenu:showsMenu];
}

- (BOOL)isShowingMenu {
    return [self.cell isShowingMenu];
}

- (LIBorderMask)borderMask {
    return [self.cell borderMask];
}
- (void)setBorderMask:(LIBorderMask)borderMask {
    [self.cell setBorderMask:borderMask];
}

- (NSColor *)borderColor {
    return [self.cell borderColor];
}
- (void)setBorderColor:(NSColor *)borderColor {
    [self.cell setBorderColor:borderColor];
}
- (NSColor *)backgroundColor {
    return [self.cell backgroundColor];
}
- (void)setBackgroundColor:(NSColor *)backgroundColor {
    [self.cell setBackgroundColor:backgroundColor];
}

- (NSColor *)titleColor {
    return [self.cell titleColor];
}
- (void)setTitleColor:(NSColor *)titleColor {
    [self.cell setTitleColor:titleColor];
}
- (NSColor *)titleHighlightColor {
    return [self.cell titleHighlightColor];
}
- (void)setTitleHighlightColor:(NSColor *)titleHighlightColor {
    [self.cell setTitleHighlightColor:titleHighlightColor];
}

- (CGFloat)minWidth {
    return [self.cell minWidth];
}
- (void)setMinWidth:(CGFloat)minWidth {
    [self.cell setMinWidth:minWidth];
}
- (CGFloat)maxWidth {
    return [self.cell maxWidth];
}
- (void)setMaxWidth:(CGFloat)maxWidth {
    [self.cell setMaxWidth:maxWidth];
}

- (void)setCell:(NSCell *)aCell {
    [super setCell:aCell];
    if ([aCell isKindOfClass:[LITabCell class]]) {
        [self constrainSizeWithCell:(id)aCell];
    }
}

- (void)constrainSizeWithCell:(LITabCell *)cell {
    if (_minWidthConstraint != nil) {
        if (cell.minWidth > 0) {
            [_minWidthConstraint setConstant:cell.minWidth];
        } else {
            [self removeConstraint:_minWidthConstraint];
            _minWidthConstraint = nil;
        }
    } else {
        if (cell.minWidth > 0) {
            _minWidthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                  toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1 constant:cell.minWidth];
            [self addConstraint:_minWidthConstraint];
        }
    }
    
    if (_maxWidthConstraint != nil) {
        if (cell.maxWidth > 0) {
            [_maxWidthConstraint setConstant:cell.maxWidth];
        } else {
            [self removeConstraint:_maxWidthConstraint];
            _maxWidthConstraint = nil;
        }
    } else {
        if (cell.maxWidth > 0) {
            _maxWidthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationLessThanOrEqual
                                                                  toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1 constant:cell.maxWidth];
            [self addConstraint:_maxWidthConstraint];
        }
    }

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

